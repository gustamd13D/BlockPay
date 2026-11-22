import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import '../telas/adminAjustes.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class AdminAjustesController extends BaseController {
  Future<void> _salvarDadosAdmin(
    BuildContext context,
    String cpf,
    String nome,
    String email,
    String telefone,
  ) async {
    final salvo = await executarComCarregamento(context, () async {
      final banco = FirebaseFirestore.instance;
      final docCliente = banco.collection('clientes').doc(cpf);
      final snapCliente = await docCliente.get();

      final dadosAtualizados = {
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (snapCliente.exists) {
        await docCliente.update(dadosAtualizados);
      } else {
        await banco.collection('admins').doc(cpf).update(dadosAtualizados);
      }
      return true;
    });

    if (salvo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas com sucesso!'),
          backgroundColor: CoresApp.verdePositivo,
        ),
      );
    }
  }

  void _exibirTermosDeUso(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CoresApp.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CoresApp.borda, width: 1),
        ),
        title: const Text(
          'Termos de uso',
          style: TextStyle(
            color: CoresApp.textoPrimario,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'O BlockPay EDU é um ambiente educacional de simulação financeira '
          'e criptoativos. Nenhum valor exibido na plataforma representa '
          'dinheiro real.',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Fechar',
              style: TextStyle(
                color: CoresApp.cianoPrimario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _montarTelaComDados(
    BuildContext context,
    ClienteModelo args,
    Map<String, dynamic> dados,
  ) {
    final nomeAtual = (dados['nome'] ?? args.nome).toString();
    final emailAtual = (dados['email'] ?? args.email).toString();
    final telefoneAtual = (dados['telefone'] ?? '').toString();

    return AdminAjustes(
      iniciaisUsuario: extrairIniciais(nomeAtual),
      nomeInicial: nomeAtual,
      cpf: args.cpf,
      emailInicial: emailAtual,
      telefoneInicial: telefoneAtual,
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
      aoSelecionarAba: (indice) => navegarPeloMenuAdmin(context, args, indice),
      aoClicarAlterarPin: () {
        Navigator.pushNamed(
          context,
          RotasApp.recuperarAcessoAdmin,
          arguments: args,
        );
      },
      aoClicarTermosUso: () => _exibirTermosDeUso(context),
      aoSalvarAlteracoes: (nome, email, telefone) =>
          _salvarDadosAdmin(context, args.cpf, nome, email, telefone),
    );
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    final banco = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot>(
      stream: banco.collection('clientes').doc(args.cpf).snapshots(),
      builder: (context, snapCliente) {
        if (snapCliente.hasData && snapCliente.data!.exists) {
          final dados =
              (snapCliente.data!.data() as Map<String, dynamic>?) ?? {};
          return _montarTelaComDados(context, args, dados);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: banco.collection('admins').doc(args.cpf).snapshots(),
          builder: (context, snapAdmin) {
            final dados =
                (snapAdmin.data?.data() as Map<String, dynamic>?) ?? {};
            return _montarTelaComDados(context, args, dados);
          },
        );
      },
    );
  }
}
