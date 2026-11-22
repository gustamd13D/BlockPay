import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';

/// Modelo de representacao de um ativo exibido no mercado
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

class MercadoCripto extends StatefulWidget {
  final String iniciaisUsuario;
  final void Function(AtivoMercado ativo)? aoSelecionarAtivo;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const MercadoCripto({
    super.key,
    this.iniciaisUsuario = 'AL',
    this.aoSelecionarAtivo,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<MercadoCripto> createState() => _MercadoCriptoState();
}

class _MercadoCriptoState extends State<MercadoCripto> {
  List<AtivoMercado> _ativos = const [
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

  Timer? _temporizadorCotacao;

  @override
  void initState() {
    super.initState();
    _buscarCotacoesMercado();
    _temporizadorCotacao = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _buscarCotacoesMercado(),
    );
  }

  @override
  void dispose() {
    _temporizadorCotacao?.cancel();
    super.dispose();
  }

  Future<void> _buscarCotacoesMercado() async {
    try {
      final uriCoinGecko = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price'
        '?ids=bitcoin,ethereum,solana,cardano&vs_currencies=brl&include_24hr_change=true',
      );
      final resposta =
          await http.get(uriCoinGecko).timeout(const Duration(seconds: 8));

      if (resposta.statusCode == 200) {
        final json = jsonDecode(resposta.body) as Map<String, dynamic>;
        if (!mounted) return;

        setState(() {
          _ativos = _ativos.map((ativo) {
            final dados = json[ativo.idApi] as Map<String, dynamic>?;
            if (dados == null) return ativo;

            final novoPreco =
                (dados['brl'] as num?)?.toDouble() ?? ativo.precoBrl;
            final novaVariacao =
                (dados['brl_24h_change'] as num?)?.toDouble() ??
                    ativo.variacao24h;

            return ativo.copiarCom(
              precoBrl: novoPreco,
              variacao24h: novaVariacao,
              pontosGrafico: _gerarPontosTendencia(novaVariacao),
            );
          }).toList();
        });
        return;
      }
    } catch (_) {
      // Tenta fallback abaixo
    }

    try {
      final uriAwesome = Uri.parse(
        'https://economia.awesomeapi.com.br/json/last/BTC-BRL,ETH-BRL,SOL-BRL',
      );
      final resposta =
          await http.get(uriAwesome).timeout(const Duration(seconds: 8));

      if (resposta.statusCode == 200) {
        final json = jsonDecode(resposta.body) as Map<String, dynamic>;
        if (!mounted) return;

        final mapaChaves = {
          'BTC': 'BTCBRL',
          'ETH': 'ETHBRL',
          'SOL': 'SOLBRL',
        };

        setState(() {
          _ativos = _ativos.map((ativo) {
            final chave = mapaChaves[ativo.sigla];
            if (chave == null) return ativo;
            final dados = json[chave] as Map<String, dynamic>?;
            if (dados == null) return ativo;

            final novoPreco = double.tryParse(dados['bid']?.toString() ?? '') ??
                ativo.precoBrl;
            final novaVariacao =
                double.tryParse(dados['pctChange']?.toString() ?? '') ??
                    ativo.variacao24h;

            return ativo.copiarCom(
              precoBrl: novoPreco,
              variacao24h: novaVariacao,
              pontosGrafico: _gerarPontosTendencia(novaVariacao),
            );
          }).toList();
        });
      }
    } catch (_) {
      // Mantem cotacoes atuais caso esteja offline
    }
  }

  List<double> _gerarPontosTendencia(double variacao) {
    if (variacao >= 0) {
      return const [0.22, 0.35, 0.30, 0.62, 0.54, 0.85, 0.96];
    }
    return const [0.92, 0.76, 0.65, 0.25, 0.40, 0.56, 0.38];
  }

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

  static String _formatarPercentual(double variacao) {
    final sinal = variacao >= 0 ? '+' : '-';
    final texto = variacao.abs().toStringAsFixed(1).replaceAll('.', ',');
    return '$sinal$texto%';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool telaGrande = constraints.maxWidth >= 800;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: CoresApp.superficie,
          ),
          child: Scaffold(
            backgroundColor: CoresApp.fundo,
            body: SafeArea(
              bottom: telaGrande,
              child: telaGrande
                  ? _construirLayoutDesktop()
                  : _construirLayoutMobile(),
            ),
            bottomNavigationBar: telaGrande
                ? null
                : MenuInferiorWrapper(
                    indiceAtivo: 1,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }

  Widget _construirConteudoLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cotações em tempo real',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        ..._ativos.map(
          (ativo) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CardCriptoMercado(
              ativo: ativo,
              precoFormatado: _formatarMoeda(ativo.precoBrl),
              variacaoFormatada: _formatarPercentual(ativo.variacao24h),
              aoClicar: () => widget.aoSelecionarAtivo?.call(ativo),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _BannerDicaMercado(),
      ],
    );
  }

  Widget _construirLayoutMobile() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            CabecalhoMobileWrapper(
              titulo: 'Mercado',
              iniciaisUsuario: widget.iniciaisUsuario,
              mostrarBotaoVoltar: true,
              aoVoltar: widget.aoVoltar,
              aoClicarPerfil: widget.aoClicarPerfil,
              aoClicarSair: widget.aoClicarSair,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _construirConteudoLista(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirLayoutDesktop() {
    return Column(
      children: [
        CabecalhoDesktopWrapper(
          iniciaisUsuario: widget.iniciaisUsuario,
          indiceAtivo: 1,
          etiquetaTela: 'Mercado',
          aoSelecionarAba: widget.aoSelecionarAba,
          aoClicarPerfil: widget.aoClicarPerfil,
          aoClicarSair: widget.aoClicarSair,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _BotaoVoltar(aoClicar: widget.aoVoltar),
                        const SizedBox(width: 12),
                        const Text(
                          'Mercado',
                          style: TextStyle(
                            color: CoresApp.textoPrimario,
                            fontSize: 22,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _construirConteudoLista(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardCriptoMercado extends StatelessWidget {
  final AtivoMercado ativo;
  final String precoFormatado;
  final String variacaoFormatada;
  final VoidCallback? aoClicar;

  const _CardCriptoMercado({
    required this.ativo,
    required this.precoFormatado,
    required this.variacaoFormatada,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final bool positiva = ativo.variacao24h >= 0;
    final Color corDestaque =
        positiva ? CoresApp.verdePositivo : CoresApp.vermelhoNegativo;
    final Color corFundoBadge =
        positiva ? CoresApp.verdeSuave : const Color(0x15FF5252);

    return Material(
      color: CoresApp.superficie,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CoresApp.borda,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: corFundoBadge,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  ativo.sigla,
                  style: TextStyle(
                    color: corDestaque,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ativo.nome,
                      style: const TextStyle(
                        color: CoresApp.textoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Preço atual',
                      style: TextStyle(
                        color: CoresApp.textoSecundario,
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                height: 24,
                child: CustomPaint(
                  painter: _PintorSparkline(
                    pontos: ativo.pontosGrafico,
                    cor: corDestaque,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    precoFormatado,
                    style: const TextStyle(
                      color: CoresApp.textoPrimario,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    variacaoFormatada,
                    style: TextStyle(
                      color: corDestaque,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PintorSparkline extends CustomPainter {
  final List<double> pontos;
  final Color cor;

  const _PintorSparkline({
    required this.pontos,
    required this.cor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;

    final pincel = Paint()
      ..color = cor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final caminho = Path();
    final passoX = size.width / (pontos.length - 1);

    for (var i = 0; i < pontos.length; i++) {
      final norm = pontos[i].clamp(0.0, 1.0);
      final x = i * passoX;
      final y = size.height - (norm * size.height);
      if (i == 0) {
        caminho.moveTo(x, y);
      } else {
        caminho.lineTo(x, y);
      }
    }

    canvas.drawPath(caminho, pincel);
  }

  @override
  bool shouldRepaint(covariant _PintorSparkline oldDelegate) {
    return oldDelegate.pontos != pontos || oldDelegate.cor != cor;
  }
}

class _BannerDicaMercado extends StatelessWidget {
  const _BannerDicaMercado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.superficieAvatar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: CoresApp.cianoPrimario,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acompanhe as oscilações do mercado antes de comprar ou vender seus ativos.',
              style: TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoVoltar extends StatelessWidget {
  final VoidCallback? aoClicar;

  const _BotaoVoltar({this.aoClicar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoClicar ?? () => Navigator.maybePop(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CoresApp.superficie,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: CoresApp.textoPrimario,
          size: 18,
        ),
      ),
    );
  }
}
