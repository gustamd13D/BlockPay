import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorAdminWrapper.dart';

class AtividadeAdminItem {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final DateTime dataHora;

  const AtividadeAdminItem({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.dataHora,
  });
}

class DashboardAdmin extends StatefulWidget {
  final String iniciaisUsuario;
  final int totalUsuarios;
  final int usuariosAtivos;
  final int usuariosPendentes;
  final int usuariosBloqueados;
  final double volumeTotalMovimentado;
  final List<double> pontosVolume30Dias;
  final List<AtividadeAdminItem> ultimasAtividades;

  /// Callbacks de navegacao
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const DashboardAdmin({
    super.key,
    this.iniciaisUsuario = 'AD',
    required this.totalUsuarios,
    required this.usuariosAtivos,
    required this.usuariosPendentes,
    required this.usuariosBloqueados,
    required this.volumeTotalMovimentado,
    this.pontosVolume30Dias = const [0.22, 0.48, 0.15, 0.72, 0.45, 0.90],
    this.ultimasAtividades = const [],
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
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

  Widget _construirGradeMetricas() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CardMetricaAdmin(
                rotulo: 'Total de usuários',
                valor: widget.totalUsuarios.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CardMetricaAdmin(
                rotulo: 'Usuários ativos',
                valor: widget.usuariosAtivos.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CardMetricaAdmin(
                rotulo: 'Pendentes',
                valor: widget.usuariosPendentes.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CardMetricaAdmin(
                rotulo: 'Bloqueados',
                valor: widget.usuariosBloqueados.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirCardVolume({double alturaGrafico = 56}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CoresApp.borda,
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
                'VOLUME TOTAL MOVIMENTADO',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '30d',
                style: TextStyle(
                  color: CoresApp.cianoPrimario,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatarMoeda(widget.volumeTotalMovimentado),
              style: const TextStyle(
                color: CoresApp.textoPrimario,
                fontSize: 26,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: alturaGrafico,
            width: double.infinity,
            child: CustomPaint(
              painter: _PintorGraficoVolume(pontos: widget.pontosVolume30Dias),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoUltimasAtividades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ÚLTIMAS ATIVIDADES',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.ultimasAtividades.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CoresApp.superficie,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CoresApp.borda,
                width: 1,
              ),
            ),
            child: const Text(
              'Nenhuma atividade recente registrada.',
              style: TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        else
          ...widget.ultimasAtividades.map(
            (atividade) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CardAtividadeAdmin(atividade: atividade),
            ),
          ),
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
              titulo: 'Visão geral',
              iniciaisUsuario: widget.iniciaisUsuario,
              aoClicarPerfil: widget.aoClicarPerfil,
              aoClicarSair: widget.aoClicarSair,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirGradeMetricas(),
                    const SizedBox(height: 18),
                    _construirCardVolume(alturaGrafico: 56),
                    const SizedBox(height: 22),
                    _construirSecaoUltimasAtividades(),
                  ],
                ),
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
        CabecalhoDesktopAdminWrapper(
          iniciaisUsuario: widget.iniciaisUsuario,
          indiceAtivo: 0,
          etiquetaTela: 'Admin',
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
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _construirGradeMetricas(),
                          const SizedBox(height: 20),
                          _construirCardVolume(alturaGrafico: 95),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: _construirSecaoUltimasAtividades(),
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
                : MenuInferiorAdminWrapper(
                    indiceAtivo: 0,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }
}

class _CardMetricaAdmin extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _CardMetricaAdmin({
    required this.rotulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CoresApp.borda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 22,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAtividadeAdmin extends StatelessWidget {
  final AtividadeAdminItem atividade;

  const _CardAtividadeAdmin({required this.atividade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CoresApp.borda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CoresApp.cianoSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(
              atividade.icone,
              color: CoresApp.cianoPrimario,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atividade.titulo,
                  style: const TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  atividade.subtitulo,
                  style: const TextStyle(
                    color: CoresApp.textoSecundario,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorGraficoVolume extends CustomPainter {
  final List<double> pontos;

  const _PintorGraficoVolume({required this.pontos});

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;

    final pincelLinha = Paint()
      ..color = CoresApp.cianoPrimario
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
  bool shouldRepaint(covariant _PintorGraficoVolume oldDelegate) {
    return oldDelegate.pontos != pontos;
  }
}
