import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../servicos/servicoBlockchain.dart';
import '../servicos/servicoCotacoes.dart';
import '../telas/auditoria.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class AuditoriaController extends BaseController {
  static const List<String> _mesesAbrev = [
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

  /// Retorna a cotacao atualizada em BRL pelo servico compartilhado
  static double cotacaoBrlPorAtivo(String sigla) {
    return ServicoCotacoes.instancia.obterCotacaoBrl(sigla);
  }

  static String _formatarQuantidadeCripto(double valor, String sigla) {
    var texto = valor.abs().toStringAsFixed(8).replaceAll('.', ',');
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    if (texto.endsWith(',')) {
      texto = '${texto}00';
    }
    return '$texto $sigla';
  }

  static String _formatarInteiro(int numero) {
    final texto = numero.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(texto[i]);
    }
    return buffer.toString();
  }

  static String _formatarVolumeCompacto(double valor) {
    final absoluto = valor.abs();
    if (absoluto >= 1000000) {
      return 'R\$ ${(absoluto / 1000000).toStringAsFixed(1)}M';
    }
    if (absoluto >= 100000) {
      return 'R\$ ${(absoluto / 1000).toStringAsFixed(0)}k';
    }
    final partes = absoluto.toStringAsFixed(2).split('.');
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

  static String _formatarCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 11) return cpf;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
        '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
  }

  static String _formatarDataCurta(DateTime dataHora) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final diaEvento = DateTime(dataHora.year, dataHora.month, dataHora.day);

    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    if (diaEvento == hoje) return 'Hoje, $hora:$minuto';
    if (diaEvento == ontem) return 'Ontem, $hora:$minuto';

    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = _mesesAbrev[dataHora.month - 1];
    return '$dia $mes, $hora:$minuto';
  }

  static String _formatarDataCompleta(DateTime dataHora) {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = _mesesAbrev[dataHora.month - 1];
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');
    return '$dia $mes ${dataHora.year}, $hora:$minuto';
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    final firestore = FirebaseFirestore.instance;
    final servicoCotacoes = ServicoCotacoes.instancia;
    servicoCotacoes.atualizarCotacoes();

    return ValueListenableBuilder<List<AtivoMercado>>(
      valueListenable: servicoCotacoes.ativosNotifier,
      builder: (context, _, __) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('clientes').snapshots(),
          builder: (context, snapClientes) {
            final docsClientes = snapClientes.data?.docs ?? [];

            int totalUsuarios = 0;
            final mapaNomesPorCpf = <String, String>{};

            for (final doc in docsClientes) {
              final dados = (doc.data() as Map<String, dynamic>?) ?? {};
              final cpf = (dados['cpf'] ?? doc.id).toString();
              final nome = (dados['nome'] ?? 'Usuario').toString();
              mapaNomesPorCpf[cpf] = nome;

              final isAdmin = dados['isAdmin'] == true ||
                  dados['tipo']?.toString().toLowerCase() == 'admin';

              if (!isAdmin) {
                totalUsuarios++;
              }
            }

            final nomeAdminAtual = mapaNomesPorCpf[args.cpf] ?? args.nome;

            return StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('transacoes').snapshots(),
              builder: (context, snapTransacoes) {
                final docsTransacoes = snapTransacoes.data?.docs ?? [];

                double volumeTotal = 0.0;
                final int totalTransacoes = docsTransacoes.length;

                final agora = DateTime.now();
                final mesesJanela = <DateTime>[];
                final contagemPorMes = <String, int>{};
                final volumePorMes = <String, double>{};

                for (var i = 5; i >= 0; i--) {
                  final mesRef = DateTime(agora.year, agora.month - i, 1);
                  final chave = '${mesRef.year}-${mesRef.month}';
                  mesesJanela.add(mesRef);
                  contagemPorMes[chave] = 0;
                  volumePorMes[chave] = 0.0;
                }

                final listaItensOrdenaveis =
                    <({DateTime dataHora, TransacaoAuditoriaItem item})>[];

                for (final doc in docsTransacoes) {
                  final dados = (doc.data() as Map<String, dynamic>?) ?? {};

                  final tipo =
                      (dados['tipo'] ?? '').toString().toLowerCase().trim();
                  final tituloBruto = (dados['titulo'] ?? '').toString().trim();
                  final ativo =
                      (dados['ativo'] ?? 'BRL').toString().toUpperCase().trim();
                  final status = (dados['status'] ?? 'Confirmada').toString();
                  final qtdCripto =
                      (dados['quantidadeCripto'] as num?)?.toDouble() ??
                          (dados['quantidade'] as num?)?.toDouble() ??
                          0.0;

                  double valorBrl = (dados['valorBrl'] as num?)?.toDouble() ??
                      (dados['valor'] as num?)?.toDouble() ??
                      0.0;

                  // Calcula dinamicamente o valor em BRL usando a cotacao compartilhada
                  if (valorBrl <= 0 &&
                      qtdCripto > 0 &&
                      ativo.isNotEmpty &&
                      ativo != 'BRL') {
                    final cotacaoSalva =
                        (dados['cotacaoUnitaria'] as num?)?.toDouble() ?? 0.0;
                    final cotacaoEfetiva = cotacaoSalva > 0
                        ? cotacaoSalva
                        : servicoCotacoes.obterCotacaoBrl(ativo);
                    if (cotacaoEfetiva > 0) {
                      valorBrl = double.parse(
                        (qtdCripto * cotacaoEfetiva).toStringAsFixed(2),
                      );
                    }
                  }

                  final criadoEm = dados['criadoEm'] ?? dados['dataHora'];
                  final dataHora = criadoEm is Timestamp
                      ? criadoEm.toDate()
                      : DateTime.now();

                  volumeTotal += valorBrl.abs();

                  final chaveMes = '${dataHora.year}-${dataHora.month}';
                  if (contagemPorMes.containsKey(chaveMes)) {
                    contagemPorMes[chaveMes] =
                        (contagemPorMes[chaveMes] ?? 0) + 1;
                    volumePorMes[chaveMes] =
                        (volumePorMes[chaveMes] ?? 0.0) + valorBrl.abs();
                  }

                  final cpfCliente =
                      (dados['cpfCliente'] ?? dados['cpfRemetente'] ?? '')
                          .toString();
                  final nomeUsuario = mapaNomesPorCpf[cpfCliente] ??
                      (dados['nomeCliente'] ?? 'Cliente').toString();
                  final iniciais = extrairIniciais(nomeUsuario);

                  final destinatario = (dados['destinatario'] ??
                          dados['nomeDestinatario'] ??
                          dados['cpfDestinatario'] ??
                          '')
                      .toString()
                      .trim();

                  final hashSalva = (dados['hash'] ?? '').toString().trim();
                  final hashFinal = hashSalva.isNotEmpty
                      ? hashSalva
                      : ServicoBlockchain.instancia.gerarHashSha256(
                          '${doc.id}|$cpfCliente|$valorBrl',
                        );

                  final indiceBlocoNum =
                      (dados['indiceBloco'] as num?)?.toInt();
                  final indiceBlocoTexto = indiceBlocoNum != null
                      ? 'Bloco #$indiceBlocoNum'
                      : 'Bloco #0 (Gênesis)';
                  final hashBlocoTexto =
                      (dados['hashBloco'] ?? '').toString().trim();

                  final dataCurta = _formatarDataCurta(dataHora);

                  late final String tituloOperacao;
                  late final String contextoOperacao;
                  late final bool isEntrada;

                  if (tipo == 'deposito' ||
                      tipo == 'pix' ||
                      tipo == 'recarga') {
                    final rotuloOp =
                        tituloBruto.isNotEmpty ? tituloBruto : 'Depósito Pix';
                    tituloOperacao = '$nomeUsuario — $rotuloOp';
                    contextoOperacao = 'Carteira BlockPay';
                    isEntrada = true;
                  } else if (tipo == 'compra') {
                    tituloOperacao = '$nomeUsuario — Compra $ativo';
                    contextoOperacao = qtdCripto > 0
                        ? _formatarQuantidadeCripto(qtdCripto, ativo)
                        : 'Carteira $ativo';
                    isEntrada = false;
                  } else if (tipo == 'venda') {
                    tituloOperacao = '$nomeUsuario — Venda $ativo';
                    contextoOperacao = qtdCripto > 0
                        ? _formatarQuantidadeCripto(qtdCripto, ativo)
                        : 'Carteira $ativo';
                    isEntrada = true;
                  } else if (tipo == 'envio' ||
                      tipo.contains('transferencia')) {
                    final isCripto = tipo == 'envio' ||
                        tipo.contains('cripto') ||
                        (ativo != 'BRL' && ativo.isNotEmpty);
                    tituloOperacao = isCripto
                        ? '$nomeUsuario — Transferência $ativo'
                        : '$nomeUsuario — Transferência Pix';
                    final qtdTexto = (isCripto && qtdCripto > 0)
                        ? '${_formatarQuantidadeCripto(qtdCripto, ativo)} • '
                        : '';
                    contextoOperacao = destinatario.isNotEmpty
                        ? '${qtdTexto}Destinatário: $destinatario'
                        : '${qtdTexto}Carteira BlockPay';
                    isEntrada = false;
                  } else {
                    final rotuloOp =
                        tituloBruto.isNotEmpty ? tituloBruto : 'Movimentação';
                    tituloOperacao = '$nomeUsuario — $rotuloOp';
                    contextoOperacao = 'Carteira BlockPay';
                    isEntrada = valorBrl >= 0;
                  }

                  final bool movimentouCripto =
                      qtdCripto > 0 && ativo.isNotEmpty && ativo != 'BRL';

                  final valorMoeda = formatarMoedaBr(valorBrl);
                  final valorFormatado =
                      isEntrada ? '+$valorMoeda' : '-$valorMoeda';

                  listaItensOrdenaveis.add((
                    dataHora: dataHora,
                    item: TransacaoAuditoriaItem(
                      idTransacao: doc.id,
                      hashTransacao: hashFinal,
                      indiceBloco: indiceBlocoTexto,
                      hashBloco: hashBlocoTexto,
                      nomeUsuario: nomeUsuario,
                      cpfUsuario: _formatarCpf(cpfCliente),
                      iniciaisUsuario: iniciais,
                      tituloOperacao: tituloOperacao,
                      subtituloOperacao: '$contextoOperacao • $dataCurta',
                      valorFormatado: valorFormatado,
                      siglaCripto: movimentouCripto ? ativo : null,
                      valorCriptoFormatado: movimentouCripto
                          ? _formatarQuantidadeCripto(qtdCripto, ativo)
                          : null,
                      isEntrada: isEntrada,
                      status: status,
                      dataHoraCompleta: _formatarDataCompleta(dataHora),
                    ),
                  ));
                }

                listaItensOrdenaveis
                    .sort((a, b) => b.dataHora.compareTo(a.dataHora));

                final dadosGrafico = mesesJanela.map((mesRef) {
                  final chave = '${mesRef.year}-${mesRef.month}';
                  return DadoMesAuditoria(
                    rotuloMes: _mesesAbrev[mesRef.month - 1],
                    quantidadeTransacoes: contagemPorMes[chave] ?? 0,
                    volumeTotal: volumePorMes[chave] ?? 0.0,
                  );
                }).toList();

                return Auditoria(
                  iniciaisUsuario: extrairIniciais(nomeAdminAtual),
                  totalUsuariosFormatado: _formatarInteiro(totalUsuarios),
                  volumeTotalFormatado: _formatarVolumeCompacto(volumeTotal),
                  totalTransacoesFormatado: _formatarInteiro(totalTransacoes),
                  dadosGraficoMensal: dadosGrafico,
                  transacoesRecentes: listaItensOrdenaveis
                      .take(30)
                      .map((registro) => registro.item)
                      .toList(),
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
                );
              },
            );
          },
        );
      },
    );
  }
}
