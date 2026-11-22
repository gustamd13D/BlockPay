import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/editarConta.dart';
import 'routerController.dart';
import 'baseController.dart';
import 'loginController.dart';

class EditarContaController extends BaseController {
  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return EditarConta(
      nome: args.nome,
      cpf: args.cpf,
      email: args.email,
      telefone: args.telefone,
      aoClicarAlterarSenha: () {
        Navigator.pushNamed(
          context,
          RotasApp.alterarSenha,
          arguments: {'cpf': args.cpf, 'exigirSenhaAtual': true},
        );
      },
      salvarAlteracoes: (novoNome, novoEmail, novoTelefone) async {
        var salvo = false;
        await executarComCarregamento(context, () async {
          await FirebaseFirestore.instance
              .collection('clientes')
              .doc(args.cpf)
              .update({
            'nome': novoNome,
            'email': novoEmail,
            'telefone': novoTelefone,
          });
          salvo = true;
        });

        if (salvo && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados da conta atualizados com sucesso!'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
          Navigator.pop(context);
        }
      },
      aoClicarPerfil: () => abrirPerfil(context, args),
      aoClicarSair: () => sairDaConta(context),
      aoSelecionarAba: (indice) => navegarPeloMenu(context, args, indice),
    );
  }
}
