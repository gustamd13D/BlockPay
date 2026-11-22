import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import '../telas/editarUsuario.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class EditarUsuarioController extends BaseController {
  void _voltarParaDetalhes(
    BuildContext context,
    ClienteModelo admin,
    String cpfUsuario,
  ) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(
        context,
        RotasApp.detalhesUsuario,
        arguments: {
          'admin': admin,
          'cpfUsuario': cpfUsuario,
        },
      );
    }
  }

  Future<void> _salvarAlteracoesUsuario(
    BuildContext context,
    ClienteModelo admin,
    String cpfUsuario,
    String nome,
    String email,
    bool isAdmin,
    bool contaAtiva,
  ) async {
    final salvo = await executarComCarregamento(context, () async {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(cpfUsuario)
          .update({
        'nome': nome,
        'email': email,
        'isAdmin': isAdmin,
        'tipo': isAdmin ? 'admin' : 'cliente',
        'status': contaAtiva ? 'ativo' : 'bloqueado',
        'ativo': contaAtiva,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (salvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas com sucesso!'),
          backgroundColor: CoresApp.verdePositivo,
        ),
      );
      _voltarParaDetalhes(context, admin, cpfUsuario);
    }
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! Map<String, dynamic> ||
        args['admin'] is! ClienteModelo ||
        args['cpfUsuario'] is! String) {
      return LoginController().construirTela(context);
    }

    final ClienteModelo admin = args['admin'] as ClienteModelo;
    final String cpfUsuario = args['cpfUsuario'] as String;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .doc(cpfUsuario)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: CoresApp.fundo,
            body: Center(
              child: CircularProgressIndicator(
                color: CoresApp.cianoPrimario,
              ),
            ),
          );
        }

        final dados = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};
        final nome = (dados['nome'] ?? '').toString();
        final email = (dados['email'] ?? '').toString();
        final isAdmin = dados['isAdmin'] == true ||
            dados['tipo']?.toString().toLowerCase() == 'admin';
        final status = (dados['status'] ?? 'ativo').toString().toLowerCase();
        final bool contaAtiva =
            dados['ativo'] != false && status != 'bloqueado';

        final sufixoId =
            cpfUsuario.length >= 4 ? cpfUsuario.substring(0, 4) : cpfUsuario;

        return EditarUsuario(
          iniciaisAdmin: extrairIniciais(admin.nome),
          idExibicao: 'ID #BP-$sufixoId',
          nomeInicial: nome,
          cpf: cpfUsuario,
          emailInicial: email,
          isAdminInicial: isAdmin,
          contaAtivaInicial: contaAtiva,
          aoVoltar: () => _voltarParaDetalhes(context, admin, cpfUsuario),
          aoDescartar: () => _voltarParaDetalhes(context, admin, cpfUsuario),
          aoClicarPerfil: () => abrirPerfil(context, admin),
          aoClicarSair: () => sairDaConta(context),
          aoSelecionarAba: (indice) =>
              navegarPeloMenuAdmin(context, admin, indice),
          aoSalvarAlteracoes: (novoNome, novoEmail, novoIsAdmin, novaAtiva) =>
              _salvarAlteracoesUsuario(
            context,
            admin,
            cpfUsuario,
            novoNome,
            novoEmail,
            novoIsAdmin,
            novaAtiva,
          ),
        );
      },
    );
  }
}
