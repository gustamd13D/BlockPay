import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Modelo de representacao de um ativo exibido no mercado e usado nas cotacoes
class AtivoMercado {
  final String idApi;
  final String sigla;
  final String nome;
  final double precoBrl;
  final double variacao24h;
  final List<double> pontosGrafico;

  const AtivoMercado({
    required this.idApi,
    required this.sigla,
    required this.nome,
    required this.precoBrl,
    required this.variacao24h,
    required this.pontosGrafico,
  });

  AtivoMercado copiarCom({
    double? precoBrl,
    double? variacao24h,
    List<double>? pontosGrafico,
  }) {
    return AtivoMercado(
      idApi: idApi,
      sigla: sigla,
      nome: nome,
      precoBrl: precoBrl ?? this.precoBrl,
      variacao24h: variacao24h ?? this.variacao24h,
      pontosGrafico: pontosGrafico ?? this.pontosGrafico,
    );
  }
}

/// Servico centralizado de cotacoes em tempo real (CoinGecko + fallback AwesomeAPI)
class ServicoCotacoes {
  static final ServicoCotacoes instancia = ServicoCotacoes._interno();

  factory ServicoCotacoes() => instancia;

  ServicoCotacoes._interno() {
    atualizarCotacoes();
  }

  static const List<AtivoMercado> _ativosPadrao = [
    AtivoMercado(
      idApi: 'bitcoin',
      sigla: 'BTC',
      nome: 'Bitcoin',
      precoBrl: 310450.00,
      variacao24h: 3.4,
      pontosGrafico: [0.25, 0.38, 0.32, 0.65, 0.58, 0.88, 0.95],
    ),
    AtivoMercado(
      idApi: 'ethereum',
      sigla: 'ETH',
      nome: 'Ethereum',
      precoBrl: 16200.00,
      variacao24h: -1.2,
      pontosGrafico: [0.92, 0.78, 0.62, 0.22, 0.38, 0.60, 0.45],
    ),
    AtivoMercado(
      idApi: 'solana',
      sigla: 'SOL',
      nome: 'Solana',
      precoBrl: 680.00,
      variacao24h: 12.5,
      pontosGrafico: [0.15, 0.28, 0.42, 0.56, 0.48, 0.82, 0.95],
    ),
    AtivoMercado(
      idApi: 'cardano',
      sigla: 'ADA',
      nome: 'Cardano',
      precoBrl: 2.45,
      variacao24h: -0.5,
      pontosGrafico: [0.90, 0.68, 0.80, 0.58, 0.25, 0.48, 0.35],
    ),
  ];

  final ValueNotifier<List<AtivoMercado>> ativosNotifier =
      ValueNotifier<List<AtivoMercado>>(_ativosPadrao);

  Timer? _temporizador;
  int _ouvintesAtivos = 0;
  DateTime? _ultimaAtualizacao;
  Future<List<AtivoMercado>>? _requisicaoEmAndamento;

  List<AtivoMercado> get ativosAtualizados => ativosNotifier.value;

  /// Retorna a cotacao atual em BRL da moeda informada
  double obterCotacaoBrl(String sigla) {
    final codigo = sigla.toUpperCase().trim();
    if (codigo == 'BRL') return 1.0;

    for (final ativo in ativosNotifier.value) {
      if (ativo.sigla.toUpperCase() == codigo) {
        return ativo.precoBrl;
      }
    }

    switch (codigo) {
      case 'BTC':
        return 310450.00;
      case 'ETH':
        return 16200.00;
      case 'SOL':
        return 680.00;
      case 'ADA':
        return 2.45;
      default:
        return 0.0;
    }
  }

  /// Inicia a atualizacao periodica a cada 60 segundos enquanto houver telas ouvindo
  void iniciarAtualizacaoAutomatica() {
    _ouvintesAtivos++;
    atualizarCotacoes();

    _temporizador ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => atualizarCotacoes(forcar: true),
    );
  }

  /// Encerra o temporizador quando nenhuma tela estiver mais observando
  void pararAtualizacaoAutomatica() {
    if (_ouvintesAtivos > 0) {
      _ouvintesAtivos--;
    }
    if (_ouvintesAtivos == 0) {
      _temporizador?.cancel();
      _temporizador = null;
    }
  }

  /// Atualiza as cotacoes na CoinGecko com fallback automatico na AwesomeAPI
  Future<List<AtivoMercado>> atualizarCotacoes({bool forcar = false}) {
    if (!forcar && _ultimaAtualizacao != null) {
      final decorrido = DateTime.now().difference(_ultimaAtualizacao!);
      if (decorrido.inSeconds < 15) {
        return Future.value(ativosNotifier.value);
      }
    }

    if (_requisicaoEmAndamento != null) {
      return _requisicaoEmAndamento!;
    }

    final futuro = _executarBuscaCotacoes();
    _requisicaoEmAndamento = futuro;
    futuro.whenComplete(() {
      if (identical(_requisicaoEmAndamento, futuro)) {
        _requisicaoEmAndamento = null;
      }
    });
    return futuro;
  }

  Future<List<AtivoMercado>> _executarBuscaCotacoes() async {
    try {
      final uriCoinGecko = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price'
        '?ids=bitcoin,ethereum,solana,cardano&vs_currencies=brl&include_24hr_change=true',
      );
      final resposta =
          await http.get(uriCoinGecko).timeout(const Duration(seconds: 8));

      if (resposta.statusCode == 200) {
        final json = jsonDecode(resposta.body) as Map<String, dynamic>;

        final atualizados = ativosNotifier.value.map((ativo) {
          final dados = json[ativo.idApi] as Map<String, dynamic>?;
          if (dados == null) return ativo;

          final novoPreco =
              (dados['brl'] as num?)?.toDouble() ?? ativo.precoBrl;
          final novaVariacao = (dados['brl_24h_change'] as num?)?.toDouble() ??
              ativo.variacao24h;

          return ativo.copiarCom(
            precoBrl: novoPreco,
            variacao24h: novaVariacao,
            pontosGrafico: _gerarPontosTendencia(novaVariacao),
          );
        }).toList();

        ativosNotifier.value = atualizados;
        _ultimaAtualizacao = DateTime.now();
        return atualizados;
      }
    } catch (_) {
      // Tenta fallback abaixo
    }

    try {
      final uriAwesome = Uri.parse(
        'https://economia.awesomeapi.com.br/json/last/BTC-BRL,ETH-BRL,SOL-BRL,ADA-BRL',
      );
      final resposta =
          await http.get(uriAwesome).timeout(const Duration(seconds: 8));

      if (resposta.statusCode == 200) {
        final json = jsonDecode(resposta.body) as Map<String, dynamic>;

        const mapaChaves = {
          'BTC': 'BTCBRL',
          'ETH': 'ETHBRL',
          'SOL': 'SOLBRL',
          'ADA': 'ADABRL',
        };

        final atualizados = ativosNotifier.value.map((ativo) {
          final chave = mapaChaves[ativo.sigla];
          if (chave == null) return ativo;
          final dados = json[chave] as Map<String, dynamic>?;
          if (dados == null) return ativo;

          final novoPreco =
              double.tryParse(dados['bid']?.toString() ?? '') ?? ativo.precoBrl;
          final novaVariacao =
              double.tryParse(dados['pctChange']?.toString() ?? '') ??
                  ativo.variacao24h;

          return ativo.copiarCom(
            precoBrl: novoPreco,
            variacao24h: novaVariacao,
            pontosGrafico: _gerarPontosTendencia(novaVariacao),
          );
        }).toList();

        ativosNotifier.value = atualizados;
        _ultimaAtualizacao = DateTime.now();
        return atualizados;
      }
    } catch (_) {
      // Mantem cotacoes atuais caso esteja offline
    }

    return ativosNotifier.value;
  }

  List<double> _gerarPontosTendencia(double variacao) {
    if (variacao >= 0) {
      return const [0.22, 0.35, 0.30, 0.62, 0.54, 0.85, 0.96];
    }
    return const [0.92, 0.76, 0.65, 0.25, 0.40, 0.56, 0.38];
  }
}
