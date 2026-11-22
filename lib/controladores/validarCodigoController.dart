import 'dart:async';
import 'package:flutter/material.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/validarCodigo.dart';
import 'routerController.dart';
import 'baseController.dart';
import 'loginController.dart';

class ValidarCodigoController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  ValidarCodigoController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! Map<String, String>) {
      return LoginController().construirTela(context);
    }

    final cpf = args['cpf']!;
    final email = args['email']!;

    return ValidarCodigo(
      cpf: cpf,
      email: email,
      validarCodigo: (codigo) async {
        var validado = false;
        await executarComCarregamento(context, () async {
          await _servicoFirestore.validarCodigoRecuperacao(
            cpf: cpf,
            codigo: codigo,
          );
          validado = true;
        });

        if (validado && context.mounted) {
          Navigator.pushNamed(
            context,
            RotasApp.alterarSenha,
            arguments: {'cpf': cpf, 'exigirSenhaAtual': false},
          );
        }
      },
      reenviarCodigo: () async {
        final novoCodigo = await executarComCarregamento(
          context,
          () => _servicoFirestore.solicitarCodigoRecuperacao(
            cpf: cpf,
            email: email,
          ),
        );

        if (novoCodigo != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 10),
              content: Text(
                'Novo código de verificação enviado para $email.',
              ),
              backgroundColor: const Color(0xFF151A26),
            ),
          );
        }
      },
    );
  }
}
