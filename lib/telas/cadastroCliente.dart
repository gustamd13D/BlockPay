import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1F00E5FF);
  static const Color cianoBannerFundo = Color(0x1200E5FF);
  static const Color cianoBannerBorda = Color(0x3300E5FF);
  static const Color vermelhoErro = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class CadastroCliente extends StatefulWidget {
  final void Function(String nome, String cpf, String email, String pin)?
      cadastrar;

  const CadastroCliente({
    super.key,
    this.cadastrar,
  });

  @override
  State<CadastroCliente> createState() => _CadastroClienteState();
}

class _CadastroClienteState extends State<CadastroCliente> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorCpf = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorPin = TextEditingController();
  final _controladorConfirmarPin = TextEditingController();

  bool _ocultarPin = true;
  bool _ocultarConfirmarPin = true;

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorCpf.dispose();
    _controladorEmail.dispose();
    _controladorPin.dispose();
    _controladorConfirmarPin.dispose();
    super.dispose();
  }

  void _processarCadastro() {
    // Fecha o teclado antes de validar e enviar
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final nome = _controladorNome.text.trim();
      final cpfLimpo = _controladorCpf.text.replaceAll(RegExp(r'\D'), '');
      final email = _controladorEmail.text.trim().toLowerCase();
      final pin = _controladorPin.text.trim();

      widget.cadastrar?.call(nome, cpfLimpo, email, pin);
    }
  }

  String? _validarNome(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe o seu nome completo';
    }
    final partes = texto.split(RegExp(r'\s+'));
    if (partes.length < 2 || partes.any((parte) => parte.length < 2)) {
      return 'Digite nome e sobrenome';
    }
    return null;
  }

  String? _validarCpf(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) {
      return 'Informe o seu CPF';
    }
    if (digitos.length != 11) {
      return 'CPF incompleto (11 dígitos)';
    }
    if (!_cpfValido(digitos)) {
      return 'CPF inválido';
    }
    return null;
  }

  // Validacao matematica dos digitos verificadores do CPF
  bool _cpfValido(String cpf) {
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return false;
    }

    var soma = 0;
    for (var i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    var primeiroDigito = (soma * 10) % 11;
    if (primeiroDigito == 10) primeiroDigito = 0;
    if (primeiroDigito != int.parse(cpf[9])) return false;

    soma = 0;
    for (var i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    var segundoDigito = (soma * 10) % 11;
    if (segundoDigito == 10) segundoDigito = 0;
    return segundoDigito == int.parse(cpf[10]);
  }

  String? _validarEmail(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe o seu e-mail';
    }
    final regexEmail = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regexEmail.hasMatch(texto)) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  String? _validarPin(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Crie uma senha de acesso';
    }
    if (texto.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(texto)) {
      return 'Inclua pelo menos uma letra maiúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(texto)) {
      return 'Inclua pelo menos um número';
    }
    if (!RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:"\\|,.<>\/?]')
        .hasMatch(texto)) {
      return 'Inclua pelo menos um caractere especial';
    }
    return null;
  }

  String? _validarConfirmacaoPin(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Confirme a sua senha';
    }
    if (texto != _controladorPin.text.trim()) {
      return 'As senhas digitadas não coincidem';
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _chaveFormulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const _CabecalhoLogo(),
                      const SizedBox(height: 28),
                      const Text(
                        'Cadastro',
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
                        'Preencha seus dados para criar sua conta e começar a usar o BlockPay.',
                        style: TextStyle(
                          color: _CoresApp.textoSecundario,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _CampoEntrada(
                        rotulo: 'Nome Completo',
                        dica: 'digite aqui seu nome',
                        iconePrefixo: Icons.person_outline_rounded,
                        controlador: _controladorNome,
                        tipoTeclado: TextInputType.name,
                        capitalizacao: TextCapitalization.words,
                        acaoTeclado: TextInputAction.next,
                        validador: _validarNome,
                      ),
                      const SizedBox(height: 16),
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
                        rotulo: 'E-mail',
                        dica: 'voce@exemplo.com',
                        iconePrefixo: Icons.alternate_email_rounded,
                        controlador: _controladorEmail,
                        tipoTeclado: TextInputType.emailAddress,
                        acaoTeclado: TextInputAction.next,
                        validador: _validarEmail,
                      ),
                      const SizedBox(height: 16),
                      _CampoEntrada(
                        rotulo: 'Senha de acesso',
                        dica: 'Mínimo 8 caracteres',
                        iconePrefixo: Icons.lock_outline_rounded,
                        controlador: _controladorPin,
                        tipoTeclado: TextInputType.visiblePassword,
                        acaoTeclado: TextInputAction.next,
                        textoOculto: _ocultarPin,
                        validador: _validarPin,
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
                      const SizedBox(height: 16),
                      _CampoEntrada(
                        rotulo: 'Confirmação de senha',
                        dica: 'Digite a senha novamente',
                        iconePrefixo: Icons.lock_outline_rounded,
                        controlador: _controladorConfirmarPin,
                        tipoTeclado: TextInputType.visiblePassword,
                        acaoTeclado: TextInputAction.done,
                        textoOculto: _ocultarConfirmarPin,
                        validador: _validarConfirmacaoPin,
                        concluirDigitacao: (_) => _processarCadastro(),
                        iconeSufixo: IconButton(
                          onPressed: () {
                            // Alterna a visibilidade da confirmacao da senha
                            setState(() {
                              _ocultarConfirmarPin = !_ocultarConfirmarPin;
                            });
                          },
                          icon: Icon(
                            _ocultarConfirmarPin
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _CoresApp.textoSecundario,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'A senha deve conter pelo menos uma letra maiúscula, um número e um caractere especial.',
                        style: TextStyle(
                          color: _CoresApp.textoSecundario,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _AvisoSeguranca(),
                      const SizedBox(height: 20),
                      _BotaoCriarConta(
                        rotulo: 'Criar conta',
                        criarContaPressionar: _processarCadastro,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
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
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Abra sua conta digital e comece a investir com segurança.',
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

class _CampoEntrada extends StatelessWidget {
  final String rotulo;
  final String dica;
  final IconData iconePrefixo;
  final TextEditingController controlador;
  final TextInputType tipoTeclado;
  final TextCapitalization capitalizacao;
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
    this.capitalizacao = TextCapitalization.none,
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
          textCapitalization: capitalizacao,
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

class _AvisoSeguranca extends StatelessWidget {
  const _AvisoSeguranca();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            size: 20,
          ),
          SizedBox(width: 12),
          // Expanded evita estouro de largura em telas menores
          Expanded(
            child: Text(
              'Sua conta será protegida por senha forte e autenticação segura.',
              style: TextStyle(
                color: _CoresApp.textoSecundario,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoCriarConta extends StatelessWidget {
  final String rotulo;
  final VoidCallback criarContaPressionar;

  const _BotaoCriarConta({
    required this.rotulo,
    required this.criarContaPressionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: criarContaPressionar,
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
