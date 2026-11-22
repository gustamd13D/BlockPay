import 'dart:async';
import 'package:flutter/material.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/cadastroCliente.dart';
import 'baseController.dart';

class CadastroClienteController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  CadastroClienteController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  Widget construirTela(BuildContext context) {
    return CadastroCliente(
      cadastrar: (nome, cpf, email, pin) async {
        final clienteCriado = await executarComCarregamento(
          context,
          () => _servicoFirestore.cadastrarCliente(
            nome: nome,
            cpf: cpf,
            email: email,
            pin: pin,
          ),
        );

        if (clienteCriado != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Conta criada com sucesso! Você recebeu R\$ 10.000,00 fictícios.',
              ),
              backgroundColor: Color(0xFF00C853),
            ),
          );
          Navigator.pop(context);
        }
      },
    );
  }
}
