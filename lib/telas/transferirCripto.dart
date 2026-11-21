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
  static const Color amareloBitcoin = Color(0xFFFFD600);
  static const Color amareloSuave = Color(0x15FFD600);
  static const Color vermelhoErro = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
  static const Color textoTerciario = Color(0xFF546E7A);
}

class TransferirCripto extends StatefulWidget {
  final String iniciaisUsuario;
  final double saldoBtc;
  final double saldoEth;
  final String? emailRemetente;
  final String? cpfRemetente;

  /// Callback assincrono executado ao confirmar a transferencia.
  /// Deve retornar null se concluir com sucesso ou uma mensagem de erro
  /// caso o destinatario nao exista no banco.
  final Future<String?> Function(
    String destinatario,
    String ativo,
    double quantidade,
  )? aoTransferir;

  /// Callbacks de navegacao
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const TransferirCripto({
    super.key,
    this.iniciaisUsuario = 'AL',
    this.saldoBtc = 0.034,
    this.saldoEth = 0.25,
    this.emailRemetente,
    this.cpfRemetente,
    this.aoTransferir,
    this.aoClicarPerfil,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
  });

  @override
  State<TransferirCripto> createState() => _TransferirCriptoState();
}

class _TransferirCriptoState extends State<TransferirCripto> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorDestinatario = TextEditingController();
  final _controladorQuantidade = TextEditingController();

  String _ativoSelecionado = 'BTC';
  String? _erroDestinatario;
  bool _verificandoEnvio = false;

  @override
  void dispose() {
    _controladorDestinatario.dispose();
    _controladorQuantidade.dispose();
    super.dispose();
  }

  double get _saldoDisponivelAtual =>
      _ativoSelecionado == 'BTC' ? widget.saldoBtc : widget.saldoEth;

  static String _formatarQuantidade(double valor) {
    var texto = valor.toStringAsFixed(6).replaceAll('.', ',');
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    if (texto.endsWith(',')) {
      texto = '${texto}00';
    }
    return texto;
  }

  double? _converterQuantidade(String texto) {
    final normalizado = texto.trim().replaceAll(',', '.');
    return double.tryParse(normalizado);
  }

  String? _validarDestinatario(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe o e-mail ou CPF do usuário cadastrado';
    }

    final regexEmail = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    final apenasDigitos = texto.replaceAll(RegExp(r'\D'), '');
    final regexCarteira = RegExp(r'^(0x)?[a-zA-Z0-9]{12,64}$');

    if (!regexEmail.hasMatch(texto) &&
        apenasDigitos.length != 11 &&
        !regexCarteira.hasMatch(texto)) {
      return 'Informe um e-mail, CPF ou endereço válido';
    }

    final emailProprio = (widget.emailRemetente ?? '').trim().toLowerCase();
    final cpfProprio =
        (widget.cpfRemetente ?? '').replaceAll(RegExp(r'\D'), '');

    if ((emailProprio.isNotEmpty && texto.toLowerCase() == emailProprio) ||
        (cpfProprio.isNotEmpty &&
            apenasDigitos.length == 11 &&
            apenasDigitos == cpfProprio)) {
      return 'Você não pode transferir para sua própria conta';
    }

    return null;
  }

  String? _validarQuantidade(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe a quantidade para transferir';
    }

    final quantidade = _converterQuantidade(texto);
    if (quantidade == null || quantidade <= 0) {
      return 'Informe um valor maior que zero';
    }

    if (quantidade > _saldoDisponivelAtual + 1e-9) {
      return 'Saldo insuficiente de $_ativoSelecionado';
    }

    return null;
  }

  Future<void> _processarTransferencia() async {
    if (_verificandoEnvio) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _erroDestinatario = null;
    });

    if (!(_chaveFormulario.currentState?.validate() ?? false)) {
      return;
    }

    final destinatario = _controladorDestinatario.text.trim();
    final quantidade = _converterQuantidade(_controladorQuantidade.text)!;

    if (widget.aoTransferir == null) return;

    setState(() {
      _verificandoEnvio = true;
    });

    try {
      final erroRetornado = await widget.aoTransferir!(
        destinatario,
        _ativoSelecionado,
        quantidade,
      );

      if (!mounted) return;
      if (erroRetornado != null && erroRetornado.isNotEmpty) {
        setState(() {
          _erroDestinatario = erroRetornado;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _verificandoEnvio = false;
        });
      }
    }
  }

  Widget _construirIconeAtivo(String sigla) {
    if (sigla == 'BTC') {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _CoresApp.amareloSuave,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.currency_bitcoin_rounded,
          color: _CoresApp.amareloBitcoin,
          size: 16,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _CoresApp.cianoSuave,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.toll_rounded,
        color: _CoresApp.cianoPrimario,
        size: 16,
      ),
    );
  }

  Widget _construirFormulario({required bool telaGrande}) {
    return Form(
      key: _chaveFormulario,
      child: Column(
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
                  'Transferir cripto',
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
          const Text(
            'Destinatário (e-mail ou endereço)',
            style: TextStyle(
              color: _CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controladorDestinatario,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validarDestinatario,
            onChanged: (_) {
              if (_erroDestinatario != null) {
                setState(() {
                  _erroDestinatario = null;
                });
              }
            },
            style: const TextStyle(
              color: _CoresApp.textoPrimario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            cursorColor: _CoresApp.cianoPrimario,
            decoration: InputDecoration(
              hintText: 'usuario@exemplo.com',
              errorText: _erroDestinatario,
              errorMaxLines: 2,
              hintStyle: const TextStyle(
                color: _CoresApp.textoSecundario,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: _CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: _CoresApp.textoSecundario,
                size: 20,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.borda,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.cianoPrimario,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.vermelhoErro,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.vermelhoErro,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Selecione o ativo',
            style: TextStyle(
              color: _CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _ativoSelecionado,
            dropdownColor: _CoresApp.superficie,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _CoresApp.textoSecundario,
              size: 22,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.borda,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.cianoPrimario,
                  width: 1.5,
                ),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'BTC',
                child: Row(
                  children: [
                    _construirIconeAtivo('BTC'),
                    const SizedBox(width: 10),
                    const Text(
                      'Bitcoin (BTC)',
                      style: TextStyle(
                        color: _CoresApp.textoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'ETH',
                child: Row(
                  children: [
                    _construirIconeAtivo('ETH'),
                    const SizedBox(width: 10),
                    const Text(
                      'Ethereum (ETH)',
                      style: TextStyle(
                        color: _CoresApp.textoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: _verificandoEnvio
                ? null
                : (novoAtivo) {
                    if (novoAtivo == null) return;
                    setState(() {
                      _ativoSelecionado = novoAtivo;
                    });
                  },
          ),
          const SizedBox(height: 18),
          const Text(
            'Quantidade',
            style: TextStyle(
              color: _CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controladorQuantidade,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: _validarQuantidade,
            onFieldSubmitted: (_) => _processarTransferencia(),
            style: const TextStyle(
              color: _CoresApp.textoPrimario,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
            cursorColor: _CoresApp.cianoPrimario,
            decoration: InputDecoration(
              hintText: '0.001',
              hintStyle: const TextStyle(
                color: _CoresApp.textoSecundario,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: _CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _ativoSelecionado,
                      style: const TextStyle(
                        color: _CoresApp.cianoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.borda,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.cianoPrimario,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.vermelhoErro,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.vermelhoErro,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponível: ${_formatarQuantidade(_saldoDisponivelAtual)} $_ativoSelecionado',
                style: const TextStyle(
                  color: _CoresApp.textoTerciario,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              InkWell(
                onTap: _verificandoEnvio
                    ? null
                    : () {
                        _controladorQuantidade.text =
                            _saldoDisponivelAtual.toString();
                      },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Usar máximo',
                    style: TextStyle(
                      color: _CoresApp.cianoPrimario,
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verificandoEnvio ? null : _processarTransferencia,
              style: ElevatedButton.styleFrom(
                backgroundColor: _CoresApp.cianoPrimario,
                disabledBackgroundColor:
                    _CoresApp.cianoPrimario.withOpacity(0.5),
                foregroundColor: _CoresApp.fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _verificandoEnvio
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: _CoresApp.fundo,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Verificando destinatário...',
                          style: TextStyle(
                            color: _CoresApp.fundo,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuar transferência',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.send_outlined,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
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
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: _CoresApp.superficie,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _CoresApp.borda,
                                      width: 1,
                                    ),
                                  ),
                                  child: _construirFormulario(
                                    telaGrande: true,
                                  ),
                                ),
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
                              titulo: 'Transferir cripto',
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
                                child: _construirFormulario(
                                  telaGrande: false,
                                ),
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
                  'Transferir Cripto',
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
