import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color superficieAvatar = Color(0xFF21293A);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1500E5FF);
  static const Color verdePositivo = Color(0xFF00E676);
  static const Color verdeSuave = Color(0x1500E676);
  static const Color amareloBitcoin = Color(0xFFFFD600);
  static const Color amareloSuave = Color(0x15FFD600);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class Dashboard extends StatelessWidget {
  /// Dados exibidos na carteira (com valores padrao da simulacao inicial)
  final String iniciaisUsuario;
  final double saldoBrl;
  final double quantidadeBtc;
  final double valorBtcBrl;
  final double quantidadeEth;
  final double valorEthBrl;
  final double variacaoHojeBrl;
  final double variacaoHojePercentual;
  final String descricaoUltimaAtividade;
  final double valorUltimaAtividade;
  final List<double> pontosEvolucao7Dias;

  /// Callbacks de navegacao dos elementos clicaveis
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarVerTodas;
  final VoidCallback? aoClicarTransferir;
  final VoidCallback? aoClicarBlockchain;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const Dashboard({
    super.key,
    this.iniciaisUsuario = 'AL',
    this.saldoBrl = 1000.00,
    this.quantidadeBtc = 0.034,
    this.valorBtcBrl = 10420.00,
    this.quantidadeEth = 0.25,
    this.valorEthBrl = 4000.00,
    this.variacaoHojeBrl = 420.00,
    this.variacaoHojePercentual = 2.8,
    this.descricaoUltimaAtividade = 'Depósito via Pix',
    this.valorUltimaAtividade = 1000.00,
    this.pontosEvolucao7Dias = const [0.32, 0.0, 0.49, 0.81, 0.65, 0.89, 1.0],
    this.aoClicarPerfil,
    this.aoClicarVerTodas,
    this.aoClicarTransferir,
    this.aoClicarBlockchain,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
  });

  double get _patrimonioTotal => saldoBrl + valorBtcBrl + valorEthBrl;

  /// Formata valores monetarios no padrao brasileiro (ex: 15.420,00)
  static String _formatarMoeda(double valor) {
    final negativo = valor < 0;
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

    return '${negativo ? '-' : ''}R\$ ${buffer.toString()},$centavos';
  }

  /// Formata quantidades decimais com virgula (ex: 0,034)
  static String _formatarDecimal(double valor, int casas) {
    var texto = valor.toStringAsFixed(casas).replaceAll('.', ',');
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    if (texto.endsWith(',')) {
      texto = '${texto}00';
    }
    return texto;
  }

  Widget _construirSecaoAtivos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSecao(texto: 'SEUS ATIVOS'),
        const SizedBox(height: 10),
        _CardAtivo(
          corFundoIcone: _CoresApp.verdeSuave,
          iconeWidget: const Text(
            'R\$',
            style: TextStyle(
              color: _CoresApp.verdePositivo,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          titulo: 'Saldo em BRL',
          subtitulo: 'Disponível para uso',
          valorBrlFormatado: _formatarMoeda(saldoBrl),
        ),
        const SizedBox(height: 10),
        _CardAtivo(
          corFundoIcone: _CoresApp.amareloSuave,
          iconeWidget: const Icon(
            Icons.currency_bitcoin_rounded,
            color: _CoresApp.amareloBitcoin,
            size: 22,
          ),
          titulo: 'Bitcoin (BTC)',
          subtitulo: '${_formatarDecimal(quantidadeBtc, 6)} BTC',
          valorBrlFormatado: _formatarMoeda(valorBtcBrl),
        ),
        const SizedBox(height: 10),
        _CardAtivo(
          corFundoIcone: _CoresApp.cianoSuave,
          iconeWidget: const Icon(
            Icons.toll_rounded,
            color: _CoresApp.cianoPrimario,
            size: 22,
          ),
          titulo: 'Ethereum (ETH)',
          subtitulo: '${_formatarDecimal(quantidadeEth, 4)} ETH',
          valorBrlFormatado: _formatarMoeda(valorEthBrl),
        ),
      ],
    );
  }

  Widget _construirSecaoAtividades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _TituloSecao(texto: 'ATIVIDADES RECENTES'),
            InkWell(
              onTap: aoClicarVerTodas,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    color: _CoresApp.cianoPrimario,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CardAtividadeRecente(
          descricao: descricaoUltimaAtividade,
          valorFormatado: '+${_formatarMoeda(valorUltimaAtividade)}',
        ),
      ],
    );
  }

  Widget _construirSecaoAcoesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSecao(texto: 'AÇÕES RÁPIDAS'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BotaoAcaoRapida(
                icone: Icons.send_outlined,
                rotulo: 'Transferir',
                aoClicar: aoClicarTransferir,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BotaoAcaoRapida(
                icone: Icons.storage_rounded,
                rotulo: 'Blockchain',
                aoClicar: aoClicarBlockchain,
              ),
            ),
          ],
        ),
      ],
    );
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
                    indiceAtivo: 0,
                    aoClicarInicio: aoClicarInicio,
                    aoClicarMercado: aoClicarMercado,
                    aoClicarPix: aoClicarPix,
                    aoClicarHistorico: aoClicarHistorico,
                  ),
          ),
        );
      },
    );
  }

  /// Layout compacto em 1 coluna para celulares
  Widget _construirLayoutMobile() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            _CabecalhoCarteira(
              iniciais: iniciaisUsuario,
              aoClicarPerfil: aoClicarPerfil,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CardPatrimonioTotal(
                      valorTotalFormatado: _formatarMoeda(_patrimonioTotal),
                      variacaoHojeFormatada:
                          '+${_formatarMoeda(variacaoHojeBrl)} (${_formatarDecimal(variacaoHojePercentual, 1)}%) hoje',
                    ),
                    const SizedBox(height: 18),
                    _CardEvolucaoCarteira(
                      pontos: pontosEvolucao7Dias,
                      alturaGrafico: 76,
                    ),
                    const SizedBox(height: 22),
                    _construirSecaoAtivos(),
                    const SizedBox(height: 22),
                    _construirSecaoAtividades(),
                    const SizedBox(height: 22),
                    _construirSecaoAcoesRapidas(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout expandido em 2 colunas com navegacao superior para Web e Tablets
  Widget _construirLayoutDesktop() {
    return Column(
      children: [
        _CabecalhoDesktop(
          iniciais: iniciaisUsuario,
          indiceAtivo: 0,
          aoClicarPerfil: aoClicarPerfil,
          aoClicarInicio: aoClicarInicio,
          aoClicarMercado: aoClicarMercado,
          aoClicarPix: aoClicarPix,
          aoClicarHistorico: aoClicarHistorico,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coluna esquerda: visao geral, grafico e atividades
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CardPatrimonioTotal(
                            valorTotalFormatado:
                                _formatarMoeda(_patrimonioTotal),
                            variacaoHojeFormatada:
                                '+${_formatarMoeda(variacaoHojeBrl)} (${_formatarDecimal(variacaoHojePercentual, 1)}%) hoje',
                          ),
                          const SizedBox(height: 20),
                          _CardEvolucaoCarteira(
                            pontos: pontosEvolucao7Dias,
                            alturaGrafico: 115,
                          ),
                          const SizedBox(height: 24),
                          _construirSecaoAtividades(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Coluna direita: acoes rapidas e lista de ativos
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _construirSecaoAcoesRapidas(),
                          const SizedBox(height: 24),
                          _construirSecaoAtivos(),
                        ],
                      ),
                    ),
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

class _CabecalhoCarteira extends StatelessWidget {
  final String iniciais;
  final VoidCallback? aoClicarPerfil;

  const _CabecalhoCarteira({
    required this.iniciais,
    this.aoClicarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Minha Carteira',
              style: TextStyle(
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
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const _CabecalhoDesktop({
    required this.iniciais,
    required this.indiceAtivo,
    this.aoClicarPerfil,
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
          bottom: BorderSide(
            color: _CoresApp.borda,
            width: 1,
          ),
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
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _CoresApp.cianoSuave,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Minha Carteira',
                  style: TextStyle(
                    color: _CoresApp.cianoPrimario,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
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

  const _AvatarUsuario({
    required this.iniciais,
    this.aoClicarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoClicarPerfil,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _CoresApp.superficieAvatar,
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

class _CardPatrimonioTotal extends StatelessWidget {
  final String valorTotalFormatado;
  final String variacaoHojeFormatada;

  const _CardPatrimonioTotal({
    required this.valorTotalFormatado,
    required this.variacaoHojeFormatada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _CoresApp.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _CoresApp.borda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PATRIMÔNIO TOTAL',
            style: TextStyle(
              color: _CoresApp.textoSecundario,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valorTotalFormatado,
              style: const TextStyle(
                color: _CoresApp.textoPrimario,
                fontSize: 32,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.north_east_rounded,
                color: _CoresApp.verdePositivo,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  variacaoHojeFormatada,
                  style: const TextStyle(
                    color: _CoresApp.verdePositivo,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardEvolucaoCarteira extends StatelessWidget {
  final List<double> pontos;
  final double alturaGrafico;

  const _CardEvolucaoCarteira({
    required this.pontos,
    this.alturaGrafico = 76,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CoresApp.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _CoresApp.borda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evolução da carteira',
                style: TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '7 dias',
                style: TextStyle(
                  color: _CoresApp.textoSecundario,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: alturaGrafico,
            width: double.infinity,
            child: CustomPaint(
              painter: _PintorGraficoLinha(pontos: pontos),
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorGraficoLinha extends CustomPainter {
  final List<double> pontos;

  const _PintorGraficoLinha({required this.pontos});

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;

    final pincelLinha = Paint()
      ..color = _CoresApp.cianoPrimario
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final caminho = Path();
    final espacamentoX = size.width / (pontos.length - 1);

    for (var i = 0; i < pontos.length; i++) {
      final valorNormalizado = pontos[i].clamp(0.0, 1.0);
      final x = i * espacamentoX;
      final y = size.height - (valorNormalizado * size.height);

      if (i == 0) {
        caminho.moveTo(x, y);
      } else {
        caminho.lineTo(x, y);
      }
    }

    canvas.drawPath(caminho, pincelLinha);
  }

  @override
  bool shouldRepaint(covariant _PintorGraficoLinha oldDelegate) {
    return oldDelegate.pontos != pontos;
  }
}

class _TituloSecao extends StatelessWidget {
  final String texto;

  const _TituloSecao({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: _CoresApp.textoSecundario,
        fontSize: 13,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _CardAtivo extends StatelessWidget {
  final Color corFundoIcone;
  final Widget iconeWidget;
  final String titulo;
  final String subtitulo;
  final String valorBrlFormatado;

  const _CardAtivo({
    required this.corFundoIcone,
    required this.iconeWidget,
    required this.titulo,
    required this.subtitulo,
    required this.valorBrlFormatado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
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
              color: corFundoIcone,
              shape: BoxShape.circle,
            ),
            child: iconeWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: _CoresApp.textoPrimario,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: _CoresApp.textoSecundario,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valorBrlFormatado,
            style: const TextStyle(
              color: _CoresApp.textoPrimario,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAtividadeRecente extends StatelessWidget {
  final String descricao;
  final String valorFormatado;

  const _CardAtividadeRecente({
    required this.descricao,
    required this.valorFormatado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _CoresApp.borda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: _CoresApp.verdePositivo,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              descricao,
              style: const TextStyle(
                color: _CoresApp.textoPrimario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valorFormatado,
            style: const TextStyle(
              color: _CoresApp.verdePositivo,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoAcaoRapida extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback? aoClicar;

  const _BotaoAcaoRapida({
    required this.icone,
    required this.rotulo,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CoresApp.superficie,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _CoresApp.borda,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                color: _CoresApp.cianoPrimario,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                rotulo,
                style: const TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
          top: BorderSide(
            color: _CoresApp.borda,
            width: 1,
          ),
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
              Icon(
                icone,
                color: cor,
                size: 22,
              ),
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
