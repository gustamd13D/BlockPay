import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';

class CriarUsuario extends StatefulWidget {
  final String iniciaisAdmin;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoCancelar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;
  final void Function(
    String nome,
    String cpf,
    String email,
    String pin,
    bool isAdmin,
  )? aoCriarUsuario;

  const CriarUsuario({
    super.key,
    this.iniciaisAdmin = 'AD',
    this.aoVoltar,
    this.aoCancelar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
    this.aoCriarUsuario,
  });

  @override
  State<CriarUsuario> createState() => _CriarUsuarioState();
}

class _CriarUsuarioState extends State<CriarUsuario> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorCpf = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorPin = TextEditingController();

  String _perfilSelecionado = 'Cliente';
  bool _ocultarPin = true;

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorCpf.dispose();
    _controladorEmail.dispose();
    _controladorPin.dispose();
    super.dispose();
  }

  void _processarCriacao() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final nome = _controladorNome.text.trim();
      final cpfLimpo = _controladorCpf.text.replaceAll(RegExp(r'\D'), '');
      final email = _controladorEmail.text.trim().toLowerCase();
      final pin = _controladorPin.text.trim();
      final isAdmin = _perfilSelecionado == 'Administrador';

      widget.aoCriarUsuario?.call(nome, cpfLimpo, email, pin, isAdmin);
    }
  }

  String? _validarNome(String? valor) {
    if ((valor ?? '').trim().isEmpty) {
      return 'Informe o nome completo';
    }
    return null;
  }

  String? _validarCpf(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) {
      return 'Informe o CPF';
    }
    if (digitos.length != 11) {
      return 'CPF incompleto (11 dígitos)';
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe o e-mail';
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
      return 'Informe o PIN temporário';
    }
    if (texto.length < 6) {
      return 'O PIN deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  Widget _construirFormulario() {
    return Form(
      key: _chaveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cadastre uma nova pessoa e defina suas permissões de acesso.',
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _CampoFormularioUsuario(
            rotulo: 'Nome completo',
            dica: 'Digite o nome',
            controlador: _controladorNome,
            tipoTeclado: TextInputType.name,
            acaoTeclado: TextInputAction.next,
            validador: _validarNome,
          ),
          const SizedBox(height: 16),
          _CampoFormularioUsuario(
            rotulo: 'CPF',
            dica: '000.000.000-00',
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
          _CampoFormularioUsuario(
            rotulo: 'E-mail',
            dica: 'usuario@email.com',
            controlador: _controladorEmail,
            tipoTeclado: TextInputType.emailAddress,
            acaoTeclado: TextInputAction.next,
            validador: _validarEmail,
          ),
          const SizedBox(height: 16),
          _CampoFormularioUsuario(
            rotulo: 'PIN temporário',
            dica: 'Mínimo de 6 caracteres',
            controlador: _controladorPin,
            tipoTeclado: TextInputType.visiblePassword,
            acaoTeclado: TextInputAction.done,
            textoOculto: _ocultarPin,
            validador: _validarPin,
            sufixo: IconButton(
              onPressed: () {
                setState(() {
                  _ocultarPin = !_ocultarPin;
                });
              },
              icon: Icon(
                _ocultarPin
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: CoresApp.textoSecundario,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Perfil de acesso',
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _perfilSelecionado,
            dropdownColor: CoresApp.superficie,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: CoresApp.textoSecundario,
            ),
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CoresApp.borda,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CoresApp.cianoPrimario,
                  width: 1.5,
                ),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Cliente',
                child: Text('Cliente'),
              ),
              DropdownMenuItem(
                value: 'Administrador',
                child: Text('Administrador'),
              ),
            ],
            onChanged: (novoValor) {
              if (novoValor != null) {
                setState(() {
                  _perfilSelecionado = novoValor;
                });
              }
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1500E5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x3300E5FF),
                width: 1,
              ),
            ),
            child: const Text(
              'O usuário receberá instruções para ativar a conta e trocar o PIN no primeiro acesso.',
              style: TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processarCriacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoresApp.cianoPrimario,
                foregroundColor: CoresApp.fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Criar usuário',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.aoCancelar ??
                  widget.aoVoltar ??
                  () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: CoresApp.superficie,
                foregroundColor: CoresApp.textoPrimario,
                side: const BorderSide(
                  color: CoresApp.borda,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 15,
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

  Widget _construirLayoutMobile() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            CabecalhoMobileWrapper(
              titulo: 'Novo usuário',
              iniciaisUsuario: widget.iniciaisAdmin,
              mostrarBotaoVoltar: true,
              estiloAdmin: true,
              aoVoltar: widget.aoVoltar,
              aoClicarPerfil: widget.aoClicarPerfil,
              aoClicarSair: widget.aoClicarSair,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: _construirFormulario(),
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
          iniciaisUsuario: widget.iniciaisAdmin,
          indiceAtivo: 1,
          etiquetaTela: 'Usuários',
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
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: widget.aoVoltar ??
                              () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: CoresApp.cianoPrimario,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Novo usuário',
                          style: TextStyle(
                            color: CoresApp.textoPrimario,
                            fontSize: 22,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _construirFormulario(),
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
            systemNavigationBarColor: CoresApp.fundo,
          ),
          child: Scaffold(
            backgroundColor: CoresApp.fundo,
            body: SafeArea(
              child: telaGrande
                  ? _construirLayoutDesktop()
                  : _construirLayoutMobile(),
            ),
          ),
        );
      },
    );
  }
}

class _CampoFormularioUsuario extends StatelessWidget {
  final String rotulo;
  final String dica;
  final TextEditingController controlador;
  final TextInputType tipoTeclado;
  final TextInputAction acaoTeclado;
  final bool textoOculto;
  final List<TextInputFormatter>? formatadores;
  final String? Function(String?)? validador;
  final Widget? sufixo;

  const _CampoFormularioUsuario({
    required this.rotulo,
    required this.dica,
    required this.controlador,
    required this.tipoTeclado,
    required this.acaoTeclado,
    this.textoOculto = false,
    this.formatadores,
    this.validador,
    this.sufixo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: CoresApp.textoSecundario,
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
          style: const TextStyle(
            color: CoresApp.textoPrimario,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          cursorColor: CoresApp.cianoPrimario,
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: const TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: CoresApp.superficie,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            suffixIcon: sufixo,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: CoresApp.borda,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: CoresApp.cianoPrimario,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: CoresApp.vermelhoNegativo,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: CoresApp.vermelhoNegativo,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
