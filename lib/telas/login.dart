import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1F00E5FF);
  static const Color amareloAlerta = Color(0xFFFFD600);
  static const Color amareloSuave = Color(0x20FFD600);
  static const Color vermelhoErro = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class Login extends StatefulWidget {
  final void Function(String cpf, String pin)? entrar;
  final VoidCallback? esquecerSenha;
  final VoidCallback? criarConta;

  const Login({
    super.key,
    this.entrar,
    this.esquecerSenha,
    this.criarConta,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorCpf = TextEditingController();
  final _controladorPin = TextEditingController();
  bool _ocultarPin = true;

  @override
  void dispose() {
    _controladorCpf.dispose();
    _controladorPin.dispose();
    super.dispose();
  }

  void _processarLogin() {
    // Fecha o teclado antes de validar e enviar
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final cpfLimpo = _controladorCpf.text.replaceAll(RegExp(r'\D'), '');
      final pin = _controladorPin.text.trim();
      widget.entrar?.call(cpfLimpo, pin);
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

  String? _validarPin(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe a sua senha';
    }
    if (texto.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
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
            // Limita a largura maxima em tablets e web mantendo 100% fluido no celular
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
                            vertical: 20,
                          ),
                          child: Form(
                            key: _chaveFormulario,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(flex: 2),
                                const _CabecalhoLogo(),
                                const Spacer(flex: 2),
                                const SizedBox(height: 24),
                                const _BannerAvisoSimulacao(),
                                const SizedBox(height: 20),
                                _CampoEntrada(
                                  rotulo: 'CPF',
                                  dica: '123.456.789-00',
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
                                  rotulo: 'Senha',
                                  dica: 'Digite sua senha',
                                  iconePrefixo: Icons.lock_outline_rounded,
                                  controlador: _controladorPin,
                                  tipoTeclado: TextInputType.visiblePassword,
                                  acaoTeclado: TextInputAction.done,
                                  textoOculto: _ocultarPin,
                                  validador: _validarPin,
                                  concluirDigitacao: (_) => _processarLogin(),
                                  iconeSufixo: IconButton(
                                    onPressed: () {
                                      // Alterna a visibilidade da senha
                                      setState(() {
                                        _ocultarPin = !_ocultarPin;
                                      });
                                    },
                                    icon: Icon(
                                      _ocultarPin
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _CoresApp.textoSecundario,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _BotaoLogin(
                                  rotulo: 'Login',
                                  loginPressionar: _processarLogin,
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: widget.esquecerSenha ?? () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: _CoresApp.cianoPrimario,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      'Esqueceu a senha?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(flex: 3),
                                const SizedBox(height: 24),
                                _RodapeCriarConta(
                                  criarContaPressionar:
                                      widget.criarConta ?? () {},
                                ),
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

class _CabecalhoLogo extends StatelessWidget {
  const _CabecalhoLogo();

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
        const SizedBox(height: 14),
        const Text(
          'BlockPay',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CoresApp.textoPrimario,
            fontSize: 28,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Aprenda a investir em criptomoedas de forma e segura.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _CoresApp.textoSecundario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerAvisoSimulacao extends StatelessWidget {
  const _BannerAvisoSimulacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _CoresApp.amareloSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _CoresApp.amareloAlerta,
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.gpp_maybe_outlined,
            color: _CoresApp.amareloAlerta,
            size: 18,
          ),
          SizedBox(width: 8),
          // Expanded evita estouro de largura em telas menores
          Expanded(
            child: Text(
              'AMBIENTE DE SIMULAÇÃO: Sem dinheiro real envolvido. Tudo é educativo.',
              style: TextStyle(
                color: _CoresApp.amareloAlerta,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
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
  final bool textoOculto;
  final List<TextInputFormatter>? formatadores;
  final String? Function(String?)? validador;
  final ValueChanged<String>? concluirDigitacao;
  final Widget? iconeSufixo;

  const _CampoEntrada({
    required this.rotulo,
    required this.dica,
    required this.iconePrefixo,
    required this.controlador,
    required this.tipoTeclado,
    required this.acaoTeclado,
    this.textoOculto = false,
    this.formatadores,
    this.validador,
    this.concluirDigitacao,
    this.iconeSufixo,
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
          obscureText: textoOculto,
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
            suffixIcon: iconeSufixo,
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

class _BotaoLogin extends StatelessWidget {
  final String rotulo;
  final VoidCallback loginPressionar;

  const _BotaoLogin({
    required this.rotulo,
    required this.loginPressionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loginPressionar,
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
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RodapeCriarConta extends StatelessWidget {
  final VoidCallback criarContaPressionar;

  const _RodapeCriarConta({required this.criarContaPressionar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: criarContaPressionar,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_add_alt_1_rounded,
              color: _CoresApp.cianoPrimario,
              size: 32,
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  color: _CoresApp.textoSecundario,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: 'Ainda não possui uma conta? '),
                  TextSpan(
                    text: 'Crie uma agora',
                    style: TextStyle(
                      color: _CoresApp.cianoPrimario,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
