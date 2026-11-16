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

class RecuperarAcesso extends StatefulWidget {
  final void Function(String cpf, String email)? enviarSolicitacao;

  const RecuperarAcesso({
    super.key,
    this.enviarSolicitacao,
  });

  @override
  State<RecuperarAcesso> createState() => _RecuperarAcessoState();
}

class _RecuperarAcessoState extends State<RecuperarAcesso> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorCpf = TextEditingController();
  final _controladorEmail = TextEditingController();

  @override
  void dispose() {
    _controladorCpf.dispose();
    _controladorEmail.dispose();
    super.dispose();
  }

  void _processarEnvio() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final cpfLimpo = _controladorCpf.text.replaceAll(RegExp(r'\D'), '');
      final email = _controladorEmail.text.trim().toLowerCase();
      widget.enviarSolicitacao?.call(cpfLimpo, email);
    }
  }

  String? _validarCpf(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) {
      return 'Informe o seu CPF';
    }
    if (digitos.length != 11) {
      return 'CPF incompleto (11 dígitos)';
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe o e-mail cadastrado';
    }
    final regexEmail = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regexEmail.hasMatch(texto)) {
      return 'Informe um e-mail válido';
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
                                  titulo: 'Recuperar acesso',
                                  aoVoltar: () => Navigator.pop(context),
                                ),
                                const SizedBox(height: 24),
                                const _CabecalhoRecuperacao(),
                                const SizedBox(height: 28),
                                _CampoEntrada(
                                  rotulo: 'CPF',
                                  dica: '000.000.000-00',
                                  iconePrefixo: Icons.person_outline_rounded,
                                  controlador: _controladorCpf,
                                  tipoTeclado: TextInputType.number,
                                  acaoTeclado: TextInputAction.next,
                                  formatadores: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                    _FormatadorCpf(),
                                  ],
                                  validador: _validarCpf,
                                ),
                                const SizedBox(height: 16),
                                _CampoEntrada(
                                  rotulo: 'E-mail cadastrado',
                                  dica: 'voce@exemplo.com',
                                  iconePrefixo: Icons.alternate_email_rounded,
                                  controlador: _controladorEmail,
                                  tipoTeclado: TextInputType.emailAddress,
                                  acaoTeclado: TextInputAction.done,
                                  validador: _validarEmail,
                                  concluirDigitacao: (_) => _processarEnvio(),
                                ),
                                const SizedBox(height: 20),
                                const _BannerInformativo(
                                  texto:
                                      'Se os dados estiverem cadastrados, enviaremos ao seu e-mail um código para redefinir sua senha.',
                                ),
                                const SizedBox(height: 24),
                                _BotaoPrimario(
                                  rotulo: 'Enviar',
                                  icone: Icons.arrow_forward_rounded,
                                  aoPressionar: _processarEnvio,
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _CoresApp.cianoPrimario,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      'Lembrou a senha? Voltar ao login',
                                      style: TextStyle(
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

class _CabecalhoRecuperacao extends StatelessWidget {
  const _CabecalhoRecuperacao();

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
          'Vamos recuperar seu acesso',
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
          'Informe o CPF e o e-mail cadastrados para voltar à sua jornada no BlockPay.',
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

class _CampoEntrada extends StatelessWidget {
  final String rotulo;
  final String dica;
  final IconData iconePrefixo;
  final TextEditingController controlador;
  final TextInputType tipoTeclado;
  final TextInputAction acaoTeclado;
  final List<TextInputFormatter>? formatadores;
  final String? Function(String?)? validador;
  final ValueChanged<String>? concluirDigitacao;

  const _CampoEntrada({
    required this.rotulo,
    required this.dica,
    required this.iconePrefixo,
    required this.controlador,
    required this.tipoTeclado,
    required this.acaoTeclado,
    this.formatadores,
    this.validador,
    this.concluirDigitacao,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: _CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          keyboardType: tipoTeclado,
          textInputAction: acaoTeclado,
          inputFormatters: formatadores,
          validator: validador,
          onFieldSubmitted: concluirDigitacao,
          style: const TextStyle(
            color: _CoresApp.textoPrimario,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
          cursorColor: _CoresApp.cianoPrimario,
          decoration: InputDecoration(
            hintText: dica,
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
            prefixIcon: Icon(
              iconePrefixo,
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
      ],
    );
  }
}

class _BannerInformativo extends StatelessWidget {
  final String texto;

  const _BannerInformativo({required this.texto});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: _CoresApp.cianoPrimario,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
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

class _BotaoPrimario extends StatelessWidget {
  final String rotulo;
  final IconData? icone;
  final VoidCallback aoPressionar;

  const _BotaoPrimario({
    required this.rotulo,
    required this.aoPressionar,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: aoPressionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: _CoresApp.cianoPrimario,
          foregroundColor: _CoresApp.fundo,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            if (icone != null) ...[
              const SizedBox(width: 8),
              Icon(icone, size: 20),
            ],
          ],
        ),
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

/// Mascara automatica para formatar o CPF no padrao 000.000.000-00
class _FormatadorCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue valorAntigo,
    TextEditingValue valorNovo,
  ) {
    final digitos = valorNovo.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digitos.length && i < 11; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      } else if (i == 9) {
        buffer.write('-');
      }
      buffer.write(digitos[i]);
    }

    final textoFormatado = buffer.toString();
    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}
