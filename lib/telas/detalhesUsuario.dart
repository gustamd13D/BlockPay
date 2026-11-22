import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorAdminWrapper.dart';

class DetalhesUsuario extends StatelessWidget {
  final String iniciaisAdmin;
  final String nomeUsuario;
  final String emailUsuario;
  final String cpfUsuario;
  final String perfilUsuario;
  final String criadoEm;
  final String ultimoAcesso;
  final String statusUsuario;

  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;
  final VoidCallback? aoClicarEditarUsuario;
  final VoidCallback? aoAlternarBloqueio;
  final VoidCallback? aoConfirmarExclusao;

  const DetalhesUsuario({
    super.key,
    this.iniciaisAdmin = 'AD',
    required this.nomeUsuario,
    required this.emailUsuario,
    required this.cpfUsuario,
    required this.perfilUsuario,
    required this.criadoEm,
    required this.ultimoAcesso,
    required this.statusUsuario,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
    this.aoClicarEditarUsuario,
    this.aoAlternarBloqueio,
    this.aoConfirmarExclusao,
  });

  bool get _isBloqueado => statusUsuario.toLowerCase().trim() == 'bloqueado';
  bool get _isPendente => statusUsuario.toLowerCase().trim() == 'pendente';

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

  Future<void> _exibirPopupExcluir(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CoresApp.borda,
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0x20FFD600),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD600),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFD600),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Excluir usuário?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CoresApp.textoPrimario,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tem certeza que deseja excluir o usuário $nomeUsuario? '
                    'Esta ação não pode ser desfeita e todos os dados serão removidos permanentemente.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CoresApp.textoSecundario,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        aoConfirmarExclusao?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoresApp.vermelhoNegativo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sim, excluir usuário',
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
                    height: 50,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
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
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirBannerBloqueado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x15FF5252),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CoresApp.vermelhoNegativo,
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.block_rounded,
            color: CoresApp.vermelhoNegativo,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acesso bloqueado',
                  style: TextStyle(
                    color: CoresApp.vermelhoNegativo,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Este usuário não pode acessar a plataforma.',
                  style: TextStyle(
                    color: CoresApp.textoSecundario,
                    fontSize: 12,
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

  Widget _construirCardPerfil() {
    final Color corAvatarFundo =
        _isBloqueado ? const Color(0x15FF5252) : const Color(0x1500E5FF);
    final Color corAvatarTexto =
        _isBloqueado ? CoresApp.vermelhoNegativo : CoresApp.cianoPrimario;

    final String textoSelo = _isBloqueado
        ? 'Conta bloqueada'
        : _isPendente
            ? 'Conta pendente'
            : 'Conta ativa';

    final Color corSeloFundo = _isBloqueado
        ? const Color(0x18FF5252)
        : _isPendente
            ? const Color(0x18FFD600)
            : const Color(0x1800E676);

    final Color corSeloTexto = _isBloqueado
        ? CoresApp.vermelhoNegativo
        : _isPendente
            ? const Color(0xFFFFD600)
            : const Color(0xFF00E676);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: corAvatarFundo,
              shape: BoxShape.circle,
            ),
            child: Text(
              _extrairIniciais(nomeUsuario),
              style: TextStyle(
                color: corAvatarTexto,
                fontSize: 22,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nomeUsuario,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emailUsuario,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: corSeloFundo,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              textoSelo,
              style: TextStyle(
                color: corSeloTexto,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCardInformacoes() {
    return Container(
      width: double.infinity,
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
          _LinhaInfoUsuario(
            rotulo: 'CPF',
            valor: _formatarCpf(cpfUsuario),
          ),
          const SizedBox(height: 14),
          _LinhaInfoUsuario(
            rotulo: 'Perfil',
            valor: perfilUsuario,
          ),
          const SizedBox(height: 14),
          _LinhaInfoUsuario(
            rotulo: 'Criado em',
            valor: criadoEm,
          ),
          const SizedBox(height: 14),
          _LinhaInfoUsuario(
            rotulo: 'Último acesso',
            valor: ultimoAcesso,
          ),
        ],
      ),
    );
  }

  Widget _construirBotoesAcao(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: aoClicarEditarUsuario,
            style: ElevatedButton.styleFrom(
              backgroundColor: CoresApp.cianoPrimario,
              foregroundColor: CoresApp.fundo,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Editar usuário',
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
          child: OutlinedButton(
            onPressed: aoAlternarBloqueio,
            style: OutlinedButton.styleFrom(
              backgroundColor: CoresApp.superficie,
              foregroundColor: _isBloqueado
                  ? CoresApp.cianoPrimario
                  : CoresApp.textoPrimario,
              side: const BorderSide(
                color: CoresApp.borda,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isBloqueado ? 'Desbloquear acesso' : 'Bloquear acesso',
              style: const TextStyle(
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
          child: ElevatedButton(
            onPressed: () => _exibirPopupExcluir(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: CoresApp.vermelhoNegativo,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Excluir usuário',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirConteudo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isBloqueado) ...[
          _construirBannerBloqueado(),
          const SizedBox(height: 16),
        ],
        _construirCardPerfil(),
        const SizedBox(height: 16),
        _construirCardInformacoes(),
        const SizedBox(height: 20),
        _construirBotoesAcao(context),
      ],
    );
  }

  Widget _construirLayoutMobile(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            CabecalhoMobileWrapper(
              titulo: 'Detalhes do usuário',
              iniciaisUsuario: iniciaisAdmin,
              mostrarBotaoVoltar: true,
              estiloAdmin: true,
              aoVoltar: aoVoltar,
              aoClicarPerfil: aoClicarPerfil,
              aoClicarSair: aoClicarSair,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: _construirConteudo(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirLayoutDesktop(BuildContext context) {
    return Column(
      children: [
        CabecalhoDesktopAdminWrapper(
          iniciaisUsuario: iniciaisAdmin,
          indiceAtivo: 1,
          etiquetaTela: 'Usuários',
          aoSelecionarAba: aoSelecionarAba,
          aoClicarPerfil: aoClicarPerfil,
          aoClicarSair: aoClicarSair,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: aoVoltar ?? () => Navigator.maybePop(context),
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
                          'Detalhes do usuário',
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
                    _construirConteudo(context),
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
                  ? _construirLayoutDesktop(context)
                  : _construirLayoutMobile(context),
            ),
            bottomNavigationBar: telaGrande
                ? null
                : MenuInferiorAdminWrapper(
                    indiceAtivo: 1,
                    aoSelecionarAba: aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }
}

class _LinhaInfoUsuario extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _LinhaInfoUsuario({
    required this.rotulo,
    required this.valor,
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
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            color: CoresApp.textoPrimario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
