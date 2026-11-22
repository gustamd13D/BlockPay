import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopAdminWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorAdminWrapper.dart';
import '../servicos/servicoBlockchain.dart';

class DadoMesAuditoria {
  final String rotuloMes;
  final int quantidadeTransacoes;
  final double volumeTotal;

  const DadoMesAuditoria({
    required this.rotuloMes,
    required this.quantidadeTransacoes,
    required this.volumeTotal,
  });
}

class TransacaoAuditoriaItem {
  final String idTransacao;
  final String hashTransacao;
  final String indiceBloco;
  final String hashBloco;
  final String nomeUsuario;
  final String cpfUsuario;
  final String iniciaisUsuario;
  final String tituloOperacao;
  final String subtituloOperacao;
  final String valorFormatado;
  final String? siglaCripto;
  final String? valorCriptoFormatado;
  final bool isEntrada;
  final String status;
  final String dataHoraCompleta;

  const TransacaoAuditoriaItem({
    required this.idTransacao,
    required this.hashTransacao,
    required this.indiceBloco,
    required this.hashBloco,
    required this.nomeUsuario,
    required this.cpfUsuario,
    required this.iniciaisUsuario,
    required this.tituloOperacao,
    required this.subtituloOperacao,
    required this.valorFormatado,
    this.siglaCripto,
    this.valorCriptoFormatado,
    required this.isEntrada,
    required this.status,
    required this.dataHoraCompleta,
  });
}

class Auditoria extends StatefulWidget {
  final String iniciaisUsuario;
  final String totalUsuariosFormatado;
  final String volumeTotalFormatado;
  final String totalTransacoesFormatado;
  final List<DadoMesAuditoria> dadosGraficoMensal;
  final List<TransacaoAuditoriaItem> transacoesRecentes;

  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const Auditoria({
    super.key,
    this.iniciaisUsuario = 'AD',
    required this.totalUsuariosFormatado,
    required this.volumeTotalFormatado,
    required this.totalTransacoesFormatado,
    required this.dadosGraficoMensal,
    required this.transacoesRecentes,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<Auditoria> createState() => _AuditoriaState();
}

class _AuditoriaState extends State<Auditoria> {
  @override
  void initState() {
    super.initState();
    ServicoBlockchain.instancia.iniciarGeracaoAutomatica();
  }

  @override
  void dispose() {
    ServicoBlockchain.instancia.pararGeracaoAutomatica();
    super.dispose();
  }

  void _copiarHash(BuildContext context, String hash) {
    Clipboard.setData(ClipboardData(text: hash));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hash da transação copiado!'),
        backgroundColor: CoresApp.cianoPrimario,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exibirDetalhesTransacao(
    BuildContext context,
    TransacaoAuditoriaItem item,
  ) {
    final bool possuiValorCripto = item.siglaCripto != null &&
        item.siglaCripto!.isNotEmpty &&
        item.valorCriptoFormatado != null &&
        item.valorCriptoFormatado!.isNotEmpty;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: CoresApp.superficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CoresApp.borda,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF21293A),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          item.iniciaisUsuario,
                          style: const TextStyle(
                            color: CoresApp.textoPrimario,
                            fontSize: 13,
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
                              item.tituloOperacao,
                              style: const TextStyle(
                                color: CoresApp.textoPrimario,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CPF: ${item.cpfUsuario}',
                              style: const TextStyle(
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
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: CoresApp.borda),
                  const SizedBox(height: 16),
                  _LinhaDetalheAuditoria(
                    rotulo: 'Valor movimentado (R\$)',
                    valor: item.valorFormatado,
                    corValor: item.isEntrada
                        ? const Color(0xFF00E676)
                        : CoresApp.textoPrimario,
                  ),
                  if (possuiValorCripto) ...[
                    const SizedBox(height: 12),
                    _LinhaDetalheAuditoria(
                      rotulo: 'Valor movimentado (${item.siglaCripto})',
                      valor: item.valorCriptoFormatado!,
                      corValor: CoresApp.cianoPrimario,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _LinhaDetalheAuditoria(
                    rotulo: 'Detalhes',
                    valor: item.subtituloOperacao,
                  ),
                  const SizedBox(height: 12),
                  _LinhaDetalheAuditoria(
                    rotulo: 'Status',
                    valor: item.status,
                    corValor: CoresApp.cianoPrimario,
                  ),
                  const SizedBox(height: 12),
                  _LinhaDetalheAuditoria(
                    rotulo: 'Data e hora',
                    valor: item.dataHoraCompleta,
                  ),
                  const SizedBox(height: 12),
                  _LinhaDetalheAuditoria(
                    rotulo: 'Bloco na rede',
                    valor: item.indiceBloco,
                    corValor: CoresApp.cianoPrimario,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CoresApp.fundo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CoresApp.borda,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hash da transação',
                              style: TextStyle(
                                color: CoresApp.textoSecundario,
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _copiarHash(context, item.hashTransacao),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 13,
                                      color: CoresApp.cianoPrimario,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Copiar',
                                      style: TextStyle(
                                        color: CoresApp.cianoPrimario,
                                        fontSize: 11,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          item.hashTransacao,
                          style: const TextStyle(
                            color: CoresApp.cianoPrimario,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.hashBloco.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Hash do bloco',
                            style: TextStyle(
                              color: CoresApp.textoSecundario,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            item.hashBloco,
                            style: const TextStyle(
                              color: CoresApp.textoSecundario,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoresApp.cianoPrimario,
                        foregroundColor: CoresApp.fundo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          fontSize: 14,
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

  Widget _construirCardsMetricas() {
    return Row(
      children: [
        Expanded(
          child: _CardMetricaAuditoria(
            valor: widget.totalUsuariosFormatado,
            rotulo: 'Usuários totais',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CardMetricaAuditoria(
            valor: widget.volumeTotalFormatado,
            rotulo: 'Volume total',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CardMetricaAuditoria(
            valor: widget.totalTransacoesFormatado,
            rotulo: 'Transações',
          ),
        ),
      ],
    );
  }

  Widget _construirGraficoMensal() {
    int maiorQuantidade = 0;
    for (final item in widget.dadosGraficoMensal) {
      if (item.quantidadeTransacoes > maiorQuantidade) {
        maiorQuantidade = item.quantidadeTransacoes;
      }
    }

    const double alturaMaximaBarra = 72.0;
    const double alturaMinimaBarra = 6.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transações por mês',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              StreamBuilder<BlocoBlockchain?>(
                stream: ServicoBlockchain.instancia.streamBlocoAtual(),
                builder: (context, snapBloco) {
                  final bloco = snapBloco.data;
                  final textoBloco = bloco != null
                      ? 'Bloco #${bloco.indice} (${bloco.quantidadeTransacoes}/${bloco.limiteTransacoes})'
                      : 'Bloco #0';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1500E5FF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0x3300E5FF),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      textoBloco,
                      style: const TextStyle(
                        color: CoresApp.cianoPrimario,
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 102,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.dadosGraficoMensal.map((dado) {
                double alturaBarra = alturaMinimaBarra;
                if (maiorQuantidade > 0 && dado.quantidadeTransacoes > 0) {
                  alturaBarra = 14.0 +
                      ((dado.quantidadeTransacoes / maiorQuantidade) *
                          (alturaMaximaBarra - 14.0));
                }

                return Expanded(
                  child: Tooltip(
                    message:
                        '${dado.rotuloMes}: ${dado.quantidadeTransacoes} transacoes',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: 16,
                          height: alturaBarra,
                          decoration: BoxDecoration(
                            color: dado.quantidadeTransacoes > 0
                                ? CoresApp.cianoPrimario
                                : CoresApp.borda,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dado.rotuloMes,
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
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoTransacoes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSAÇÕES RECENTES',
          style: TextStyle(
            color: CoresApp.textoSecundario,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.transacoesRecentes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: CoresApp.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CoresApp.borda,
                width: 1,
              ),
            ),
            child: const Text(
              'Nenhuma transação registrada na plataforma.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < widget.transacoesRecentes.length; i++) ...[
                _CardTransacaoAuditoria(
                  item: widget.transacoesRecentes[i],
                  aoClicar: () => _exibirDetalhesTransacao(
                    context,
                    widget.transacoesRecentes[i],
                  ),
                ),
                if (i < widget.transacoesRecentes.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }

  Widget _construirConteudo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _construirCardsMetricas(),
        const SizedBox(height: 16),
        _construirGraficoMensal(),
        const SizedBox(height: 20),
        _construirSecaoTransacoes(context),
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
              titulo: 'Auditoria',
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
          iniciaisUsuario: widget.iniciaisUsuario,
          indiceAtivo: 2,
          etiquetaTela: 'Auditoria',
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
                          'Auditoria',
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
                    indiceAtivo: 2,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }
}

class _CardMetricaAuditoria extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _CardMetricaAuditoria({
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                color: CoresApp.textoPrimario,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _CardTransacaoAuditoria extends StatelessWidget {
  final TransacaoAuditoriaItem item;
  final VoidCallback? aoClicar;

  const _CardTransacaoAuditoria({
    required this.item,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoClicar,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: Color(0xFF21293A),
                shape: BoxShape.circle,
              ),
              child: Text(
                item.iniciaisUsuario,
                style: const TextStyle(
                  color: CoresApp.textoPrimario,
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
                    item.tituloOperacao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CoresApp.textoPrimario,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtituloOperacao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 8),
            Text(
              item.valorFormatado,
              style: TextStyle(
                color: item.isEntrada
                    ? const Color(0xFF00E676)
                    : CoresApp.textoPrimario,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: CoresApp.textoSecundario,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaDetalheAuditoria extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color corValor;

  const _LinhaDetalheAuditoria({
    required this.rotulo,
    required this.valor,
    this.corValor = CoresApp.textoPrimario,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: corValor,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
