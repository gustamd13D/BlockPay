import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';

class EditarConta extends StatefulWidget {
  final String nome;
  final String cpf;
  final String email;
  final String telefone;

  /// Callbacks de acao e navegacao
  final void Function(String nome, String email, String telefone)?
      salvarAlteracoes;
  final VoidCallback? aoClicarAlterarSenha;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const EditarConta({
    super.key,
    required this.nome,
    required this.cpf,
    required this.email,
    this.telefone = '',
    this.salvarAlteracoes,
    this.aoClicarAlterarSenha,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<EditarConta> createState() => _EditarContaState();
}

class _EditarContaState extends State<EditarConta> {
  final _chaveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controladorNome;
  late final TextEditingController _controladorCpf;
  late final TextEditingController _controladorEmail;
  late final TextEditingController _controladorTelefone;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController(text: widget.nome);
    _controladorCpf = TextEditingController(text: _formatarCpf(widget.cpf));
    _controladorEmail = TextEditingController(text: widget.email);
    _controladorTelefone =
        TextEditingController(text: _formatarTelefoneInicial(widget.telefone));
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorCpf.dispose();
    _controladorEmail.dispose();
    _controladorTelefone.dispose();
    super.dispose();
  }

  static String _formatarCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 11) return cpf;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
        '${digitos.substring(6, 9)}-${digitos.substring(9)}';
  }

  static String _formatarTelefoneInicial(String telefone) {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return '';
    if (digitos.length == 11) {
      return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 7)}-${digitos.substring(7)}';
    }
    if (digitos.length == 10) {
      return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 6)}-${digitos.substring(6)}';
    }
    return telefone;
  }

  String _extrairIniciais(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'BP';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  void _processarSalvar() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final nome = _controladorNome.text.trim();
      final email = _controladorEmail.text.trim();
      final telefone = _controladorTelefone.text.trim();
      widget.salvarAlteracoes?.call(nome, email, telefone);
    }
  }

  String? _validarNome(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe seu nome completo';
    }
    if (texto.length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe seu e-mail';
    }
    final regexEmail = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!regexEmail.hasMatch(texto)) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  String? _validarTelefone(String? valor) {
    final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return null; // Opcional caso ainda nao cadastrado
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Informe um telefone válido com DDD';
    }
    return null;
  }

  Widget _construirFormulario({required bool telaGrande}) {
    final nomeExibicao = _controladorNome.text.trim().isEmpty
        ? widget.nome
        : _controladorNome.text.trim();

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
                  'Minha Conta',
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
          _CabecalhoPerfil(
            iniciais: _extrairIniciais(nomeExibicao),
            nomeCompleto: nomeExibicao,
          ),
          const SizedBox(height: 24),
          _CampoPerfil(
            rotulo: 'Nome completo',
            dica: 'Seu nome completo',
            icone: Icons.person_outline_rounded,
            controlador: _controladorNome,
            tipoTeclado: TextInputType.name,
            acaoTeclado: TextInputAction.next,
            validador: _validarNome,
            aoAlterar: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _CampoPerfil(
            rotulo: 'CPF',
            dica: '000.000.000-00',
            icone: Icons.person_outline_rounded,
            controlador: _controladorCpf,
            somenteLeitura: true,
            textoAjuda: 'O CPF não pode ser alterado',
          ),
          const SizedBox(height: 18),
          _CampoPerfil(
            rotulo: 'E-mail',
            dica: 'seu.email@exemplo.com',
            icone: Icons.mail_outline_rounded,
            controlador: _controladorEmail,
            tipoTeclado: TextInputType.emailAddress,
            acaoTeclado: TextInputAction.next,
            validador: _validarEmail,
          ),
          const SizedBox(height: 18),
          _CampoPerfil(
            rotulo: 'Telefone',
            dica: '(11) 99999-0000',
            icone: Icons.phone_outlined,
            controlador: _controladorTelefone,
            tipoTeclado: TextInputType.phone,
            acaoTeclado: TextInputAction.done,
            formatadores: [
              FilteringTextInputFormatter.digitsOnly,
              _FormatadorTelefone(),
            ],
            validador: _validarTelefone,
            concluirDigitacao: (_) => _processarSalvar(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.aoClicarAlterarSenha,
              icon: const Icon(
                Icons.lock_outline_rounded,
                color: CoresApp.textoSecundario,
                size: 20,
              ),
              label: const Text(
                'Alterar senha',
                style: TextStyle(
                  color: CoresApp.cianoPrimario,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: CoresApp.borda,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
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
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
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
                  fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final iniciais = _extrairIniciais(
      _controladorNome.text.trim().isEmpty
          ? widget.nome
          : _controladorNome.text.trim(),
    );

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
                          iniciaisUsuario: iniciais,
                          indiceAtivo: -1,
                          etiquetaTela: 'Minha Conta',
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
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: CoresApp.superficie,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: CoresApp.borda,
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
                            CabecalhoMobileWrapper(
                              titulo: 'Minha Conta',
                              iniciaisUsuario: iniciais,
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
                : MenuInferiorWrapper(
                    indiceAtivo: -1,
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

class _CabecalhoPerfil extends StatelessWidget {
  final String iniciais;
  final String nomeCompleto;

  const _CabecalhoPerfil({
    required this.iniciais,
    required this.nomeCompleto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: CoresApp.superficieAvatar,
            shape: BoxShape.circle,
          ),
          child: Text(
            iniciais,
            style: const TextStyle(
              color: CoresApp.cianoPrimario,
              fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nomeCompleto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CoresApp.textoPrimario,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CampoPerfil extends StatelessWidget {
  final String rotulo;
  final String dica;
  final IconData icone;
  final TextEditingController controlador;
  final bool somenteLeitura;
  final String? textoAjuda;
  final TextInputType? tipoTeclado;
  final TextInputAction? acaoTeclado;
  final List<TextInputFormatter>? formatadores;
  final String? Function(String?)? validador;
  final ValueChanged<String>? aoAlterar;
  final ValueChanged<String>? concluirDigitacao;

  const _CampoPerfil({
    required this.rotulo,
    required this.dica,
    required this.icone,
    required this.controlador,
    this.somenteLeitura = false,
    this.textoAjuda,
    this.tipoTeclado,
    this.acaoTeclado,
    this.formatadores,
    this.validador,
    this.aoAlterar,
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
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: somenteLeitura ? 0.65 : 1.0,
          child: TextFormField(
            controller: controlador,
            readOnly: somenteLeitura,
            enabled: !somenteLeitura,
            keyboardType: tipoTeclado,
            textInputAction: acaoTeclado,
            inputFormatters: formatadores,
            validator: validador,
            onChanged: aoAlterar,
            onFieldSubmitted: concluirDigitacao,
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
              fillColor: somenteLeitura
                  ? const Color(0xFF1A2230)
                  : CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: Icon(
                icone,
                color: CoresApp.textoSecundario,
                size: 20,
              ),
              suffixIcon: somenteLeitura
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      color: CoresApp.textoSecundario,
                      size: 18,
                    )
                  : null,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CoresApp.borda,
                  width: 1,
                ),
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
        ),
        if (textoAjuda != null) ...[
          const SizedBox(height: 6),
          Text(
            textoAjuda!,
            style: const TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _FormatadorTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;

    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(limitado[i]);
      if (i == 1) buffer.write(') ');
      if (limitado.length == 11 && i == 6) buffer.write('-');
      if (limitado.length <= 10 && i == 5) buffer.write('-');
    }

    final formatado = buffer.toString();
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}