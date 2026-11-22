import 'dart:async';
import 'package:flutter/material.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/login.dart';
import 'routerController.dart';
import 'baseController.dart';

class LoginController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  LoginController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  Widget construirTela(BuildContext context) {
    return Login(
      entrar: (cpf, pin) async {
        final cliente = await executarComCarregamento(
          context,
          () => _servicoFirestore.autenticarCliente(
            cpf: cpf,
            pin: pin,
          ),
        );

        if (cliente != null && context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RotasApp.painel,
            (_) => false,
            arguments: cliente,
          );
        }
      },
      esquecerSenha: () {
        Navigator.pushNamed(context, RotasApp.recuperarAcesso);
      },
      criarConta: () {
        Navigator.pushNamed(context, RotasApp.cadastro);
      },
    );
  }
}
