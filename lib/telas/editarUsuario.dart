import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';

class EditarUsuario extends StatefulWidget {
  final String iniciaisAdmin;
  final String idExibicao;
  final String nomeInicial;
  final String cpf;
  final String emailInicial;
  final bool isAdminInicial;
  final bool contaAtivaInicial;

  final VoidCallback? aoVoltar;
  final VoidCallback? aoDescartar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;
  final void Function(
    String nome,
    String email,
    bool isAdmin,
    bool contaAtiva,
  )? aoSalvarAlteracoes;

  const EditarUsuario({
    super.key,
    this.iniciaisAdmin = 'AD',
    required this.idExibicao,
    required this.nomeInicial,
    required this.cpf,
    required this.emailInicial,
    required this.isAdminInicial,
    required this.contaAtivaInicial,
    this.aoVoltar,
    this.aoDescartar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
    this.aoSalvarAlteracoes,
  });

  @override
  State<EditarUsuario> createState() => _EditarUsuarioState();
}

class _EditarUsuarioState extends State<EditarUsuario> {
  final _chaveFormulario = GlobalKey<FormState>();
  late final TextEditingController _controladorNome;
  late final TextEditingController _controladorEmail;
  late String _perfilSelecionado;
  late bool _contaAtiva;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController(text: widget.nomeInicial);
    _controladorEmail = TextEditingController(text: widget.emailInicial);
    _perfilSelecionado = widget.isAdminInicial ? 'Administrador' : 'Cliente';
    _contaAtiva = widget.contaAtivaInicial;
  }

  @override
  void didUpdateWidget(covariant EditarUsuario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nomeInicial != widget.nomeInicial) {
      _controladorNome.text = widget.nomeInicial;
    }
    if (oldWidget.emailInicial != widget.emailInicial) {
      _controladorEmail.text = widget.emailInicial;
    }
    if (oldWidget.isAdminInicial != widget.isAdminInicial) {
      _perfilSelecionado = widget.isAdminInicial ? 'Administrador' : 'Cliente';
    }
    if (oldWidget.contaAtivaInicial != widget.contaAtivaInicial) {
      _contaAtiva = widget.contaAtivaInicial;
    }
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    super.dispose();
  }

  String _extrairIniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'US';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  String _formatarCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 11) return cpf;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
        '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
  }

  void _processarSalvar() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final nome = _controladorNome.text.trim();
      final email = _controladorEmail.text.trim().toLowerCase();
      final isAdmin = _perfilSelecionado == 'Administrador';
      widget.aoSalvarAlteracoes?.call(nome, email, isAdmin, _contaAtiva);
    }
  }

  Widget _construirCardResumoUsuario() {
    final nomeAtual = _controladorNome.text.trim().isEmpty
        ? widget.nomeInicial
        : _controladorNome.text.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CoresApp.borda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x1500E5FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              _extrairIniciais(nomeAtual),
              style: const TextStyle(
                color: CoresApp.cianoPrimario,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeAtual,
                  style: const TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.idExibicao,
                  style: const TextStyle(
                    color: CoresApp.textoSecundario,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    return Form(
      key: _chaveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCardResumoUsuario(),
          const SizedBox(height: 20),
          _CampoEdicaoUsuario(
            rotulo: 'Nome completo',
            dica: 'Nome completo',
            controlador: _controladorNome,
            tipoTeclado: TextInputType.name,
            aoAlterar: (_) => setState(() {}),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: CoresApp.superficie,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CoresApp.borda,
                width: 1,
              ),
            ),
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
          const SizedBox(height: 16),
          _CampoEdicaoUsuario(
            rotulo: 'E-mail',
            dica: 'usuario@email.com',
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoresApp.superficie,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CoresApp.borda,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conta ativa',
                        style: TextStyle(
                          color: CoresApp.textoPrimario,
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Permitir acesso ao BlockPay',
                        style: TextStyle(
                          color: CoresApp.textoSecundario,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _contaAtiva,
                  activeThumbColor: CoresApp.fundo,
                  activeTrackColor: CoresApp.cianoPrimario,
                  inactiveThumbColor: CoresApp.textoSecundario,
                  inactiveTrackColor: CoresApp.fundo,
                  onChanged: (valor) {
                    setState(() {
                      _contaAtiva = valor;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
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
              onPressed: widget.aoDescartar ??
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
                'Descartar alterações',
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
              titulo: 'Editar usuário',
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
                          'Editar usuário',
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

class _CampoEdicaoUsuario extends StatelessWidget {
  final String rotulo;
  final String dica;
  final TextEditingController controlador;
  final TextInputType tipoTeclado;
  final String? Function(String?)? validador;
  final ValueChanged<String>? aoAlterar;

  const _CampoEdicaoUsuario({
    required this.rotulo,
    required this.dica,
    required this.controlador,
    required this.tipoTeclado,
    this.validador,
    this.aoAlterar,
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
          validator: validador,
          onChanged: aoAlterar,
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
