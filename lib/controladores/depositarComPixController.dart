import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/depositarComPix.dart';
import 'baseController.dart';
import 'loginController.dart';

class DepositarComPixController extends BaseController {
  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return DepositarComPix(
      iniciaisUsuario: extrairIniciais(args.nome),
      nomeRecebedor: 'BLOCKPAY EDU',
      cidadeRecebedor: 'SAO PAULO',
      aoVoltar: () => Navigator.pop(context),
      aoClicarPerfil: () => abrirPerfil(context, args),
      aoClicarSair: () => sairDaConta(context),
      aoSelecionarAba: (indice) => navegarPeloMenu(context, args, indice),
    );
  }
}
