import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1503232E);
  static const Color vermelhoErro = Color(0xFFFF5252);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class AlterarSenha extends StatefulWidget {
  final String cpf;

  /// Quando falso (fluxo de recuperacao por e-mail), oculta o campo de senha atual
  final bool exigirSenhaAtual;
  final void Function(String? senhaAtual, String novaSenha)? salvarSenha;

  const AlterarSenha({
    super.key,
    required this.cpf,
    this.exigirSenhaAtual = false,
    this.salvarSenha,
  });

  @override
  State<AlterarSenha> createState() => _AlterarSenhaState();
}

class _AlterarSenhaState extends State<AlterarSenha> {
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

  void _voltarParaLoginOuAnterior() {
    if (widget.exigirSenhaAtual) {
      Navigator.pop(context);
    } else {
      Navigator.popUntil(context, ModalRoute.withName('/login'));
    }
  }

  void _processarSalvar() {
    FocusScope.of(context).unfocus();

    if (_chaveFormulario.currentState?.validate() ?? false) {
      final senhaAtual =
          widget.exigirSenhaAtual ? _controladorSenhaAtual.text.trim() : null;
      final novaSenha = _controladorNovaSenha.text.trim();
      widget.salvarSenha?.call(senhaAtual, novaSenha);
    }
  }

  String? _validarSenhaAtual(String? valor) {
    if (!widget.exigirSenhaAtual) return null;
    if ((valor ?? '').trim().isEmpty) {
      return 'Informe a sua senha atual';
    }
    return null;
  }

  String? _validarNovaSenha(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe a nova senha';
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

  String? _validarConfirmacao(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Confirme a nova senha';
    }
    if (texto != _controladorNovaSenha.text.trim()) {
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                        titulo: 'Alterar Senha',
                        aoVoltar: _voltarParaLoginOuAnterior,
                      ),
                      const SizedBox(height: 28),
                      const _CabecalhoCadeado(),
                      const SizedBox(height: 28),
                      if (widget.exigirSenhaAtual) ...[
                        _CampoSenha(
                          rotulo: 'Senha atual',
                          dica: '••••••••',
                          controlador: _controladorSenhaAtual,
                          acaoTeclado: TextInputAction.next,
                          textoOculto: _ocultarSenhaAtual,
                          validador: _validarSenhaAtual,
                          alternarVisibilidade: () {
                            setState(() {
                              _ocultarSenhaAtual = !_ocultarSenhaAtual;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _CampoSenha(
                        rotulo: 'Nova senha',
                        dica: 'Mínimo 8 caracteres',
                        controlador: _controladorNovaSenha,
                        acaoTeclado: TextInputAction.next,
                        textoOculto: _ocultarNovaSenha,
                        validador: _validarNovaSenha,
                        alternarVisibilidade: () {
                          setState(() {
                            _ocultarNovaSenha = !_ocultarNovaSenha;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _CampoSenha(
                        rotulo: 'Confirme a nova senha',
                        dica: 'Digite a nova senha novamente',
                        controlador: _controladorConfirmarSenha,
                        acaoTeclado: TextInputAction.done,
                        textoOculto: _ocultarConfirmarSenha,
                        validador: _validarConfirmacao,
                        concluirDigitacao: (_) => _processarSalvar(),
                        alternarVisibilidade: () {
                          setState(() {
                            _ocultarConfirmarSenha = !_ocultarConfirmarSenha;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A nova senha deve conter pelo menos uma letra maiúscula, um número e um caractere especial.',
                        style: TextStyle(
                          color: _CoresApp.textoSecundario,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                            'Salvar nova senha',
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
                          onPressed: _voltarParaLoginOuAnterior,
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
                      const SizedBox(height: 16),
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

class _CabecalhoCadeado extends StatelessWidget {
  const _CabecalhoCadeado();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _CoresApp.cianoSuave,
            shape: BoxShape.circle,
            border: Border.all(
              color: _CoresApp.cianoPrimario,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: _CoresApp.cianoPrimario,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Mantenha sua conta BlockPay segura. Escolha uma senha forte de uso pessoal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _CoresApp.textoSecundario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _CampoSenha extends StatelessWidget {
  final String rotulo;
  final String dica;
  final TextEditingController controlador;
  final TextInputAction acaoTeclado;
  final bool textoOculto;
  final String? Function(String?)? validador;
  final ValueChanged<String>? concluirDigitacao;
  final VoidCallback alternarVisibilidade;

  const _CampoSenha({
    required this.rotulo,
    required this.dica,
    required this.controlador,
    required this.acaoTeclado,
    required this.textoOculto,
    required this.alternarVisibilidade,
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
          keyboardType: TextInputType.visiblePassword,
          textInputAction: acaoTeclado,
          obscureText: textoOculto,
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
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: _CoresApp.textoSecundario,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: alternarVisibilidade,
              icon: Icon(
                textoOculto
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _CoresApp.textoSecundario,
                size: 20,
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
      ],
    );
  }
}
