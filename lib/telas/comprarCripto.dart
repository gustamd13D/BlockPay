import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';
import 'mercadoCripto.dart';

class ComprarCripto extends StatefulWidget {
  final String iniciaisUsuario;
  final double saldoBrlDisponivel;
  final AtivoMercado ativo;
  final Future<String?> Function(double valorReais, double fracaoCripto)?
      aoConfirmarCompra;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const ComprarCripto({
    super.key,
    this.iniciaisUsuario = 'AL',
    required this.saldoBrlDisponivel,
    required this.ativo,
    this.aoConfirmarCompra,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<ComprarCripto> createState() => _ComprarCriptoState();
}

class _ComprarCriptoState extends State<ComprarCripto> {
  final TextEditingController _valorController =
      TextEditingController(text: '500,00');
  bool _processando = false;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _validarEntrada();
  }

  @override
  void didUpdateWidget(covariant ComprarCripto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saldoBrlDisponivel != widget.saldoBrlDisponivel) {
      _validarEntrada();
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  /// Converte texto no padrao brasileiro (ex: "1.500,50" ou "500,00") para double
  double _parseValorReais(String texto) {
    var limpo = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (limpo.isEmpty) return 0.0;

    if (limpo.contains(',') && limpo.contains('.')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    } else if (limpo.contains(',')) {
      limpo = limpo.replaceAll(',', '.');
    }

    return double.tryParse(limpo) ?? 0.0;
  }

  double get _valorDigitadoBrl => _parseValorReais(_valorController.text);

  double get _fracaoEstimada {
    if (_valorDigitadoBrl <= 0 || widget.ativo.precoBrl <= 0) return 0.0;
    return _valorDigitadoBrl / widget.ativo.precoBrl;
  }

  void _validarEntrada() {
    final valor = _valorDigitadoBrl;
    String? erro;

    if (_valorController.text.trim().isEmpty || valor <= 0) {
      erro = 'Informe um valor em Reais maior que R\$ 0,00.';
    } else if (valor < 1.0) {
      erro = 'O valor mínimo para compra é R\$ 1,00.';
    } else if (valor > widget.saldoBrlDisponivel) {
      erro = 'Saldo em BRL insuficiente para esta operação.';
    } else if (widget.ativo.precoBrl <= 0) {
      erro = 'Cotação indisponível no momento.';
    }

    setState(() {
      _mensagemErro = erro;
    });
  }

  Future<void> _submeterCompra() async {
    _validarEntrada();
    if (_mensagemErro != null || _processando) return;

    FocusScope.of(context).unfocus();
    setState(() => _processando = true);

    try {
      final erroServidor = await widget.aoConfirmarCompra?.call(
        double.parse(_valorDigitadoBrl.toStringAsFixed(2)),
        double.parse(_fracaoEstimada.toStringAsFixed(8)),
      );

      if (erroServidor != null && mounted) {
        setState(() {
          _mensagemErro = erroServidor;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
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

  static String _formatarFracao(double valor) {
    if (valor <= 0) return '0,00000000';
    return valor.toStringAsFixed(8).replaceAll('.', ',');
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

  Widget _construirFormularioCompra() {
    final bool temErro = _mensagemErro != null;
    final bool podeConfirmar = !temErro && !_processando;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner de saldo BRL disponivel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: CoresApp.superficieAvatar,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo BRL Disponível:',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                _formatarMoeda(widget.saldoBrlDisponivel),
                style: const TextStyle(
                  color: CoresApp.verdePositivo,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Campo de valor em Reais
        const Text(
          'Quanto deseja comprar em Reais?',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: CoresApp.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: temErro
                  ? CoresApp.vermelhoNegativo
                  : CoresApp.cianoPrimario,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Text(
                'R\$',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _valorController,
                  enabled: !_processando,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => _validarEntrada(),
                  style: const TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0,00',
                    hintStyle: TextStyle(
                      color: CoresApp.textoTerciario,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 6),
          Text(
            _mensagemErro!,
            style: const TextStyle(
              color: CoresApp.vermelhoNegativo,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Linha de cotacao atual
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cotação atual:',
              style: TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '1 ${widget.ativo.sigla} = ${_formatarMoeda(widget.ativo.precoBrl)}',
              style: const TextStyle(
                color: CoresApp.textoPrimario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Card de fracao estimada
        Container(
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
              const Text(
                'FRAÇÃO CALCULADA ESTIMADA',
                style: TextStyle(
                  color: CoresApp.cianoPrimario,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatarFracao(_fracaoEstimada),
                        style: const TextStyle(
                          color: CoresApp.textoPrimario,
                          fontSize: 28,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.ativo.sigla,
                    style: const TextStyle(
                      color: CoresApp.cianoPrimario,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: CoresApp.borda,
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taxa de rede',
                    style: TextStyle(
                      color: CoresApp.textoSecundario,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'R\$ 0,00',
                    style: TextStyle(
                      color: CoresApp.verdePositivo,
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
        const SizedBox(height: 22),

        // Botao confirmar compra
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: podeConfirmar ? _submeterCompra : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CoresApp.cianoPrimario,
              disabledBackgroundColor:
                  CoresApp.cianoPrimario.withValues(alpha: 0.35),
              foregroundColor: CoresApp.fundo,
              disabledForegroundColor: CoresApp.fundo.withValues(alpha: 0.7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _processando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: CoresApp.fundo,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Confirmar compra',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Revise os dados da operação antes de confirmar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CoresApp.textoTerciario,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
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
              titulo: 'Comprar ${widget.ativo.nome}',
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
                child: _construirFormularioCompra(),
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
          etiquetaTela: 'Comprar Cripto',
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
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _BotaoVoltar(aoClicar: widget.aoVoltar),
                        const SizedBox(width: 12),
                        Text(
                          'Comprar ${widget.ativo.nome}',
                          style: const TextStyle(
                            color: CoresApp.textoPrimario,
                            fontSize: 22,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _construirFormularioCompra(),
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