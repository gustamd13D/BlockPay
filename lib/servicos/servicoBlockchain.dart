import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Representa um bloco da cadeia BlockPay
class BlocoBlockchain {
  final int indice;
  final String hashBloco;
  final String hashAnterior;
  final int criadoEmMs;
  final int quantidadeTransacoes;
  final int limiteTransacoes;
  final String status;

  const BlocoBlockchain({
    required this.indice,
    required this.hashBloco,
    required this.hashAnterior,
    required this.criadoEmMs,
    required this.quantidadeTransacoes,
    this.limiteTransacoes = 5,
    this.status = 'Aberto',
  });

  factory BlocoBlockchain.deMapa(Map<String, dynamic> mapa) {
    return BlocoBlockchain(
      indice: (mapa['indice'] as num?)?.toInt() ?? 0,
      hashBloco: (mapa['hashBloco'] ?? '').toString(),
      hashAnterior: (mapa['hashAnterior'] ?? '').toString(),
      criadoEmMs: (mapa['criadoEmMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      quantidadeTransacoes:
          (mapa['quantidadeTransacoes'] as num?)?.toInt() ?? 0,
      limiteTransacoes: (mapa['limiteTransacoes'] as num?)?.toInt() ?? 5,
      status: (mapa['status'] ?? 'Aberto').toString(),
    );
  }

  Map<String, dynamic> paraMapa() {
    return {
      'indice': indice,
      'hashBloco': hashBloco,
      'hashAnterior': hashAnterior,
      'criadoEmMs': criadoEmMs,
      'quantidadeTransacoes': quantidadeTransacoes,
      'limiteTransacoes': limiteTransacoes,
      'status': status,
    };
  }
}

/// Dados preparados na fase de leitura da transacao atomica
class PreparacaoBloco {
  final BlocoBlockchain? blocoAnteriorParaSelar;
  final BlocoBlockchain blocoAlvo;
  final bool gerouNovoBloco;

  const PreparacaoBloco({
    this.blocoAnteriorParaSelar,
    required this.blocoAlvo,
    required this.gerouNovoBloco,
  });
}

/// Resultado criptografico gerado para uma transacao dentro de um bloco
class RegistroTransacaoBlockchain {
  final String hashTransacao;
  final int indiceBloco;
  final String hashBloco;
  final String hashBlocoAnterior;
  final int posicaoNoBloco;

  const RegistroTransacaoBlockchain({
    required this.hashTransacao,
    required this.indiceBloco,
    required this.hashBloco,
    required this.hashBlocoAnterior,
    required this.posicaoNoBloco,
  });
}

/// Motor da blockchain simulada do BlockPay (1 bloco por minuto ou a cada 5 transacoes)
class ServicoBlockchain {
  static final ServicoBlockchain instancia = ServicoBlockchain();

  static const String colecaoBlocos = 'blocos_blockchain';
  static const String docCadeiaAtual = 'cadeia_atual';
  static const int limiteTransacoesPorBloco = 5;
  static const int intervaloBlocoMs = 60000; // 1 minuto
  static const String hashGenesisAnterior =
      '0x0000000000000000000000000000000000000000000000000000000000000000';

  final FirebaseFirestore _banco;
  Timer? _temporizadorBlocos;
  int _ouvintesAtivos = 0;

  ServicoBlockchain({FirebaseFirestore? banco})
      : _banco = banco ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _refCadeia =>
      _banco.collection(colecaoBlocos).doc(docCadeiaAtual);

  DocumentReference<Map<String, dynamic>> _refBlocoHistorico(int indice) =>
      _banco.collection(colecaoBlocos).doc('bloco$indice');

  /// Gera hash SHA-256 com prefixo 0x a partir de um conteudo
  String gerarHashSha256(String conteudo) {
    final bytes = utf8.encode(conteudo);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}';
  }

  BlocoBlockchain _criarBlocoGenesis(int agoraMs) {
    final hashBloco = gerarHashSha256(
      '0|$hashGenesisAnterior|$agoraMs|BLOCKPAY_GENESIS',
    );
    return BlocoBlockchain(
      indice: 0,
      hashBloco: hashBloco,
      hashAnterior: hashGenesisAnterior,
      criadoEmMs: agoraMs,
      quantidadeTransacoes: 0,
      limiteTransacoes: limiteTransacoesPorBloco,
      status: 'Aberto',
    );
  }

  BlocoBlockchain _derivarProximoBloco(BlocoBlockchain anterior, int agoraMs) {
    final novoIndice = anterior.indice + 1;
    final hashAnterior = anterior.hashBloco;
    final hashNovoBloco = gerarHashSha256(
      '$novoIndice|$hashAnterior|$agoraMs|BLOCKPAY_BLOCK',
    );

    return BlocoBlockchain(
      indice: novoIndice,
      hashBloco: hashNovoBloco,
      hashAnterior: hashAnterior,
      criadoEmMs: agoraMs,
      quantidadeTransacoes: 0,
      limiteTransacoes: limiteTransacoesPorBloco,
      status: 'Aberto',
    );
  }

  /// Fase 1 (Leitura): avalia se o bloco atual expirou (1 min) ou atingiu 5 transacoes
  Future<PreparacaoBloco> prepararRegistroNaTransacao(
    Transaction transaction,
  ) async {
    final agoraMs = DateTime.now().millisecondsSinceEpoch;
    final snapCadeia = await transaction.get(_refCadeia);

    if (!snapCadeia.exists || snapCadeia.data() == null) {
      final genesis = _criarBlocoGenesis(agoraMs);
      return PreparacaoBloco(
        blocoAlvo: genesis,
        gerouNovoBloco: true,
      );
    }

    final blocoAtual = BlocoBlockchain.deMapa(snapCadeia.data()!);
    final bool atingiuLimiteTransacoes =
        blocoAtual.quantidadeTransacoes >= limiteTransacoesPorBloco;
    final bool atingiuTempoLimite =
        (agoraMs - blocoAtual.criadoEmMs) >= intervaloBlocoMs;

    if (atingiuLimiteTransacoes || atingiuTempoLimite) {
      final blocoSelado = BlocoBlockchain(
        indice: blocoAtual.indice,
        hashBloco: blocoAtual.hashBloco,
        hashAnterior: blocoAtual.hashAnterior,
        criadoEmMs: blocoAtual.criadoEmMs,
        quantidadeTransacoes: blocoAtual.quantidadeTransacoes,
        limiteTransacoes: limiteTransacoesPorBloco,
        status: 'Selado',
      );
      final proximoBloco = _derivarProximoBloco(blocoAtual, agoraMs);

      return PreparacaoBloco(
        blocoAnteriorParaSelar: blocoSelado,
        blocoAlvo: proximoBloco,
        gerouNovoBloco: true,
      );
    }

    return PreparacaoBloco(
      blocoAlvo: blocoAtual,
      gerouNovoBloco: false,
    );
  }

  /// Fase 2 (Calculo): deriva o hash da transacao a partir do hash do bloco ativo
  RegistroTransacaoBlockchain calcularRegistroTransacao(
    PreparacaoBloco preparacao, {
    required String resumoDados,
  }) {
    final bloco = preparacao.blocoAlvo;
    final posicao = bloco.quantidadeTransacoes + 1;
    final agoraMs = DateTime.now().millisecondsSinceEpoch;

    final hashTransacao = gerarHashSha256(
      '${bloco.hashBloco}|${bloco.indice}|$posicao|$resumoDados|$agoraMs',
    );

    return RegistroTransacaoBlockchain(
      hashTransacao: hashTransacao,
      indiceBloco: bloco.indice,
      hashBloco: bloco.hashBloco,
      hashBlocoAnterior: bloco.hashAnterior,
      posicaoNoBloco: posicao,
    );
  }

  /// Fase 3 (Escrita): persiste o bloco atualizado e o historico na mesma transacao atomica
  void aplicarEscritaNaTransacao(
    Transaction transaction,
    PreparacaoBloco preparacao,
    RegistroTransacaoBlockchain registro,
  ) {
    if (preparacao.blocoAnteriorParaSelar != null) {
      final anterior = preparacao.blocoAnteriorParaSelar!;
      transaction.set(
        _refBlocoHistorico(anterior.indice),
        {
          ...anterior.paraMapa(),
          'seladoEm': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    final bool blocoCompleto =
        registro.posicaoNoBloco >= limiteTransacoesPorBloco;

    final blocoAtualizado = BlocoBlockchain(
      indice: preparacao.blocoAlvo.indice,
      hashBloco: preparacao.blocoAlvo.hashBloco,
      hashAnterior: preparacao.blocoAlvo.hashAnterior,
      criadoEmMs: preparacao.blocoAlvo.criadoEmMs,
      quantidadeTransacoes: registro.posicaoNoBloco,
      limiteTransacoes: limiteTransacoesPorBloco,
      status: blocoCompleto ? 'Cheio (5/5)' : 'Aberto',
    );

    transaction.set(
      _refCadeia,
      {
        ...blocoAtualizado.paraMapa(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
    );

    transaction.set(
      _refBlocoHistorico(blocoAtualizado.indice),
      {
        ...blocoAtualizado.paraMapa(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Verifica se ja passou 1 minuto desde o ultimo bloco e gera o proximo automaticamente
  Future<void> verificarEGerarBlocoPorTempo() async {
    try {
      await _banco.runTransaction((transaction) async {
        final agoraMs = DateTime.now().millisecondsSinceEpoch;
        final snapCadeia = await transaction.get(_refCadeia);

        if (!snapCadeia.exists || snapCadeia.data() == null) {
          final genesis = _criarBlocoGenesis(agoraMs);
          transaction.set(_refCadeia, {
            ...genesis.paraMapa(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
          transaction.set(_refBlocoHistorico(0), {
            ...genesis.paraMapa(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
          return;
        }

        final blocoAtual = BlocoBlockchain.deMapa(snapCadeia.data()!);
        if ((agoraMs - blocoAtual.criadoEmMs) >= intervaloBlocoMs) {
          final blocoSelado = BlocoBlockchain(
            indice: blocoAtual.indice,
            hashBloco: blocoAtual.hashBloco,
            hashAnterior: blocoAtual.hashAnterior,
            criadoEmMs: blocoAtual.criadoEmMs,
            quantidadeTransacoes: blocoAtual.quantidadeTransacoes,
            limiteTransacoes: limiteTransacoesPorBloco,
            status: 'Selado',
          );

          final proximo = _derivarProximoBloco(blocoAtual, agoraMs);

          transaction.set(
            _refBlocoHistorico(blocoSelado.indice),
            {
              ...blocoSelado.paraMapa(),
              'seladoEm': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.set(_refCadeia, {
            ...proximo.paraMapa(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

          transaction.set(_refBlocoHistorico(proximo.indice), {
            ...proximo.paraMapa(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (_) {
      // Evita interromper a interface em caso de concorrencia de rede
    }
  }

  /// Inicia verificacao periodica para mintar 1 novo bloco a cada 1 minuto
  void iniciarGeracaoAutomatica() {
    _ouvintesAtivos++;
    if (_temporizadorBlocos != null) return;

    verificarEGerarBlocoPorTempo();
    _temporizadorBlocos = Timer.periodic(
      const Duration(seconds: 10),
      (_) => verificarEGerarBlocoPorTempo(),
    );
  }

  /// Encerra o temporizador quando nenhuma tela ativa estiver observando
  void pararGeracaoAutomatica() {
    if (_ouvintesAtivos > 0) {
      _ouvintesAtivos--;
    }
    if (_ouvintesAtivos <= 0) {
      _ouvintesAtivos = 0;
      _temporizadorBlocos?.cancel();
      _temporizadorBlocos = null;
    }
  }

  /// Stream em tempo real do bloco ativo atual na cadeia
  Stream<BlocoBlockchain?> streamBlocoAtual() {
    return _refCadeia.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return BlocoBlockchain.deMapa(snap.data()!);
    });
  }
}
