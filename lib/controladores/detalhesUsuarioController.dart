import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import '../telas/detalhesUsuario.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class DetalhesUsuarioController extends BaseController {
  static String _formatarDataHora(dynamic valorTimestamp,
      {String fallback = 'Nao registrado'}) {
    if (valorTimestamp is! Timestamp) return fallback;

    final dataHora = valorTimestamp.toDate();
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final diaEvento = DateTime(dataHora.year, dataHora.month, dataHora.day);

    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    if (diaEvento == hoje) return 'Hoje, $hora:$minuto';
    if (diaEvento == ontem) return 'Ontem, $hora:$minuto';

    const meses = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = meses[dataHora.month - 1];
    return '$dia $mes ${dataHora.year}, $hora:$minuto';
  }

  Future<void> _alternarBloqueioUsuario(
    BuildContext context,
    String cpfUsuario,
    bool estaBloqueado,
  ) async {
    final novoStatus = estaBloqueado ? 'ativo' : 'bloqueado';
    final novoAtivo = estaBloqueado;

    final atualizado = await executarComCarregamento(context, () async {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(cpfUsuario)
          .update({
        'status': novoStatus,
        'ativo': novoAtivo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (atualizado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estaBloqueado
                ? 'Acesso desbloqueado com sucesso!'
                : 'Acesso do usuário bloqueado.',
          ),
          backgroundColor: estaBloqueado
              ? CoresApp.verdePositivo
              : CoresApp.vermelhoNegativo,
        ),
      );
    }
  }

  Future<void> _excluirUsuario(
    BuildContext context,
    ClienteModelo admin,
    String cpfUsuario,
  ) async {
    final excluido = await executarComCarregamento(context, () async {
      final banco = FirebaseFirestore.instance;
      final docUsuario = banco.collection('clientes').doc(cpfUsuario);

      // Remove subcolecoes antes de excluir o documento principal
      final carteiraSnap = await docUsuario.collection('carteira').get();
      for (final item in carteiraSnap.docs) {
        await item.reference.delete();
      }

      final transacoesSnap = await docUsuario.collection('transacoes').get();
      for (final item in transacoesSnap.docs) {
        await item.reference.delete();
      }

      await docUsuario.delete();
      return true;
    });

    if (excluido == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário excluído com sucesso!'),
          backgroundColor: CoresApp.verdePositivo,
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(
          context,
          RotasApp.gerenciarUsuarios,
          arguments: admin,
        );
      }
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
        final nome = (dados['nome'] ?? 'Usuario').toString();
        final email = (dados['email'] ?? '').toString();
        final isAdmin = dados['isAdmin'] == true ||
            dados['tipo']?.toString().toLowerCase() == 'admin';
        final ativoFlag = dados['ativo'] != false;

        String status = (dados['status'] ?? (ativoFlag ? 'ativo' : 'bloqueado'))
            .toString()
            .toLowerCase()
            .trim();
        if (!ativoFlag && status != 'bloqueado') {
          status = 'bloqueado';
        }

        final bool isBloqueado = status == 'bloqueado';

        final criadoEm = _formatarDataHora(dados['criadoEm']);
        final ultimoAcesso = _formatarDataHora(
          dados['ultimoAcesso'] ?? dados['atualizadoEm'] ?? dados['criadoEm'],
          fallback: 'Primeiro acesso pendente',
        );

        return DetalhesUsuario(
          iniciaisAdmin: extrairIniciais(admin.nome),
          nomeUsuario: nome,
          emailUsuario: email,
          cpfUsuario: cpfUsuario,
          perfilUsuario: isAdmin ? 'Administrador' : 'Cliente',
          criadoEm: criadoEm,
          ultimoAcesso: ultimoAcesso,
          statusUsuario: status,
          aoVoltar: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                context,
                RotasApp.gerenciarUsuarios,
                arguments: admin,
              );
            }
          },
          aoClicarPerfil: () => abrirPerfil(context, admin),
          aoClicarSair: () => sairDaConta(context),
          aoSelecionarAba: (indice) =>
              navegarPeloMenuAdmin(context, admin, indice),
          aoClicarEditarUsuario: () {
            Navigator.pushNamed(
              context,
              RotasApp.editarUsuario,
              arguments: {
                'admin': admin,
                'cpfUsuario': cpfUsuario,
              },
            );
          },
          aoAlternarBloqueio: () =>
              _alternarBloqueioUsuario(context, cpfUsuario, isBloqueado),
          aoConfirmarExclusao: () =>
              _excluirUsuario(context, admin, cpfUsuario),
        );
      },
    );
  }
}
