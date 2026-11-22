import 'dart:async';
import 'package:flutter/material.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/alterarSenha.dart';
import 'routerController.dart';
import 'baseController.dart';
import 'loginController.dart';

class AlterarSenhaController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  AlterarSenhaController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! Map<String, dynamic>) {
      return LoginController().construirTela(context);
    }

    final cpf = args['cpf'] as String;
    final exigirSenhaAtual = args['exigirSenhaAtual'] as bool? ?? false;

    return AlterarSenha(
      cpf: cpf,
      exigirSenhaAtual: exigirSenhaAtual,
      salvarSenha: (senhaAtual, novaSenha) async {
        var salva = false;
        await executarComCarregamento(context, () async {
          await _servicoFirestore.redefinirSenha(
            cpf: cpf,
            novaSenha: novaSenha,
            senhaAtual: senhaAtual,
          );
          salva = true;
        });

        if (salva && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                exigirSenhaAtual
                    ? 'Senha alterada com sucesso!'
                    : 'Senha alterada com sucesso! Faça login.',
              ),
              backgroundColor: const Color(0xFF00C853),
            ),
          );
          if (exigirSenhaAtual) {
            Navigator.pop(context);
          } else {
            Navigator.popUntil(context, ModalRoute.withName(RotasApp.login));
          }
        }
      },
    );
  }
}
