import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color superficieDesabilitada = Color(0xFF1A2230);
  static const Color superficieAvatar = Color(0xFF21293A);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1500E5FF);
  static const Color vermelhoErro = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class EditarConta extends StatefulWidget {
  final String nome;
  final String cpf;
  final String email;
  final String telefone;

  /// Callbacks de acao e navegacao
  final void Function(String nome, String email, String telefone)?
      salvarAlteracoes;
  final VoidCallback? aoClicarAlterarSenha;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const EditarConta({
    super.key,
    required this.nome,
    required this.cpf,
    required this.email,
    this.telefone = '',
    this.salvarAlteracoes,
    this.aoClicarAlterarSenha,
    this.aoClicarInicio,
    this.aoClicarMercado,
    this.aoClicarPix,
    this.aoClicarHistorico,
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
                color: _CoresApp.textoSecundario,
                size: 20,
              ),
              label: const Text(
                'Alterar senha',
                style: TextStyle(
                  color: _CoresApp.cianoPrimario,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: _CoresApp.borda,
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
                backgroundColor: _CoresApp.cianoPrimario,
                foregroundColor: _CoresApp.fundo,
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
                foregroundColor: _CoresApp.textoPrimario,
                side: const BorderSide(
                  color: _CoresApp.borda,
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
                          iniciais: iniciais,
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
                              titulo: 'Minha Conta',
                              aoVoltar: () => Navigator.pop(context),
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
  final VoidCallback aoVoltar;

  const _BarraSuperiorMobile({
    required this.titulo,
    required this.aoVoltar,
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
        ],
      ),
    );
  }
}

class _CabecalhoDesktop extends StatelessWidget {
  final String iniciais;
  final VoidCallback? aoClicarInicio;
  final VoidCallback? aoClicarMercado;
  final VoidCallback? aoClicarPix;
  final VoidCallback? aoClicarHistorico;

  const _CabecalhoDesktop({
    required this.iniciais,
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
                  'Minha Conta',
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
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _CoresApp.superficieAvatar,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _CoresApp.cianoPrimario,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  iniciais,
                  style: const TextStyle(
                    color: _CoresApp.cianoPrimario,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
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
            color: _CoresApp.superficieAvatar,
            shape: BoxShape.circle,
          ),
          child: Text(
            iniciais,
            style: const TextStyle(
              color: _CoresApp.cianoPrimario,
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
            color: _CoresApp.textoPrimario,
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
            color: _CoresApp.textoSecundario,
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
              color: _CoresApp.textoPrimario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
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
              fillColor: somenteLeitura
                  ? _CoresApp.superficieDesabilitada
                  : _CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: Icon(
                icone,
                color: _CoresApp.textoSecundario,
                size: 20,
              ),
              suffixIcon: somenteLeitura
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      color: _CoresApp.textoSecundario,
                      size: 18,
                    )
                  : null,
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _CoresApp.borda,
                  width: 1,
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
        ),
        if (textoAjuda != null) ...[
          const SizedBox(height: 6),
          Text(
            textoAjuda!,
            style: const TextStyle(
              color: _CoresApp.textoSecundario,
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
