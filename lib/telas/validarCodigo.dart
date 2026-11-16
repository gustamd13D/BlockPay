import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1F00E5FF);
  static const Color cianoBannerFundo = Color(0x1100E5FF);
  static const Color cianoBannerBorda = Color(0x3300E5FF);
  static const Color vermelhoErro = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class ValidarCodigo extends StatefulWidget {
  final String cpf;
  final String email;
  final void Function(String codigo)? validarCodigo;
  final VoidCallback? reenviarCodigo;

  const ValidarCodigo({
    super.key,
    required this.cpf,
    required this.email,
    this.validarCodigo,
    this.reenviarCodigo,
  });

  @override
  State<ValidarCodigo> createState() => _ValidarCodigoState();
}

class _ValidarCodigoState extends State<ValidarCodigo> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorCodigo = TextEditingController();

  Timer? _temporizador;
  int _segundosRestantes = 0;

  @override
  void dispose() {
    _temporizador?.cancel();
    _controladorCodigo.dispose();
    super.dispose();
  }

  void _iniciarContagemReenvio() {
    _temporizador?.cancel();
    setState(() {
      _segundosRestantes = 30;
    });

    _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes <= 1) {
        timer.cancel();
        setState(() {
          _segundosRestantes = 0;
        });
      } else {
        setState(() {
          _segundosRestantes--;
        });
      }
    });
  }

  void _processarValidacao() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final codigo = _controladorCodigo.text.trim();
      widget.validarCodigo?.call(codigo);
    }
  }

  void _processarReenvio() {
    if (_segundosRestantes > 0) return;
    _iniciarContagemReenvio();
    widget.reenviarCodigo?.call();
  }

  String? _validarCampoCodigo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Digite o código enviado ao seu e-mail';
    }
    if (texto.length != 6) {
      return 'O código deve ter 6 dígitos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _CoresApp.fundo,
      ),
      child: Scaffold(
        backgroundColor: _CoresApp.fundo,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Form(
                            key: _chaveFormulario,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BarraSuperior(
                                  titulo: 'Validar código',
                                  aoVoltar: () => Navigator.pop(context),
                                ),
                                const SizedBox(height: 24),
                                const _CabecalhoCodigo(),
                                const SizedBox(height: 28),
                                const Text(
                                  'Código de verificação',
                                  style: TextStyle(
                                    color: _CoresApp.textoSecundario,
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _controladorCodigo,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  validator: _validarCampoCodigo,
                                  onFieldSubmitted: (_) =>
                                      _processarValidacao(),
                                  style: const TextStyle(
                                    color: _CoresApp.textoPrimario,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                  ),
                                  cursorColor: _CoresApp.cianoPrimario,
                                  decoration: InputDecoration(
                                    hintText: 'Digite o código recebido',
                                    hintStyle: const TextStyle(
                                      color: _CoresApp.textoSecundario,
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0,
                                    ),
                                    filled: true,
                                    fillColor: _CoresApp.superficie,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 15,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
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
                                const SizedBox(height: 20),
                                const _BannerAlertaCodigo(),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 54,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _processarValidacao,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _CoresApp.cianoPrimario,
                                      foregroundColor: _CoresApp.fundo,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Validar código',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Confira também a caixa de spam ou lixo eletrônico.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _CoresApp.textoSecundario,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: TextButton(
                                    onPressed: _segundosRestantes == 0
                                        ? _processarReenvio
                                        : null,
                                    style: TextButton.styleFrom(
                                      foregroundColor: _CoresApp.cianoPrimario,
                                      disabledForegroundColor:
                                          _CoresApp.textoSecundario,
                                    ),
                                    child: Text(
                                      _segundosRestantes == 0
                                          ? 'Não recebeu? Reenviar código'
                                          : 'Aguarde ${_segundosRestantes}s para reenviar',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 24),
                                const _RodapeEducativo(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  final String titulo;
  final VoidCallback aoVoltar;

  const _BarraSuperior({
    required this.titulo,
    required this.aoVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: aoVoltar,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
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
        ),
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
      ],
    );
  }
}

class _CabecalhoCodigo extends StatelessWidget {
  const _CabecalhoCodigo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _CoresApp.cianoSuave,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _CoresApp.cianoPrimario,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.storage_rounded,
            color: _CoresApp.cianoPrimario,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'BlockPay',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CoresApp.textoPrimario,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Confira seu e-mail',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CoresApp.textoPrimario,
            fontSize: 24,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Digite o código enviado ao e-mail cadastrado para continuar a recuperação da sua senha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CoresApp.textoSecundario,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BannerAlertaCodigo extends StatelessWidget {
  const _BannerAlertaCodigo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _CoresApp.cianoBannerFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _CoresApp.cianoBannerBorda,
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: _CoresApp.cianoPrimario,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'O código é pessoal. Não compartilhe com ninguém, nem com quem se passar pelo BlockPay.',
              style: TextStyle(
                color: _CoresApp.textoSecundario,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RodapeEducativo extends StatelessWidget {
  const _RodapeEducativo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Seu próximo investimento é em conhecimento.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CoresApp.textoSecundario,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ambiente educativo • Sem dinheiro real',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CoresApp.textoSecundario,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
