import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorAdminWrapper.dart';

class RecuperarAcessoAdmin extends StatefulWidget {
  final String iniciaisUsuario;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoCancelar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;
  final void Function(String senhaAtual, String novaSenha)?
      aoConfirmarAlteracao;

  const RecuperarAcessoAdmin({
    super.key,
    this.iniciaisUsuario = 'AD',
    this.aoVoltar,
    this.aoCancelar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
    this.aoConfirmarAlteracao,
  });

  @override
  State<RecuperarAcessoAdmin> createState() => _RecuperarAcessoAdminState();
}

class _RecuperarAcessoAdminState extends State<RecuperarAcessoAdmin> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorSenhaAtual = TextEditingController();
  final _controladorNovaSenha = TextEditingController();
  final _controladorConfirmarSenha = TextEditingController();

  bool _ocultarSenhaAtual = true;
  bool _ocultarNovaSenha = true;
  bool _ocultarConfirmarSenha = true;

  @override
  void dispose() {
    _controladorSenhaAtual.dispose();
    _controladorNovaSenha.dispose();
    _controladorConfirmarSenha.dispose();
    super.dispose();
  }

  void _processarConfirmacao() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final senhaAtual = _controladorSenhaAtual.text.trim();
      final novaSenha = _controladorNovaSenha.text.trim();
      widget.aoConfirmarAlteracao?.call(senhaAtual, novaSenha);
    }
  }

  String? _validarSenhaAtual(String? valor) {
    if ((valor ?? '').trim().isEmpty) {
      return 'Informe a senha de admin atual';
    }
    return null;
  }

  String? _validarNovaSenha(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe a nova senha master';
    }
    if (texto.length < 12) {
      return 'A senha deve ter pelo menos 12 caracteres';
    }
    if (texto == _controladorSenhaAtual.text.trim()) {
      return 'A nova senha deve ser diferente da atual';
    }
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Confirme a nova senha master';
    }
    if (texto != _controladorNovaSenha.text.trim()) {
      return 'As senhas informadas não coincidem';
    }
    return null;
  }

  Widget _construirCabecalhoSeguranca() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: CoresApp.cianoSuave,
            shape: BoxShape.circle,
            border: Border.all(
              color: CoresApp.cianoPrimario,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: CoresApp.cianoPrimario,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Controle de Credenciais de Segurança do Console de Administração.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirBannerAlerta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1AFF5252),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x99FF5252),
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: CoresApp.vermelhoNegativo,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ATENÇÃO: Alterar a senha master do administrador altera muitas vezes pode causar o banimento da conta do BlockPay.',
              style: TextStyle(
                color: CoresApp.vermelhoNegativo,
                fontSize: 11.5,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
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
          _construirCabecalhoSeguranca(),
          const SizedBox(height: 20),
          _construirBannerAlerta(),
          const SizedBox(height: 20),
          _CampoSenhaAdmin(
            rotulo: 'Senha de admin atual',
            dica: 'Digite sua senha atual',
            controlador: _controladorSenhaAtual,
            acaoTeclado: TextInputAction.next,
            textoOculto: _ocultarSenhaAtual,
            validador: _validarSenhaAtual,
            aoAlternarVisibilidade: () {
              setState(() {
                _ocultarSenhaAtual = !_ocultarSenhaAtual;
              });
            },
          ),
          const SizedBox(height: 16),
          _CampoSenhaAdmin(
            rotulo: 'Nova senha master',
            dica: 'Mínimo 12 caracteres',
            controlador: _controladorNovaSenha,
            acaoTeclado: TextInputAction.next,
            textoOculto: _ocultarNovaSenha,
            validador: _validarNovaSenha,
            aoAlternarVisibilidade: () {
              setState(() {
                _ocultarNovaSenha = !_ocultarNovaSenha;
              });
            },
          ),
          const SizedBox(height: 16),
          _CampoSenhaAdmin(
            rotulo: 'Confirme a nova senha master',
            dica: 'Confirme a senha master',
            controlador: _controladorConfirmarSenha,
            acaoTeclado: TextInputAction.done,
            textoOculto: _ocultarConfirmarSenha,
            validador: _validarConfirmacao,
            concluirDigitacao: (_) => _processarConfirmacao(),
            aoAlternarVisibilidade: () {
              setState(() {
                _ocultarConfirmarSenha = !_ocultarConfirmarSenha;
              });
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Senhas administrativas requerem alta complexidade para proteger o console contra redefinições não autorizadas.',
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processarConfirmacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoresApp.cianoPrimario,
                foregroundColor: CoresApp.fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirmar alteração master',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
              titulo: 'Senha do Administrador',
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                constraints: const BoxConstraints(maxWidth: 560),
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
                          'Senha do Administrador',
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

class _CampoSenhaAdmin extends StatelessWidget {
  final String rotulo;
  final String dica;
  final TextEditingController controlador;
  final TextInputAction acaoTeclado;
  final bool textoOculto;
  final String? Function(String?)? validador;
  final ValueChanged<String>? concluirDigitacao;
  final VoidCallback aoAlternarVisibilidade;

  const _CampoSenhaAdmin({
    required this.rotulo,
    required this.dica,
    required this.controlador,
    required this.acaoTeclado,
    required this.textoOculto,
    required this.aoAlternarVisibilidade,
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
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: acaoTeclado,
          obscureText: textoOculto,
          validator: validador,
          onFieldSubmitted: concluirDigitacao,
          style: const TextStyle(
            color: CoresApp.textoPrimario,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
          cursorColor: CoresApp.cianoPrimario,
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: const TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: CoresApp.superficie,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: CoresApp.textoSecundario,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: aoAlternarVisibilidade,
              icon: Icon(
                textoOculto
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: CoresApp.textoSecundario,
                size: 20,
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
      ],
    );
  }
}
