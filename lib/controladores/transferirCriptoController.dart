import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../servicos/servicoBlockchain.dart';
import '../servicos/servicoCotacoes.dart';
import '../telas/transferirCripto.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class TransferirCriptoController extends BaseController {
  final ServicoBlockchain _servicoBlockchain;
  final ServicoCotacoes _servicoCotacoes;

  TransferirCriptoController({
    ServicoBlockchain? servicoBlockchain,
    ServicoCotacoes? servicoCotacoes,
  })  : _servicoBlockchain = servicoBlockchain ?? ServicoBlockchain.instancia,
        _servicoCotacoes = servicoCotacoes ?? ServicoCotacoes.instancia;

  String _campoSaldoPorAtivo(String ativo) {
    switch (ativo.toUpperCase()) {
      case 'BTC':
        return 'saldoBtc';
      case 'ETH':
        return 'saldoEth';
      case 'SOL':
        return 'saldoSol';
      case 'ADA':
        return 'saldoAda';
      default:
        return 'saldoBtc';
    }
  }

  double _saldoPadraoPorAtivo(String ativo) {
    switch (ativo.toUpperCase()) {
      case 'BTC':
        return 0.034;
      case 'ETH':
        return 0.25;
      case 'SOL':
      case 'ADA':
      default:
        return 0.0;
    }
  }

  /// Busca um cliente cadastrado no Firestore por e-mail, CPF ou endereco
  Future<DocumentSnapshot?> _buscarDestinatarioCadastrado(
    FirebaseFirestore firestore,
    String destinatario,
  ) async {
    final texto = destinatario.trim();
    final textoMinusculo = texto.toLowerCase();

    var consulta = await firestore
        .collection('clientes')
        .where('email', isEqualTo: textoMinusculo)
        .limit(1)
        .get();

    if (consulta.docs.isEmpty && texto != textoMinusculo) {
      consulta = await firestore
          .collection('clientes')
          .where('email', isEqualTo: texto)
          .limit(1)
          .get();
    }
    if (consulta.docs.isNotEmpty) return consulta.docs.first;

    final apenasDigitos = texto.replaceAll(RegExp(r'\D'), '');
    if (apenasDigitos.length == 11) {
      final docPorCpf =
          await firestore.collection('clientes').doc(apenasDigitos).get();
      if (docPorCpf.exists) return docPorCpf;
    }

    final consultaCarteira = await firestore
        .collection('clientes')
        .where('enderecoCarteira', isEqualTo: texto)
        .limit(1)
        .get();
    if (consultaCarteira.docs.isNotEmpty) return consultaCarteira.docs.first;

    return null;
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return StreamBuilder<ClienteModelo>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .doc(args.cpf)
          .snapshots()
          .map((doc) {
        final dados = doc.data();
        return dados != null ? ClienteModelo.deMapa(dados) : args;
      }),
      builder: (context, snapshot) {
        final clienteAtual = snapshot.data ?? args;

        return TransferirCripto(
          iniciaisUsuario: extrairIniciais(clienteAtual.nome),
          saldoBtc: clienteAtual.saldoBtc,
          saldoEth: clienteAtual.saldoEth,
          saldoSol: clienteAtual.saldoSol,
          saldoAda: clienteAtual.saldoAda,
          emailRemetente: clienteAtual.email,
          cpfRemetente: clienteAtual.cpf,
          aoTransferir: (destinatario, ativo, quantidade) async {
            final firestore = FirebaseFirestore.instance;

            final docDestinatario =
                await _buscarDestinatarioCadastrado(firestore, destinatario);

            if (docDestinatario == null) {
              return 'Usuário não encontrado. Só é possível enviar para usuários cadastrados no BlockPay.';
            }

            if (docDestinatario.id == clienteAtual.cpf) {
              return 'Você não pode transferir para sua própria conta.';
            }

            final dadosDest =
                (docDestinatario.data() as Map<String, dynamic>?) ?? {};
            if (dadosDest['ativo'] == false) {
              return 'A conta deste destinatário está inativa.';
            }

            await _servicoCotacoes.atualizarCotacoes();
            final cotacaoUnitaria = _servicoCotacoes.obterCotacaoBrl(ativo);
            final valorBrlEstimado = double.parse(
              (quantidade * cotacaoUnitaria).toStringAsFixed(2),
            );

            final campoSaldo = _campoSaldoPorAtivo(ativo);
            final saldoPadrao = _saldoPadraoPorAtivo(ativo);
            final docRemetenteRef =
                firestore.collection('clientes').doc(clienteAtual.cpf);

            late Map<String, dynamic> dadosTransacaoEnvio;

            try {
              await firestore.runTransaction((transaction) async {
                // 1. Todas as leituras primeiro
                final snapRemetente = await transaction.get(docRemetenteRef);
                final snapDestinatario =
                    await transaction.get(docDestinatario.reference);
                final prepBloco = await _servicoBlockchain
                    .prepararRegistroNaTransacao(transaction);

                if (!snapRemetente.exists || !snapDestinatario.exists) {
                  throw Exception('Conta não encontrada no banco de dados.');
                }

                final dadosRem = snapRemetente.data()!;
                final dadosDestAtual =
                    (snapDestinatario.data() as Map<String, dynamic>?) ?? {};

                final saldoAnteriorRemetente =
                    (dadosRem[campoSaldo] as num?)?.toDouble() ?? saldoPadrao;

                if (quantidade > saldoAnteriorRemetente + 1e-9) {
                  throw Exception('Saldo insuficiente de $ativo.');
                }

                final novoSaldoRemetente = double.parse(
                  (saldoAnteriorRemetente - quantidade)
                      .clamp(0.0, double.infinity)
                      .toStringAsFixed(8),
                );

                final saldoAnteriorDestinatario =
                    (dadosDestAtual[campoSaldo] as num?)?.toDouble() ??
                        saldoPadrao;
                final novoSaldoDestinatario = double.parse(
                  (saldoAnteriorDestinatario + quantidade).toStringAsFixed(8),
                );

                // 2. Calculo da hash derivada do bloco ativo
                final registroTx = _servicoBlockchain.calcularRegistroTransacao(
                  prepBloco,
                  resumoDados:
                      'TRANSFERENCIA|${clienteAtual.cpf}|${docDestinatario.id}|$ativo|$quantidade',
                );

                dadosTransacaoEnvio = {
                  'tipo': 'envio',
                  'hash': registroTx.hashTransacao,
                  'indiceBloco': registroTx.indiceBloco,
                  'hashBloco': registroTx.hashBloco,
                  'ativo': ativo,
                  'quantidade': quantidade,
                  'cotacaoUnitaria': cotacaoUnitaria,
                  'valorBrl': valorBrlEstimado,
                  'destinatario': destinatario,
                  'nomeDestinatario': dadosDest['nome'] ?? destinatario,
                  'status': 'Confirmado na blockchain',
                };

                final dadosTransacaoRecebimento = {
                  'tipo': 'recebimento',
                  'hash': registroTx.hashTransacao,
                  'indiceBloco': registroTx.indiceBloco,
                  'hashBloco': registroTx.hashBloco,
                  'ativo': ativo,
                  'quantidade': quantidade,
                  'cotacaoUnitaria': cotacaoUnitaria,
                  'valorBrl': valorBrlEstimado,
                  'remetente': clienteAtual.email,
                  'nomeRemetente': clienteAtual.nome,
                  'status': 'Confirmado na blockchain',
                };

                // 3. Todas as escritas depois
                transaction.update(docRemetenteRef, {
                  campoSaldo: novoSaldoRemetente,
                  'ultimaTransacaoCripto': dadosTransacaoEnvio,
                });

                transaction.update(docDestinatario.reference, {
                  campoSaldo: novoSaldoDestinatario,
                  'ultimaTransacaoCripto': dadosTransacaoRecebimento,
                });

                transaction.set(firestore.collection('transacoes').doc(), {
                  'cpfRemetente': clienteAtual.cpf,
                  'cpfDestinatario': docDestinatario.id,
                  'hashBlocoAnterior': registroTx.hashBlocoAnterior,
                  ...dadosTransacaoEnvio,
                  'criadoEm': FieldValue.serverTimestamp(),
                });

                _servicoBlockchain.aplicarEscritaNaTransacao(
                  transaction,
                  prepBloco,
                  registroTx,
                );
              });
            } catch (erro) {
              return erro.toString().replaceFirst('Exception: ', '');
            }

            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                RotasApp.statusBlockchain,
                arguments: {
                  'cliente': clienteAtual,
                  'transacao': dadosTransacaoEnvio,
                  'animar': true,
                },
              );
            }
            return null;
          },
          aoClicarPerfil: () => abrirPerfil(context, clienteAtual),
          aoClicarSair: () => sairDaConta(context),
          aoSelecionarAba: (indice) =>
              navegarPeloMenu(context, clienteAtual, indice),
        );
      },
    );
  }
}
