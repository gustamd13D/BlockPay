import 'dart:async';
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
  static const Color verdeSuave = Color(0x2000E676);
  static const Color amareloProcessando = Color(0xFFFFD600);
  static const Color amareloSuave = Color(0x20FFD600);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class StatusBlockchain extends StatefulWidget {
  final String iniciaisUsuario;
  final String hashTransacao;
  final String? ativo;
  final double? quantidade;
  final String? destinatario;

  /// Quando true, simula a validacao em tempo real antes de confirmar o bloco
  final bool animarConfirmacao;

  /// Callbacks de navegacao
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const StatusBlockchain({
    super.key,
    this.iniciaisUsuario = 'AL',
    required this.hashTransacao,
    this.ativo,
    this.quantidade,
    this.destinatario,
    this.animarConfirmacao = false,
    this.aoClicarPerfil,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
  });

  @override
  State<StatusBlockchain> createState() => _StatusBlockchainState();
}

class _StatusBlockchainState extends State<StatusBlockchain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controladorRotacao;
  Timer? _temporizadorConfirmacao;
  late bool _confirmado;

  @override
  void initState() {
    super.initState();
    _confirmado = !widget.animarConfirmacao;

    _controladorRotacao = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.animarConfirmacao) {
      _controladorRotacao.repeat();
      _temporizadorConfirmacao = Timer(
        const Duration(milliseconds: 2800),
        () {
          if (!mounted) return;
          setState(() {
            _confirmado = true;
          });
          _controladorRotacao.stop();
        },
      );
    }
  }

  @override
  void dispose() {
    _temporizadorConfirmacao?.cancel();
    _controladorRotacao.dispose();
    super.dispose();
  }

  bool get _possuiTransacao => widget.hashTransacao.trim().isNotEmpty;

  String get _hashResumida {
    final hash = widget.hashTransacao.trim();
    if (hash.isEmpty) return 'Nenhuma transação registrada';
    if (hash.length <= 12) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }

  static String _formatarQuantidade(double valor) {
    var texto = valor.toStringAsFixed(6).replaceAll('.', ',');
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    if (texto.endsWith(',')) {
      texto = '${texto}00';
    }
    return texto;
  }

  void _copiarHash() {
    if (!_possuiTransacao) return;
    Clipboard.setData(ClipboardData(text: widget.hashTransacao));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Hash da transação copiada para a área de transferência!'),
        backgroundColor: _CoresApp.superficie,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _construirConteudo({required bool telaGrande}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (telaGrande) ...[
          Row(
            children: [
              _BotaoVoltarCircular(
                aoVoltar: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              const Text(
                'Status da blockchain',
                style: TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Container(
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
            children: [
              AnimatedScale(
                scale: _confirmado ? 1.0 : 1.08,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                child: const Icon(
                  Icons.storage_rounded,
                  color: _CoresApp.cianoPrimario,
                  size: 48,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _confirmado ? 'Status da transação' : 'Validando na rede...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _possuiTransacao
                    ? 'Acompanhe as confirmações na rede'
                    : 'Realize uma transferência para gerar uma hash',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _CoresApp.textoSecundario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (_possuiTransacao &&
                  widget.ativo != null &&
                  widget.quantidade != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _CoresApp.cianoSuave,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Envio de ${_formatarQuantidade(widget.quantidade!)} ${widget.ativo}',
                    style: const TextStyle(
                      color: _CoresApp.cianoPrimario,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              // Etapa 1: Processando bloco
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _CoresApp.amareloSuave,
                      shape: BoxShape.circle,
                    ),
                    child: _confirmado
                        ? const Icon(
                            Icons.sync_rounded,
                            color: _CoresApp.amareloProcessando,
                            size: 16,
                          )
                        : RotationTransition(
                            turns: _controladorRotacao,
                            child: const Icon(
                              Icons.sync_rounded,
                              color: _CoresApp.amareloProcessando,
                              size: 16,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _confirmado
                              ? 'Processando bloco...'
                              : 'Processando bloco...',
                          style: const TextStyle(
                            color: _CoresApp.textoPrimario,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _confirmado
                              ? 'Bloco validado pelos nós da rede'
                              : 'Aguardando confirmação dos nós',
                          style: const TextStyle(
                            color: _CoresApp.textoSecundario,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Etapa 2: Confirmado na blockchain
              AnimatedOpacity(
                opacity: (_confirmado && _possuiTransacao) ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    AnimatedScale(
                      scale: (_confirmado && _possuiTransacao) ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _CoresApp.verdeSuave,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _CoresApp.verdePositivo,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirmado na blockchain',
                            style: TextStyle(
                              color: _CoresApp.textoPrimario,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _confirmado
                                ? 'O ativo foi adicionado à carteira do destinatário'
                                : 'Aguardando conclusão da etapa anterior',
                            style: const TextStyle(
                              color: _CoresApp.textoSecundario,
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Caixa da Hash da Transacao
              InkWell(
                onTap: _possuiTransacao ? _copiarHash : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _CoresApp.superficieAvatar,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _CoresApp.borda,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HASH DA TRANSAÇÃO',
                        style: TextStyle(
                          color: _CoresApp.textoSecundario,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _hashResumida,
                              style: TextStyle(
                                color: _possuiTransacao
                                    ? _CoresApp.cianoPrimario
                                    : _CoresApp.textoSecundario,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_possuiTransacao)
                            const Icon(
                              Icons.copy_rounded,
                              color: _CoresApp.cianoPrimario,
                              size: 16,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Card educativo: O que e uma Hash?
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _CoresApp.superficieAvatar,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O que é uma Hash?',
                style: TextStyle(
                  color: _CoresApp.textoPrimario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'A hash funciona como um recibo digital único e imutável que comprova que a transação ocorreu em uma blockchain. Legal, né?',
                style: TextStyle(
                  color: _CoresApp.textoSecundario,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
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
            systemNavigationBarColor: _CoresApp.superficie,
          ),
          child: Scaffold(
            backgroundColor: _CoresApp.fundo,
            body: SafeArea(
              bottom: telaGrande,
              child: telaGrande
                  ? Column(
                      children: [
                        _CabecalhoDesktop(
                          iniciais: widget.iniciaisUsuario,
                          aoClicarPerfil: widget.aoClicarPerfil,
                          aoClicarInicio: widget.aoClicarInicio ??
                              () => Navigator.pop(context),
                          aoClicarMercado: widget.aoClicarMercado,
                          aoClicarPix: widget.aoClicarPix,
                          aoClicarHistorico: widget.aoClicarHistorico,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 28,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 560),
                                child: _construirConteudo(telaGrande: true),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          children: [
                            _BarraSuperiorMobile(
                              titulo: 'Status da blockchain',
                              iniciais: widget.iniciaisUsuario,
                              aoVoltar: () => Navigator.pop(context),
                              aoClicarPerfil: widget.aoClicarPerfil,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  28,
                                ),
                                child: _construirConteudo(telaGrande: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            bottomNavigationBar: telaGrande
                ? null
                : _BarraNavegacaoInferior(
                    indiceAtivo: 0,
                    aoClicarInicio:
                        widget.aoClicarInicio ?? () => Navigator.pop(context),
                    aoClicarMercado: widget.aoClicarMercado,
                    aoClicarPix: widget.aoClicarPix,
                    aoClicarHistorico: widget.aoClicarHistorico,
                  ),
          ),
        );
      },
    );
  }
}

class _BotaoVoltarCircular extends StatelessWidget {
  final VoidCallback aoVoltar;

  const _BotaoVoltarCircular({required this.aoVoltar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoVoltar,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: _CoresApp.superficieAvatar,
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

class _BarraSuperiorMobile extends StatelessWidget {
  final String titulo;
  final String iniciais;
  final VoidCallback aoVoltar;
  final VoidCallback? aoClicarPerfil;

  const _BarraSuperiorMobile({
    required this.titulo,
    required this.iniciais,
    required this.aoVoltar,
    this.aoClicarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _BotaoVoltarCircular(aoVoltar: aoVoltar),
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
          InkWell(
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
          ),
        ],
      ),
    );
  }
}

class _CabecalhoDesktop extends StatelessWidget {
  final String iniciais;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const _CabecalhoDesktop({
    required this.iniciais,
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
                  'Blockchain',
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
                ativo: true,
                aoClicar: aoClicarInicio,
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.show_chart_rounded,
                rotulo: 'Mercado',
                ativo: false,
                aoClicar: aoClicarMercado,
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.pix_outlined,
                rotulo: 'Pix',
                ativo: false,
                aoClicar: aoClicarPix,
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.history_rounded,
                rotulo: 'Histórico',
                ativo: false,
                aoClicar: aoClicarHistorico,
              ),
              const SizedBox(width: 20),
              InkWell(
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
