import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/comprarCripto.dart';
import '../telas/mercadoCripto.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class ComprarCriptoController extends BaseController {
  String _campoSaldoPorSigla(String sigla) {
    switch (sigla.toUpperCase()) {
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

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! Map<String, dynamic> ||
        args['cliente'] is! ClienteModelo ||
        args['ativo'] is! AtivoMercado) {
      return LoginController().construirTela(context);
    }

    final clienteInicial = args['cliente'] as ClienteModelo;
    final ativo = args['ativo'] as AtivoMercado;

    return StreamBuilder<ClienteModelo>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .doc(clienteInicial.cpf)
          .snapshots()
          .map((doc) {
        final dados = doc.data();
        return dados != null ? ClienteModelo.deMapa(dados) : clienteInicial;
      }),
      builder: (context, snapshot) {
        final clienteAtual = snapshot.data ?? clienteInicial;

        return ComprarCripto(
          iniciaisUsuario: extrairIniciais(clienteAtual.nome),
          saldoBrlDisponivel: clienteAtual.saldoBrl,
          ativo: ativo,
          aoConfirmarCompra: (valorReais, fracaoCripto) async {
            if (valorReais < 1.0) {
              return 'O valor mínimo para compra é R\$ 1,00.';
            }
            if (valorReais > clienteAtual.saldoBrl) {
              return 'Saldo em BRL insuficiente para esta operação.';
            }
            if (fracaoCripto <= 0) {
              return 'Não foi possível calcular a fração do ativo.';
            }

            final firestore = FirebaseFirestore.instance;
            final docClienteRef =
                firestore.collection('clientes').doc(clienteAtual.cpf);
            final campoSaldoCripto = _campoSaldoPorSigla(ativo.sigla);

            try {
              await firestore.runTransaction((transaction) async {
                final snap = await transaction.get(docClienteRef);
                if (!snap.exists) {
                  throw Exception('Conta do cliente não encontrada.');
                }

                final dados = snap.data()!;
                final saldoBrlAtual =
                    (dados['saldoBrl'] as num?)?.toDouble() ?? 0.0;

                if (saldoBrlAtual < valorReais) {
                  throw Exception(
                    'Saldo em BRL insuficiente para concluir a compra.',
                  );
                }

                final saldoCriptoAtual =
                    (dados[campoSaldoCripto] as num?)?.toDouble() ?? 0.0;

                final novoSaldoBrl = double.parse(
                  (saldoBrlAtual - valorReais).toStringAsFixed(2),
                );
                final novoSaldoCripto = double.parse(
                  (saldoCriptoAtual + fracaoCripto).toStringAsFixed(8),
                );

                final dadosUltimaCompra = {
                  'tipo': 'compra',
                  'ativo': ativo.sigla,
                  'nomeAtivo': ativo.nome,
                  'quantidade': fracaoCripto,
                  'valorBrl': valorReais,
                  'cotacaoUnitaria': ativo.precoBrl,
                  'status': 'Confirmada',
                };

                transaction.update(docClienteRef, {
                  'saldoBrl': novoSaldoBrl,
                  campoSaldoCripto: novoSaldoCripto,
                  'ultimaTransacaoCripto': dadosUltimaCompra,
                });

                transaction.set(firestore.collection('transacoes').doc(), {
                  'cpfCliente': clienteAtual.cpf,
                  'taxaRede': 0.0,
                  ...dadosUltimaCompra,
                  'criadoEm': FieldValue.serverTimestamp(),
                });
              });

              if (context.mounted) {
                final fracaoFormatada =
                    fracaoCripto.toStringAsFixed(8).replaceAll('.', ',');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Compra de $fracaoFormatada ${ativo.sigla} realizada com sucesso!',
                    ),
                    backgroundColor: const Color(0xFF00C853),
                  ),
                );
                Navigator.pop(context);
              }
              return null;
            } catch (erro) {
              return erro.toString().replaceFirst('Exception: ', '');
            }
          },
          aoVoltar: () => Navigator.pop(context),
          aoClicarPerfil: () {
            Navigator.pushNamed(
              context,
              RotasApp.editarConta,
              arguments: clienteAtual,
            );
          },
          aoClicarSair: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RotasApp.login,
              (_) => false,
            );
          },
          aoClicarInicio: () {
            Navigator.popUntil(context, ModalRoute.withName(RotasApp.painel));
          },
          aoClicarMercado: () => Navigator.pop(context),
          aoClicarPix: () => avisarTelaEmBreve(context, 'Pix'),
          aoClicarHistorico: () => avisarTelaEmBreve(context, 'Histórico'),
        );
      },
    );
  }
}
