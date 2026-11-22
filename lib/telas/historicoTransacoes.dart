import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';

enum FiltroHistorico {
  todos('Todos'),
  depositos('Depósitos'),
  compras('Compras'),
  transferencias('Transferências');

  final String rotulo;
  const FiltroHistorico(this.rotulo);
}

enum CategoriaTransacao {
  deposito,
  compra,
  transferencia,
}

class ItemTransacaoHistorico {
  final String id;
  final CategoriaTransacao categoria;
  final String titulo;
  final String dataFormatada;
  final String valorFormatado;
  final Color corValor;
  final IconData icone;
  final DateTime dataHora;

  const ItemTransacaoHistorico({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.dataFormatada,
    required this.valorFormatado,
    required this.corValor,
    required this.icone,
    required this.dataHora,
  });
}

class HistoricoTransacoes extends StatefulWidget {
  final String iniciaisUsuario;
  final List<ItemTransacaoHistorico> transacoes;
  final bool carregando;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const HistoricoTransacoes({
    super.key,
    this.iniciaisUsuario = 'AL',
    required this.transacoes,
    this.carregando = false,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<HistoricoTransacoes> createState() => _HistoricoTransacoesState();
}

class _HistoricoTransacoesState extends State<HistoricoTransacoes> {
  FiltroHistorico _filtroSelecionado = FiltroHistorico.todos;

  List<ItemTransacaoHistorico> get _transacoesFiltradas {
    switch (_filtroSelecionado) {
      case FiltroHistorico.todos:
        return widget.transacoes;
      case FiltroHistorico.depositos:
        return widget.transacoes
            .where((t) => t.categoria == CategoriaTransacao.deposito)
            .toList();
      case FiltroHistorico.compras:
        return widget.transacoes
            .where((t) => t.categoria == CategoriaTransacao.compra)
            .toList();
      case FiltroHistorico.transferencias:
        return widget.transacoes
            .where((t) => t.categoria == CategoriaTransacao.transferencia)
            .toList();
    }
  }

  Widget _construirBarraFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: FiltroHistorico.values.map((filtro) {
          final bool ativo = _filtroSelecionado == filtro;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _filtroSelecionado = filtro;
                });
              },
              borderRadius: BorderRadius.circular(100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ativo ? CoresApp.cianoPrimario : CoresApp.superficie,
                  borderRadius: BorderRadius.circular(100),
                  border: ativo
                      ? null
                      : Border.all(
                          color: CoresApp.borda,
                          width: 1,
                        ),
                ),
                child: Text(
                  filtro.rotulo,
                  style: TextStyle(
                    color: ativo ? CoresApp.fundo : CoresApp.textoSecundario,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: ativo ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirConteudo() {
    final lista = _transacoesFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _construirBarraFiltros(),
        const SizedBox(height: 20),
        if (widget.carregando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: CircularProgressIndicator(
                color: CoresApp.cianoPrimario,
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (lista.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
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
                const Icon(
                  Icons.history_toggle_off_rounded,
                  color: CoresApp.textoSecundario,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  _filtroSelecionado == FiltroHistorico.todos
                      ? 'Nenhuma transação encontrada'
                      : 'Nenhuma movimentação em ${_filtroSelecionado.rotulo.toLowerCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Suas compras, depósitos e transferências aparecerão aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CoresApp.textoSecundario,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          )
        else
          ...lista.map(
            (transacao) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CardTransacao(transacao: transacao),
            ),
          ),
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
              titulo: 'Histórico de transações',
              iniciaisUsuario: widget.iniciaisUsuario,
              mostrarBotaoVoltar: true,
              aoVoltar: widget.aoVoltar ?? () => Navigator.maybePop(context),
              aoClicarPerfil: widget.aoClicarPerfil,
              aoClicarSair: widget.aoClicarSair,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
        CabecalhoDesktopWrapper(
          iniciaisUsuario: widget.iniciaisUsuario,
          indiceAtivo: 3,
          etiquetaTela: 'Histórico',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _BotaoVoltar(
                          aoClicar: widget.aoVoltar ??
                              () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Histórico de transações',
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
                : MenuInferiorWrapper(
                    indiceAtivo: 3,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }
}

class _CardTransacao extends StatelessWidget {
  final ItemTransacaoHistorico transacao;

  const _CardTransacao({required this.transacao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CoresApp.borda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: CoresApp.superficieAvatar,
              shape: BoxShape.circle,
            ),
            child: Icon(
              transacao.icone,
              color: CoresApp.textoPrimario,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao.titulo,
                  style: const TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transacao.dataFormatada,
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
          const SizedBox(width: 10),
          Text(
            transacao.valorFormatado,
            style: TextStyle(
              color: transacao.corValor,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoVoltar extends StatelessWidget {
  final VoidCallback? aoClicar;

  const _BotaoVoltar({this.aoClicar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoClicar ?? () => Navigator.maybePop(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CoresApp.superficie,
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
