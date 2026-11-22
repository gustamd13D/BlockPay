import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mercadoCripto.dart';

abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color superficieDestaque = Color(0xFF21293A);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1500E5FF);
  static const Color verdePositivo = Color(0xFF00E676);
  static const Color vermelhoNegativo = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
  static const Color textoApagado = Color(0xFF546E7A);
}

class ComprarCripto extends StatefulWidget {
  final String iniciaisUsuario;
  final double saldoBrlDisponivel;
  final AtivoMercado ativo;
  final Future<String?> Function(double valorReais, double fracaoCripto)?
      aoConfirmarCompra;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const ComprarCripto({
    super.key,
    this.iniciaisUsuario = 'AL',
    required this.saldoBrlDisponivel,
    required this.ativo,
    this.aoConfirmarCompra,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
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
            color: _CoresApp.superficieDestaque,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo BRL Disponível:',
                style: TextStyle(
                  color: _CoresApp.textoSecundario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                _formatarMoeda(widget.saldoBrlDisponivel),
                style: const TextStyle(
                  color: _CoresApp.verdePositivo,
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
            color: _CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _CoresApp.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: temErro
                  ? _CoresApp.vermelhoNegativo
                  : _CoresApp.cianoPrimario,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Text(
                'R\$',
                style: TextStyle(
                  color: _CoresApp.textoPrimario,
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
                    color: _CoresApp.textoPrimario,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0,00',
                    hintStyle: TextStyle(
                      color: _CoresApp.textoApagado,
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
              color: _CoresApp.vermelhoNegativo,
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
                color: _CoresApp.textoSecundario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '1 ${widget.ativo.sigla} = ${_formatarMoeda(widget.ativo.precoBrl)}',
              style: const TextStyle(
                color: _CoresApp.textoPrimario,
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
                'FRAÇÃO CALCULADA ESTIMADA',
                style: TextStyle(
                  color: _CoresApp.cianoPrimario,
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
                          color: _CoresApp.textoPrimario,
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
                      color: _CoresApp.cianoPrimario,
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
                  color: _CoresApp.borda,
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taxa de rede',
                    style: TextStyle(
                      color: _CoresApp.textoSecundario,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'R\$ 0,00',
                    style: TextStyle(
                      color: _CoresApp.verdePositivo,
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
              backgroundColor: _CoresApp.cianoPrimario,
              disabledBackgroundColor:
                  _CoresApp.cianoPrimario.withValues(alpha: 0.35),
              foregroundColor: _CoresApp.fundo,
              disabledForegroundColor: _CoresApp.fundo.withValues(alpha: 0.7),
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
                      color: _CoresApp.fundo,
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
            color: _CoresApp.textoApagado,
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
            _CabecalhoMobile(
              titulo: 'Comprar ${widget.ativo.nome}',
              iniciais: widget.iniciaisUsuario,
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
                            color: _CoresApp.textoPrimario,
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
