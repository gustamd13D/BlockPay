import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import '../telas/historicoTransacoes.dart';
import 'baseController.dart';
import 'loginController.dart';

class HistoricoTransacoesController extends BaseController {
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

  static String _formatarQuantidadeCripto(double valor) {
    var texto = valor.abs().toStringAsFixed(6).replaceAll('.', ',');
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    if (texto.endsWith(',')) {
      texto = '${texto}00';
    }
    return texto;
  }

  static String _formatarDataHora(DateTime dataHora) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final diaTransacao = DateTime(dataHora.year, dataHora.month, dataHora.day);

    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');

    if (diaTransacao == hoje) {
      return 'Hoje, $hora:$minuto';
    }
    if (diaTransacao == ontem) {
      return 'Ontem, $hora:$minuto';
    }

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

  ItemTransacaoHistorico _converterDocumento(
    String id,
    Map<String, dynamic> dados,
    String cpfUsuario,
  ) {
    final tipo = (dados['tipo'] ?? '').toString().toLowerCase();
    final ativo = (dados['ativo'] ?? 'BTC').toString().toUpperCase();
    final quantidade = (dados['quantidade'] as num?)?.toDouble() ?? 0.0;
    final valorBrl = (dados['valorBrl'] as num?)?.toDouble() ??
        (dados['valor'] as num?)?.toDouble() ??
        0.0;

    final timestamp = dados['criadoEm'];
    final dataHora =
        timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final dataFormatada = _formatarDataHora(dataHora);

    if (tipo == 'deposito' || tipo == 'pix' || tipo == 'recarga') {
      return ItemTransacaoHistorico(
        id: id,
        categoria: CategoriaTransacao.deposito,
        titulo: dados['titulo']?.toString() ?? 'Depósito Pix',
        dataFormatada: dataFormatada,
        valorFormatado: '+${_formatarMoeda(valorBrl)}',
        corValor: CoresApp.verdePositivo,
        icone: Icons.pix_outlined,
        dataHora: dataHora,
      );
    }

    if (tipo == 'compra') {
      return ItemTransacaoHistorico(
        id: id,
        categoria: CategoriaTransacao.compra,
        titulo: 'Compra $ativo',
        dataFormatada: dataFormatada,
        valorFormatado: '-${_formatarMoeda(valorBrl)}',
        corValor: CoresApp.textoPrimario,
        icone: ativo == 'BTC'
            ? Icons.currency_bitcoin_rounded
            : Icons.toll_rounded,
        dataHora: dataHora,
      );
    }

    final bool foiRecebida =
        tipo == 'recebimento' || dados['cpfDestinatario'] == cpfUsuario;

    if (foiRecebida) {
      return ItemTransacaoHistorico(
        id: id,
        categoria: CategoriaTransacao.transferencia,
        titulo: 'Transferência Recebida',
        dataFormatada: dataFormatada,
        valorFormatado: '+${_formatarQuantidadeCripto(quantidade)} $ativo',
        corValor: CoresApp.verdePositivo,
        icone: Icons.call_received_rounded,
        dataHora: dataHora,
      );
    }

    return ItemTransacaoHistorico(
      id: id,
      categoria: CategoriaTransacao.transferencia,
      titulo: 'Transferência Enviada',
      dataFormatada: dataFormatada,
      valorFormatado: '-${_formatarQuantidadeCripto(quantidade)} $ativo',
      corValor: CoresApp.vermelhoNegativo,
      icone: Icons.send_outlined,
      dataHora: dataHora,
    );
  }

  Stream<List<ItemTransacaoHistorico>> _streamTransacoes(
      ClienteModelo cliente) {
    final firestore = FirebaseFirestore.instance;
    final controller =
        StreamController<List<ItemTransacaoHistorico>>.broadcast();

    final mapaProprias = <String, Map<String, dynamic>>{};
    final mapaEnviadas = <String, Map<String, dynamic>>{};
    final mapaRecebidas = <String, Map<String, dynamic>>{};

    void emitirListaCombinada() {
      if (controller.isClosed) return;

      final combinado = <String, Map<String, dynamic>>{
        ...mapaProprias,
        ...mapaEnviadas,
        ...mapaRecebidas,
      };

      final itens = combinado.entries
          .map((e) => _converterDocumento(e.key, e.value, cliente.cpf))
          .toList()
        ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

      if (itens.isEmpty) {
        itens.add(
          ItemTransacaoHistorico(
            id: 'bonus_inicial',
            categoria: CategoriaTransacao.deposito,
            titulo: 'Bônus de cadastro',
            dataFormatada: 'Conta ativada',
            valorFormatado: '+R\$ 10.000,00',
            corValor: CoresApp.verdePositivo,
            icone: Icons.pix_outlined,
            dataHora: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }

      controller.add(itens);
    }

    final subProprias = firestore
        .collection('transacoes')
        .where('cpfCliente', isEqualTo: cliente.cpf)
        .snapshots()
        .listen((snap) {
      mapaProprias
        ..clear()
        ..addEntries(snap.docs.map((d) => MapEntry(d.id, d.data())));
      emitirListaCombinada();
    }, onError: (_) => emitirListaCombinada());

    final subEnviadas = firestore
        .collection('transacoes')
        .where('cpfRemetente', isEqualTo: cliente.cpf)
        .snapshots()
        .listen((snap) {
      mapaEnviadas
        ..clear()
        ..addEntries(snap.docs.map((d) => MapEntry(d.id, d.data())));
      emitirListaCombinada();
    }, onError: (_) => emitirListaCombinada());

    final subRecebidas = firestore
        .collection('transacoes')
        .where('cpfDestinatario', isEqualTo: cliente.cpf)
        .snapshots()
        .listen((snap) {
      mapaRecebidas
        ..clear()
        ..addEntries(snap.docs.map((d) => MapEntry(d.id, d.data())));
      emitirListaCombinada();
    }, onError: (_) => emitirListaCombinada());

    controller.onCancel = () async {
      await subProprias.cancel();
      await subEnviadas.cancel();
      await subRecebidas.cancel();
    };

    return controller.stream;
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return StreamBuilder<List<ItemTransacaoHistorico>>(
      stream: _streamTransacoes(args),
      builder: (context, snapshot) {
        return HistoricoTransacoes(
          iniciaisUsuario: extrairIniciais(args.nome),
          transacoes: snapshot.data ?? const [],
          carregando: snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData,
          aoVoltar: () => Navigator.pop(context),
          aoClicarPerfil: () => abrirPerfil(context, args),
          aoClicarSair: () => sairDaConta(context),
          aoSelecionarAba: (indice) => navegarPeloMenu(context, args, indice),
        );
      },
    );
  }
}
