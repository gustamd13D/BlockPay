import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/mercadoCripto.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class MercadoCriptoController extends BaseController {
  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return MercadoCripto(
      iniciaisUsuario: extrairIniciais(args.nome),
      aoSelecionarAtivo: (ativo) {
        Navigator.pushNamed(
          context,
          RotasApp.comprarCripto,
          arguments: {
            'cliente': args,
            'ativo': ativo,
          },
        );
      },
      aoVoltar: () => Navigator.pop(context),
      aoClicarPerfil: () {
        Navigator.pushNamed(
          context,
          RotasApp.editarConta,
          arguments: args,
        );
      },
      aoClicarSair: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RotasApp.login,
          (_) => false,
        );
      },
      aoClicarInicio: () => Navigator.pop(context),
      aoClicarMercado: () {},
      aoClicarPix: () => avisarTelaEmBreve(context, 'Pix'),
      aoClicarHistorico: () => avisarTelaEmBreve(context, 'Histórico'),
    );
  }
}
