import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorAdminWrapper.dart';

class UsuarioGerenciamentoItem {
  final String cpf;
  final String nome;
  final String email;
  final String status;
  final bool isAdmin;

  const UsuarioGerenciamentoItem({
    required this.cpf,
    required this.nome,
    required this.email,
    required this.status,
    this.isAdmin = false,
  });
}

class GerenciarUsuario extends StatefulWidget {
  final String iniciaisUsuario;
  final int totalUsuarios;
  final int usuariosAtivos;
  final int usuariosPendentes;
  final List<UsuarioGerenciamentoItem> usuarios;

  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;
  final VoidCallback? aoClicarNovoUsuario;
  final ValueChanged<UsuarioGerenciamentoItem>? aoSelecionarUsuario;

  const GerenciarUsuario({
    super.key,
    this.iniciaisUsuario = 'AD',
    required this.totalUsuarios,
    required this.usuariosAtivos,
    required this.usuariosPendentes,
    required this.usuarios,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
    this.aoClicarNovoUsuario,
    this.aoSelecionarUsuario,
  });

  @override
  State<GerenciarUsuario> createState() => _GerenciarUsuarioState();
}

class _GerenciarUsuarioState extends State<GerenciarUsuario> {
  final _controladorBusca = TextEditingController();
  String _termoBusca = '';

  @override
  void dispose() {
    _controladorBusca.dispose();
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

  List<UsuarioGerenciamentoItem> get _usuariosFiltrados {
    final consulta = _termoBusca.trim().toLowerCase();
    if (consulta.isEmpty) return widget.usuarios;

    final digitosConsulta = consulta.replaceAll(RegExp(r'\D'), '');

    return widget.usuarios.where((usuario) {
      final nomeMatch = usuario.nome.toLowerCase().contains(consulta);
      final emailMatch = usuario.email.toLowerCase().contains(consulta);
      final cpfMatch = digitosConsulta.isNotEmpty &&
          usuario.cpf.replaceAll(RegExp(r'\D'), '').contains(digitosConsulta);
      return nomeMatch || emailMatch || cpfMatch;
    }).toList();
  }

  Widget _construirCardsMetricas() {
    return Row(
      children: [
        Expanded(
          child: _CardMetricaUsuario(
            valor: widget.totalUsuarios.toString(),
            rotulo: 'Usuários',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CardMetricaUsuario(
            valor: widget.usuariosAtivos.toString(),
            rotulo: 'Ativos',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CardMetricaUsuario(
            valor: widget.usuariosPendentes.toString(),
            rotulo: 'Pendentes',
          ),
        ),
      ],
    );
  }

  Widget _construirCampoBusca() {
    return TextField(
      controller: _controladorBusca,
      onChanged: (valor) {
        setState(() {
          _termoBusca = valor;
        });
      },
      style: const TextStyle(
        color: CoresApp.textoPrimario,
        fontSize: 13,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      ),
      cursorColor: CoresApp.cianoPrimario,
      decoration: InputDecoration(
        hintText: 'Buscar por nome, CPF ou e-mail',
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
          vertical: 14,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: CoresApp.textoSecundario,
          size: 20,
        ),
        suffixIcon: _termoBusca.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _controladorBusca.clear();
                  setState(() {
                    _termoBusca = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: CoresApp.textoSecundario,
                  size: 18,
                ),
              )
            : null,
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
    );
  }

  Widget _construirBotaoNovoUsuario() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.aoClicarNovoUsuario,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Novo usuário',
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.cianoPrimario,
          foregroundColor: CoresApp.fundo,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _construirListaUsuarios() {
    final lista = _usuariosFiltrados;

    if (lista.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: CoresApp.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CoresApp.borda, width: 1),
        ),
        child: const Text(
          'Nenhum usuário encontrado.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < lista.length; i++) ...[
          _CardUsuarioLista(
            usuario: lista[i],
            iniciais: _extrairIniciais(lista[i].nome),
            aoClicar: () => widget.aoSelecionarUsuario?.call(lista[i]),
          ),
          if (i < lista.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _construirConteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _construirCardsMetricas(),
        const SizedBox(height: 16),
        _construirCampoBusca(),
        const SizedBox(height: 16),
        _construirBotaoNovoUsuario(),
        const SizedBox(height: 18),
        _construirListaUsuarios(),
      ],
    );
  }

  Widget _construirLayoutMobile() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            CabecalhoMobileWrapper(
              titulo: 'Gerenciar usuários',
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
                child: _construirConteudo(),
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
                constraints: const BoxConstraints(maxWidth: 760),
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
                          'Gerenciar usuários',
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
                    _construirConteudo(),
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
                    indiceAtivo: 1,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }
}

class _CardMetricaUsuario extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _CardMetricaUsuario({
    required this.valor,
    required this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CoresApp.borda,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            style: const TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardUsuarioLista extends StatelessWidget {
  final UsuarioGerenciamentoItem usuario;
  final String iniciais;
  final VoidCallback? aoClicar;

  const _CardUsuarioLista({
    required this.usuario,
    required this.iniciais,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final statusNormalizado = usuario.status.toLowerCase().trim();
    final bool isBloqueado = statusNormalizado == 'bloqueado';
    final bool isPendente = statusNormalizado == 'pendente';

    final String rotuloStatus = isBloqueado
        ? 'Bloqueado'
        : isPendente
            ? 'Pendente'
            : 'Ativo';

    final Color corBadgeTexto = isBloqueado
        ? CoresApp.vermelhoNegativo
        : isPendente
            ? const Color(0xFFFFD600)
            : const Color(0xFF00E676);

    final Color corBadgeFundo = isBloqueado
        ? const Color(0x18FF5252)
        : isPendente
            ? const Color(0x18FFD600)
            : const Color(0x1800E676);

    final Color corAvatarFundo =
        isBloqueado ? const Color(0x15FF5252) : const Color(0x1500E5FF);

    final Color corAvatarTexto =
        isBloqueado ? CoresApp.vermelhoNegativo : CoresApp.cianoPrimario;

    return InkWell(
      onTap: aoClicar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              decoration: BoxDecoration(
                color: corAvatarFundo,
                shape: BoxShape.circle,
              ),
              child: Text(
                iniciais,
                style: TextStyle(
                  color: corAvatarTexto,
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
                    usuario.nome,
                    style: const TextStyle(
                      color: CoresApp.textoPrimario,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.email,
                    style: const TextStyle(
                      color: CoresApp.textoSecundario,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: corBadgeFundo,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      rotuloStatus,
                      style: TextStyle(
                        color: corBadgeTexto,
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CoresApp.textoSecundario,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
