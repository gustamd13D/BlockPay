import 'dart:async';
import 'package:flutter/material.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/recuperarAcesso.dart';
import 'routerController.dart';
import 'baseController.dart';

class RecuperarAcessoController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  RecuperarAcessoController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  Widget construirTela(BuildContext context) {
    return RecuperarAcesso(
      enviarSolicitacao: (cpf, email) async {
        final codigoGerado = await executarComCarregamento(
          context,
          () => _servicoFirestore.solicitarCodigoRecuperacao(
            cpf: cpf,
            email: email,
          ),
        );

        if (codigoGerado != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 10),
              content: Text(
                'Código de verificação enviado para $email.',
              ),
              backgroundColor: const Color(0xFF151A26),
            ),
          );

          Navigator.pushNamed(
            context,
            RotasApp.validarCodigo,
            arguments: {'cpf': cpf, 'email': email},
          );
        }
      },
    );
  }
}
