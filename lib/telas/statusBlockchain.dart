import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';

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
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const StatusBlockchain({
    super.key,
    this.iniciaisUsuario = 'AL',
    required this.hashTransacao,
    this.ativo,
    this.quantidade,
    this.destinatario,
    this.animarConfirmacao = false,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
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
        backgroundColor: CoresApp.superficie,
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
                  color: CoresApp.textoPrimario,
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
            color: CoresApp.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CoresApp.borda,
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
                  color: CoresApp.cianoPrimario,
                  size: 48,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _confirmado ? 'Status da transação' : 'Validando na rede...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CoresApp.textoPrimario,
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
                  color: CoresApp.textoSecundario,
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
                    color: CoresApp.cianoSuave,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Envio de ${_formatarQuantidade(widget.quantidade!)} ${widget.ativo}',
                    style: const TextStyle(
                      color: CoresApp.cianoPrimario,
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
                      color: CoresApp.amareloSuave,
                      shape: BoxShape.circle,
                    ),
                    child: _confirmado
                        ? const Icon(
                            Icons.sync_rounded,
                            color: CoresApp.amareloBitcoin,
                            size: 16,
                          )
                        : RotationTransition(
                            turns: _controladorRotacao,
                            child: const Icon(
                              Icons.sync_rounded,
                              color: CoresApp.amareloBitcoin,
                              size: 16,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Processando bloco...',
                          style: TextStyle(
                            color: CoresApp.textoPrimario,
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
                            color: CoresApp.textoSecundario,
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
                          color: CoresApp.verdeSuave,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: CoresApp.verdePositivo,
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
                              color: CoresApp.textoPrimario,
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
                              color: CoresApp.textoSecundario,
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
                    color: CoresApp.superficieAvatar,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CoresApp.borda,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HASH DA TRANSAÇÃO',
                        style: TextStyle(
                          color: CoresApp.textoSecundario,
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
                                    ? CoresApp.cianoPrimario
                                    : CoresApp.textoSecundario,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_possuiTransacao)
                            const Icon(
                              Icons.copy_rounded,
                              color: CoresApp.cianoPrimario,
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
            color: CoresApp.superficieAvatar,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O que é uma Hash?',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'A hash funciona como um recibo digital único e imutável que comprova que a transação ocorreu em uma blockchain. Legal, né?',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
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
            systemNavigationBarColor: CoresApp.superficie,
          ),
          child: Scaffold(
            backgroundColor: CoresApp.fundo,
            body: SafeArea(
              bottom: telaGrande,
              child: telaGrande
                  ? Column(
                      children: [
                        CabecalhoDesktopWrapper(
                          iniciaisUsuario: widget.iniciaisUsuario,
                          indiceAtivo: 0,
                          etiquetaTela: 'Blockchain',
                          aoSelecionarAba: widget.aoSelecionarAba,
                          aoClicarPerfil: widget.aoClicarPerfil,
                          aoClicarSair: widget.aoClicarSair,
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
                            CabecalhoMobileWrapper(
                              titulo: 'Status da blockchain',
                              iniciaisUsuario: widget.iniciaisUsuario,
                              mostrarBotaoVoltar: true,
                              aoVoltar: () => Navigator.pop(context),
                              aoClicarPerfil: widget.aoClicarPerfil,
                              aoClicarSair: widget.aoClicarSair,
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
                : MenuInferiorWrapper(
                    indiceAtivo: 0,
                    aoSelecionarAba: widget.aoSelecionarAba,
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
          color: CoresApp.superficieAvatar,
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