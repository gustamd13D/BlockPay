import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/statusBlockchain.dart';
import 'routerController.dart';
import 'baseController.dart';
import 'loginController.dart';

class StatusBlockchainController extends BaseController {
  Widget construirTela(BuildContext context, Object? args) {
    if (args is! Map<String, dynamic>) {
      return LoginController().construirTela(context);
    }

    final cliente = args['cliente'] as ClienteModelo;
    final animar = args['animar'] as bool? ?? false;
    final transacao = (args['transacao'] as Map<String, dynamic>?) ??
        cliente.ultimaTransacaoCripto;

    return StatusBlockchain(
      iniciaisUsuario: extrairIniciais(cliente.nome),
      hashTransacao: transacao?['hash']?.toString() ?? '',
      ativo: transacao?['ativo']?.toString(),
      quantidade: (transacao?['quantidade'] as num?)?.toDouble(),
      destinatario: transacao?['destinatario']?.toString(),
      animarConfirmacao: animar,
      aoClicarPerfil: () {
        Navigator.pushNamed(
          context,
          RotasApp.editarConta,
          arguments: cliente,
        );
      },
      aoClicarInicio: () => Navigator.pop(context),
      aoClicarMercado: () => avisarTelaEmBreve(context, 'Mercado'),
      aoClicarPix: () => avisarTelaEmBreve(context, 'Pix'),
      aoClicarHistorico: () => avisarTelaEmBreve(context, 'Histórico'),
    );
  }
}
