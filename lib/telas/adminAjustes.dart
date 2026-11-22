import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorAdminWrapper.dart';

class AdminAjustes extends StatefulWidget {
  final String iniciaisUsuario;
  final String nomeInicial;
  final String cpf;
  final String emailInicial;
  final String telefoneInicial;
  final String versaoApp;

  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;
  final VoidCallback? aoClicarAlterarPin;
  final VoidCallback? aoClicarTermosUso;
  final void Function(String nome, String email, String telefone)?
      aoSalvarAlteracoes;

  const AdminAjustes({
    super.key,
    this.iniciaisUsuario = 'AD',
    required this.nomeInicial,
    required this.cpf,
    required this.emailInicial,
    this.telefoneInicial = '',
    this.versaoApp = 'v1.0.0',
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
    this.aoClicarAlterarPin,
    this.aoClicarTermosUso,
    this.aoSalvarAlteracoes,
  });

  @override
  State<AdminAjustes> createState() => _AdminAjustesState();
}

class _AdminAjustesState extends State<AdminAjustes> {
  final _chaveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controladorNome;
  late final TextEditingController _controladorEmail;
  late final TextEditingController _controladorTelefone;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController(text: widget.nomeInicial);
    _controladorEmail = TextEditingController(text: widget.emailInicial);
    _controladorTelefone = TextEditingController(
      text: _formatarTelefoneTexto(widget.telefoneInicial),
    );
  }

  @override
  void didUpdateWidget(covariant AdminAjustes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nomeInicial != widget.nomeInicial) {
      _controladorNome.text = widget.nomeInicial;
    }
    if (oldWidget.emailInicial != widget.emailInicial) {
      _controladorEmail.text = widget.emailInicial;
    }
    if (oldWidget.telefoneInicial != widget.telefoneInicial) {
      _controladorTelefone.text =
          _formatarTelefoneTexto(widget.telefoneInicial);
    }
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorTelefone.dispose();
    super.dispose();
  }

  static String _formatarCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 11) return cpf;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
        '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
  }

  static String _formatarTelefoneTexto(String telefone) {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length && i < 11; i++) {
      if (i == 0) {
        buffer.write('(');
      } else if (i == 2) {
        buffer.write(') ');
      } else if ((digitos.length <= 10 && i == 6) ||
          (digitos.length > 10 && i == 7)) {
        buffer.write('-');
      }
      buffer.write(digitos[i]);
    }
    return buffer.toString();
  }

  void _processarSalvar() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final nome = _controladorNome.text.trim();
      final email = _controladorEmail.text.trim().toLowerCase();
      final telefone = _controladorTelefone.text.trim();
      widget.aoSalvarAlteracoes?.call(nome, email, telefone);
    }
  }

  Widget _construirSecaoDadosAdministrador() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DADOS DO ADMINISTRADOR',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
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
              _CampoEditavelAdmin(
                rotulo: 'Nome completo',
                dica: 'Admin BlockPay',
                controlador: _controladorNome,
                tipoTeclado: TextInputType.name,
                validador: (valor) {
                  if ((valor ?? '').trim().isEmpty) {
                    return 'Informe o nome completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'CPF',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: 0.60,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2230),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CoresApp.borda,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: CoresApp.textoSecundario,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatarCpf(widget.cpf),
                          style: const TextStyle(
                            color: CoresApp.textoPrimario,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: CoresApp.textoSecundario,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'O CPF não pode ser alterado',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              _CampoEditavelAdmin(
                rotulo: 'E-mail',
                dica: 'admin@blockpay.com',
                controlador: _controladorEmail,
                tipoTeclado: TextInputType.emailAddress,
                validador: (valor) {
                  final texto = (valor ?? '').trim();
                  if (texto.isEmpty || !texto.contains('@')) {
                    return 'Informe um e-mail válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _CampoEditavelAdmin(
                rotulo: 'Telefone',
                dica: '(11) 98888-0000',
                controlador: _controladorTelefone,
                tipoTeclado: TextInputType.phone,
                formatadores: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _FormatadorTelefone(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirSecaoSeguranca() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEGURANÇA',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: widget.aoClicarAlterarPin,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CoresApp.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CoresApp.borda,
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alterar PIN administrativo',
                  style: TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: CoresApp.textoSecundario,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirSecaoSobre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOBRE',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Versão do app',
                      style: TextStyle(
                        color: CoresApp.textoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      widget.versaoApp,
                      style: const TextStyle(
                        color: CoresApp.textoSecundario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: CoresApp.borda,
              ),
              InkWell(
                onTap: widget.aoClicarTermosUso,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Termos de uso',
                        style: TextStyle(
                          color: CoresApp.textoPrimario,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: CoresApp.textoSecundario,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirBotaoSalvar() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processarSalvar,
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.cianoPrimario,
          foregroundColor: CoresApp.fundo,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Salvar alterações',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
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
              titulo: 'Ajustes',
              iniciaisUsuario: widget.iniciaisUsuario,
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
                child: Form(
                  key: _chaveFormulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _construirSecaoDadosAdministrador(),
                      const SizedBox(height: 20),
                      _construirSecaoSeguranca(),
                      const SizedBox(height: 20),
                      _construirSecaoSobre(),
                      const SizedBox(height: 24),
                      _construirBotaoSalvar(),
                    ],
                  ),
                ),
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
          iniciaisUsuario: widget.iniciaisUsuario,
          indiceAtivo: 3,
          etiquetaTela: 'Ajustes',
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
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _chaveFormulario,
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
                            'Ajustes',
                            style: TextStyle(
                              color: CoresApp.textoPrimario,
                              fontSize: 22,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _construirSecaoDadosAdministrador(),
                      const SizedBox(height: 20),
                      _construirSecaoSeguranca(),
                      const SizedBox(height: 20),
                      _construirSecaoSobre(),
                      const SizedBox(height: 24),
                      _construirBotaoSalvar(),
                    ],
                  ),
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
                : MenuInferiorAdminWrapper(
                    indiceAtivo: 3,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }
}

class _CampoEditavelAdmin extends StatelessWidget {
  final String rotulo;
  final String dica;
  final TextEditingController controlador;
  final TextInputType tipoTeclado;
  final List<TextInputFormatter>? formatadores;
  final String? Function(String?)? validador;

  const _CampoEditavelAdmin({
    required this.rotulo,
    required this.dica,
    required this.controlador,
    required this.tipoTeclado,
    this.formatadores,
    this.validador,
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
            fillColor: CoresApp.fundo,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: CoresApp.textoSecundario,
              size: 20,
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

class _FormatadorTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue valorAntigo,
    TextEditingValue valorNovo,
  ) {
    final digitos = valorNovo.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digitos.length && i < 11; i++) {
      if (i == 0) {
        buffer.write('(');
      } else if (i == 2) {
        buffer.write(') ');
      } else if ((digitos.length <= 10 && i == 6) ||
          (digitos.length > 10 && i == 7)) {
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
