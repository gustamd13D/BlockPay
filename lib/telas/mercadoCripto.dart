import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color superficieDestaque = Color(0xFF21293A);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1500E5FF);
  static const Color verdePositivo = Color(0xFF00E676);
  static const Color verdeSuave = Color(0x1500E676);
  static const Color vermelhoNegativo = Color(0xFFFF5252);
  static const Color vermelhoSuave = Color(0x15FF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

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
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const MercadoCripto({
    super.key,
    this.iniciaisUsuario = 'AL',
    this.aoSelecionarAtivo,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
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
            systemNavigationBarColor: _CoresApp.superficie,
          ),
          child: Scaffold(
            backgroundColor: _CoresApp.fundo,
            body: SafeArea(
              bottom: telaGrande,
              child: telaGrande
                  ? _construirLayoutDesktop()
                  : _construirLayoutMobile(),
            ),
            bottomNavigationBar: telaGrande
                ? null
                : _BarraNavegacaoInferior(
                    indiceAtivo: 1,
                    aoClicarInicio: widget.aoClicarInicio,
                    aoClicarMercado: widget.aoClicarMercado,
                    aoClicarPix: widget.aoClicarPix,
                    aoClicarHistorico: widget.aoClicarHistorico,
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
            color: _CoresApp.textoSecundario,
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
            _CabecalhoMobile(
              titulo: 'Mercado',
              iniciais: widget.iniciaisUsuario,
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
        _CabecalhoDesktop(
          iniciais: widget.iniciaisUsuario,
          indiceAtivo: 1,
          aoClicarPerfil: widget.aoClicarPerfil,
          aoClicarSair: widget.aoClicarSair,
          aoClicarInicio: widget.aoClicarInicio,
          aoClicarMercado: widget.aoClicarMercado,
          aoClicarPix: widget.aoClicarPix,
          aoClicarHistorico: widget.aoClicarHistorico,
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
                            color: _CoresApp.textoPrimario,
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
        positiva ? _CoresApp.verdePositivo : _CoresApp.vermelhoNegativo;
    final Color corFundoBadge =
        positiva ? _CoresApp.verdeSuave : _CoresApp.vermelhoSuave;

    return Material(
      color: _CoresApp.superficie,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _CoresApp.borda,
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
                        color: _CoresApp.textoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Preço atual',
                      style: TextStyle(
                        color: _CoresApp.textoSecundario,
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
                      color: _CoresApp.textoPrimario,
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
        color: _CoresApp.superficieDestaque,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: _CoresApp.cianoPrimario,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acompanhe as oscilações do mercado antes de comprar ou vender seus ativos.',
              style: TextStyle(
                color: _CoresApp.textoSecundario,
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
          color: _CoresApp.superficie,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: _CoresApp.textoPrimario,
          size: 18,
        ),
      ),
    );
  }
}

class _CabecalhoMobile extends StatelessWidget {
  final String titulo;
  final String iniciais;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const _CabecalhoMobile({
    required this.titulo,
    required this.iniciais,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _BotaoVoltar(aoClicar: aoVoltar),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: _CoresApp.textoPrimario,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _AvatarUsuario(
            iniciais: iniciais,
            aoClicarPerfil: aoClicarPerfil,
            aoClicarSair: aoClicarSair,
          ),
        ],
      ),
    );
  }
}

class _CabecalhoDesktop extends StatelessWidget {
  final String iniciais;
  final int indiceAtivo;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const _CabecalhoDesktop({
    required this.iniciais,
    required this.indiceAtivo,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _CoresApp.superficie,
        border: Border(
          bottom: BorderSide(color: _CoresApp.borda, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _CoresApp.cianoSuave,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _CoresApp.cianoPrimario,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: _CoresApp.cianoPrimario,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'BlockPay',
                style: TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _ItemMenuSuperior(
                icone: Icons.account_balance_wallet_outlined,
                rotulo: 'Início',
                ativo: indiceAtivo == 0,
                aoClicar: aoClicarInicio,
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.show_chart_rounded,
                rotulo: 'Mercado',
                ativo: indiceAtivo == 1,
                aoClicar: aoClicarMercado,
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.pix_outlined,
                rotulo: 'Pix',
                ativo: indiceAtivo == 2,
                aoClicar: aoClicarPix,
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.history_rounded,
                rotulo: 'Histórico',
                ativo: indiceAtivo == 3,
                aoClicar: aoClicarHistorico,
              ),
              const SizedBox(width: 20),
              _AvatarUsuario(
                iniciais: iniciais,
                aoClicarPerfil: aoClicarPerfil,
                aoClicarSair: aoClicarSair,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemMenuSuperior extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback? aoClicar;

  const _ItemMenuSuperior({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? _CoresApp.cianoPrimario : _CoresApp.textoSecundario;

    return InkWell(
      onTap: aoClicar,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? _CoresApp.cianoSuave : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: cor, size: 18),
            const SizedBox(width: 6),
            Text(
              rotulo,
              style: TextStyle(
                color: cor,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarUsuario extends StatelessWidget {
  final String iniciais;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const _AvatarUsuario({
    required this.iniciais,
    this.aoClicarPerfil,
    this.aoClicarSair,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Opções da conta',
      offset: const Offset(0, 44),
      color: _CoresApp.superficie,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _CoresApp.borda, width: 1),
      ),
      onSelected: (opcao) {
        if (opcao == 'conta') {
          aoClicarPerfil?.call();
        } else if (opcao == 'sair') {
          aoClicarSair?.call();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'conta',
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: _CoresApp.cianoPrimario,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Minha Conta',
                style: TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'sair',
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: _CoresApp.vermelhoNegativo,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Sair',
                style: TextStyle(
                  color: _CoresApp.vermelhoNegativo,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _CoresApp.superficieDestaque,
          shape: BoxShape.circle,
        ),
        child: Text(
          iniciais.toUpperCase(),
          style: const TextStyle(
            color: _CoresApp.cianoPrimario,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BarraNavegacaoInferior extends StatelessWidget {
  final int indiceAtivo;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const _BarraNavegacaoInferior({
    required this.indiceAtivo,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _CoresApp.superficie,
        border: Border(
          top: BorderSide(color: _CoresApp.borda, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ItemMenuRodape(
                    icone: Icons.account_balance_wallet_outlined,
                    rotulo: 'Início',
                    ativo: indiceAtivo == 0,
                    aoClicar: aoClicarInicio,
                  ),
                  _ItemMenuRodape(
                    icone: Icons.show_chart_rounded,
                    rotulo: 'Mercado',
                    ativo: indiceAtivo == 1,
                    aoClicar: aoClicarMercado,
                  ),
                  _ItemMenuRodape(
                    icone: Icons.pix_outlined,
                    rotulo: 'Pix',
                    ativo: indiceAtivo == 2,
                    aoClicar: aoClicarPix,
                  ),
                  _ItemMenuRodape(
                    icone: Icons.history_rounded,
                    rotulo: 'Histórico',
                    ativo: indiceAtivo == 3,
                    aoClicar: aoClicarHistorico,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemMenuRodape extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback? aoClicar;

  const _ItemMenuRodape({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? _CoresApp.cianoPrimario : _CoresApp.textoSecundario;

    return Expanded(
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cor, size: 22),
              const SizedBox(height: 4),
              Text(
                rotulo,
                style: TextStyle(
                  color: cor,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
