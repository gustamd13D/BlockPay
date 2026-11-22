import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../telas/dashboardAdmin.dart';
import 'baseController.dart';
import 'loginController.dart';

class DashboardAdminController extends BaseController {
  static String _formatarMoeda(double valor) {
    final partes = valor.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final centavos = partes[1];

    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(inteiro[i]);
    }
    return 'R\$ ${buffer.toString()},$centavos';
  }

  static String _formatarDataHora(DateTime dataHora) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final diaEvento = DateTime(dataHora.year, dataHora.month, dataHora.day);

    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    if (diaEvento == hoje) return 'Hoje, $hora:$minuto';
    if (diaEvento == ontem) return 'Ontem, $hora:$minuto';

    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = meses[dataHora.month - 1];
    return '$dia $mes, $hora:$minuto';
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('clientes').snapshots(),
      builder: (context, snapClientes) {
        final docsClientes = snapClientes.data?.docs ?? [];

        int totalUsuarios = 0;
        int usuariosAtivos = 0;
        int usuariosPendentes = 0;
        int usuariosBloqueados = 0;
        final mapaNomesPorCpf = <String, String>{};
        final atividadesCadastros = <AtividadeAdminItem>[];

        for (final doc in docsClientes) {
          final Map<String, dynamic> dados =
              (doc.data() as Map<String, dynamic>?) ?? {};

          final isAdmin = dados['isAdmin'] == true ||
              dados['tipo']?.toString().toLowerCase() == 'admin';

          final cpf = (dados['cpf'] ?? doc.id).toString();
          final nome = (dados['nome'] ?? 'Usuário').toString();
          mapaNomesPorCpf[cpf] = nome;

          if (isAdmin) continue;

          totalUsuarios++;
          final ativoFlag = dados['ativo'] != false;
          String status =
              (dados['status'] ?? (ativoFlag ? 'ativo' : 'bloqueado'))
                  .toString()
                  .toLowerCase()
                  .trim();

          if (!ativoFlag && status != 'bloqueado') {
            status = 'bloqueado';
          }

          if (status == 'bloqueado') {
            usuariosBloqueados++;
          } else if (status == 'pendente') {
            usuariosPendentes++;
          } else {
            usuariosAtivos++;
          }

          final criadoEm = dados['criadoEm'];
          if (criadoEm is Timestamp) {
            final dataHora = criadoEm.toDate();
            atividadesCadastros.add(
              AtividadeAdminItem(
                icone: Icons.person_add_alt_1_outlined,
                titulo: 'Novo cadastro: $nome',
                subtitulo: _formatarDataHora(dataHora),
                dataHora: dataHora,
              ),
            );
          }
        }

        final nomeAdminAtual = mapaNomesPorCpf[args.cpf] ?? args.nome;

        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('transacoes').snapshots(),
          builder: (context, snapTransacoes) {
            final docsTransacoes = snapTransacoes.data?.docs ?? [];
            final limite30Dias =
                DateTime.now().subtract(const Duration(days: 30));

            double volume30Dias = 0.0;
            final atividadesTransacoes = <AtividadeAdminItem>[];

            for (final doc in docsTransacoes) {
              final Map<String, dynamic> dados =
                  (doc.data() as Map<String, dynamic>?) ?? {};

              final tipo = (dados['tipo'] ?? '').toString().toLowerCase();
              final ativo = (dados['ativo'] ?? 'BTC').toString().toUpperCase();
              final valorBrl = (dados['valorBrl'] as num?)?.toDouble() ??
                  (dados['valor'] as num?)?.toDouble() ??
                  0.0;

              final criadoEm = dados['criadoEm'];
              final dataHora =
                  criadoEm is Timestamp ? criadoEm.toDate() : DateTime.now();

              if (dataHora.isAfter(limite30Dias)) {
                volume30Dias += valorBrl.abs();
              }

              final cpfCliente =
                  (dados['cpfCliente'] ?? dados['cpfRemetente'] ?? '')
                      .toString();
              final nomeCliente = mapaNomesPorCpf[cpfCliente] ?? 'Cliente';

              if (tipo == 'deposito' || tipo == 'pix' || tipo == 'recarga') {
                atividadesTransacoes.add(
                  AtividadeAdminItem(
                    icone: Icons.pix_outlined,
                    titulo:
                        'Transferência Pix: $nomeCliente → ${_formatarMoeda(valorBrl)}',
                    subtitulo: _formatarDataHora(dataHora),
                    dataHora: dataHora,
                  ),
                );
              } else if (tipo == 'compra') {
                atividadesTransacoes.add(
                  AtividadeAdminItem(
                    icone: ativo == 'BTC'
                        ? Icons.currency_bitcoin_rounded
                        : Icons.toll_rounded,
                    titulo: 'Compra $ativo: $nomeCliente',
                    subtitulo: _formatarDataHora(dataHora),
                    dataHora: dataHora,
                  ),
                );
              } else {
                atividadesTransacoes.add(
                  AtividadeAdminItem(
                    icone: Icons.send_outlined,
                    titulo: 'Transferência $ativo: $nomeCliente',
                    subtitulo: _formatarDataHora(dataHora),
                    dataHora: dataHora,
                  ),
                );
              }
            }

            final todasAtividades = [
              ...atividadesCadastros,
              ...atividadesTransacoes,
            ]..sort((a, b) => b.dataHora.compareTo(a.dataHora));

            return DashboardAdmin(
              iniciaisUsuario: extrairIniciais(nomeAdminAtual),
              totalUsuarios: totalUsuarios,
              usuariosAtivos: usuariosAtivos,
              usuariosPendentes: usuariosPendentes,
              usuariosBloqueados: usuariosBloqueados,
              volumeTotalMovimentado: volume30Dias,
              ultimasAtividades: todasAtividades.take(6).toList(),
              aoClicarPerfil: () => abrirPerfil(context, args),
              aoClicarSair: () => sairDaConta(context),
              aoSelecionarAba: (indice) =>
                  navegarPeloMenuAdmin(context, args, indice),
            );
          },
        );
      },
    );
  }
}
