import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/dashboard.dart';
import 'routerController.dart';
import 'baseController.dart';
import 'loginController.dart';

class DashboardController extends BaseController {
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
        final ultimaTx = clienteAtual.ultimaTransacaoCripto;

        String descricaoAtividade = 'Bônus de cadastro';
        String valorAtividade = '+${formatarMoedaBr(clienteAtual.saldoBrl)}';
        bool atividadePositiva = true;

        if (ultimaTx != null) {
          final tipo = ultimaTx['tipo']?.toString() ?? 'envio';
          final ativo = ultimaTx['ativo']?.toString() ?? 'BTC';
          final qtd = (ultimaTx['quantidade'] as num?)?.toDouble() ?? 0.0;
          final qtdStr = qtd.toString().replaceAll('.', ',');

          if (tipo == 'compra') {
            descricaoAtividade = 'Compra de $ativo';
            valorAtividade = '+$qtdStr $ativo';
            atividadePositiva = true;
          } else if (tipo == 'recebimento') {
            descricaoAtividade = 'Recebimento de $ativo';
            valorAtividade = '+$qtdStr $ativo';
            atividadePositiva = true;
          } else {
            descricaoAtividade = 'Transferência de $ativo';
            valorAtividade = '-$qtdStr $ativo';
            atividadePositiva = false;
          }
        }

        return Dashboard(
          iniciaisUsuario: extrairIniciais(clienteAtual.nome),
          saldoBrl: clienteAtual.saldoBrl,
          quantidadeBtc: clienteAtual.saldoBtc,
          quantidadeEth: clienteAtual.saldoEth,
          quantidadeSol: clienteAtual.saldoSol,
          quantidadeAda: clienteAtual.saldoAda,
          descricaoUltimaAtividade: descricaoAtividade,
          valorUltimaAtividadeFormatado: valorAtividade,
          atividadePositiva: atividadePositiva,
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
          aoClicarVerTodas: () => avisarTelaEmBreve(context, 'Histórico'),
          aoClicarTransferir: () {
            Navigator.pushNamed(
              context,
              RotasApp.transferirCripto,
              arguments: clienteAtual,
            );
          },
          aoClicarBlockchain: () {
            Navigator.pushNamed(
              context,
              RotasApp.statusBlockchain,
              arguments: {
                'cliente': clienteAtual,
                'animar': false,
              },
            );
          },
          aoClicarInicio: () {},
          aoClicarMercado: () {
            Navigator.pushNamed(
              context,
              RotasApp.mercadoCripto,
              arguments: clienteAtual,
            );
          },
          aoClicarPix: () => avisarTelaEmBreve(context, 'Pix'),
          aoClicarHistorico: () => avisarTelaEmBreve(context, 'Histórico'),
        );
      },
    );
  }
}
