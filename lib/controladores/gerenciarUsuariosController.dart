import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/gerenciarUsuario.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class GerenciarUsuarioController extends BaseController {
  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        int totalUsuarios = 0;
        int usuariosAtivos = 0;
        int usuariosPendentes = 0;
        final listaUsuarios = <UsuarioGerenciamentoItem>[];

        for (final doc in docs) {
          final dados = (doc.data() as Map<String, dynamic>?) ?? {};
          final cpf = (dados['cpf'] ?? doc.id).toString();

          // Ignora o proprio administrador logado na listagem de gerenciamento
          if (cpf == args.cpf) continue;

          final nome = (dados['nome'] ?? 'Usuario').toString();
          final email = (dados['email'] ?? '').toString();
          final isAdmin = dados['isAdmin'] == true ||
              dados['tipo']?.toString().toLowerCase() == 'admin';
          final ativoFlag = dados['ativo'] != false;

          String status =
              (dados['status'] ?? (ativoFlag ? 'ativo' : 'bloqueado'))
                  .toString()
                  .toLowerCase()
                  .trim();

          if (!ativoFlag && status != 'bloqueado') {
            status = 'bloqueado';
          }

          totalUsuarios++;
          if (status == 'pendente') {
            usuariosPendentes++;
          } else if (status != 'bloqueado') {
            usuariosAtivos++;
          }

          listaUsuarios.add(
            UsuarioGerenciamentoItem(
              cpf: cpf,
              nome: nome,
              email: email,
              status: status,
              isAdmin: isAdmin,
            ),
          );
        }

        listaUsuarios.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );

        return GerenciarUsuario(
          iniciaisUsuario: extrairIniciais(args.nome),
          totalUsuarios: totalUsuarios,
          usuariosAtivos: usuariosAtivos,
          usuariosPendentes: usuariosPendentes,
          usuarios: listaUsuarios,
          aoVoltar: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                context,
                RotasApp.painelAdmin,
                arguments: args,
              );
            }
          },
          aoClicarPerfil: () => abrirPerfil(context, args),
          aoClicarSair: () => sairDaConta(context),
          aoSelecionarAba: (indice) =>
              navegarPeloMenuAdmin(context, args, indice),
          aoClicarNovoUsuario: () {
            Navigator.pushNamed(
              context,
              RotasApp.criarUsuario,
              arguments: args,
            );
          },
          aoSelecionarUsuario: (usuario) {
            Navigator.pushNamed(
              context,
              RotasApp.detalhesUsuario,
              arguments: {
                'admin': args,
                'cpfUsuario': usuario.cpf,
              },
            );
          },
        );
      },
    );
  }
}
