import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta de cores centralizada do sistema de design BlockPay
abstract class _CoresApp {
  static const Color fundo = Color(0xFF0B0E17);
  static const Color superficie = Color(0xFF151A26);
  static const Color borda = Color(0xFF2A354A);
  static const Color cianoPrimario = Color(0xFF00E5FF);
  static const Color cianoSuave = Color(0x1F00E5FF);
  static const Color verdeSucesso = Color(0xFF00E676);
  static const Color verdeSuave = Color(0x1F00E676);
  static const Color amareloAlerta = Color(0xFFFFD600);
  static const Color amareloSuave = Color(0x1AFFD600);
  static const Color textoPrimario = Colors.white;
  static const Color textoSecundario = Color(0xFF90A4AE);
}

class TelaBoasVindas extends StatelessWidget {
  final VoidCallback? iniciarSimulacao;

  const TelaBoasVindas({
    super.key,
    this.iniciarSimulacao,
  });

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
            // Limita a largura maxima em tablets/web mantendo 100% fluido no celular
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calcula altura proporcional da ilustracao sem quebrar telas pequenas
                  const espacamentoHorizontal = 24.0;
                  final larguraConteudo =
                      constraints.maxWidth - (espacamentoHorizontal * 2);
                  final alturaIlustracao =
                      (larguraConteudo * 0.72).clamp(190.0, 265.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: espacamentoHorizontal,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _CabecalhoMarca(),
                              const SizedBox(height: 20),
                              _CartaoIlustracaoPrincipal(
                                altura: alturaIlustracao,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Aprenda a investir em\ncripto sem riscos',
                                style: TextStyle(
                                  color: _CoresApp.textoPrimario,
                                  fontSize: 28,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Simule carteiras, faça conversões instantâneas e envie transferências na blockchain usando um saldo fictício educativo.',
                                style: TextStyle(
                                  color: _CoresApp.textoSecundario,
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _ItemFuncionalidade(
                                icone: Icons.account_balance_wallet_outlined,
                                corIcone: _CoresApp.cianoPrimario,
                                corFundoIcone: _CoresApp.cianoSuave,
                                titulo: 'Carteira Simulada',
                                subtitulo:
                                    'Comece com R\$ 10.000,00 fictícios para praticar.',
                              ),
                              const SizedBox(height: 12),
                              const _ItemFuncionalidade(
                                icone: Icons.send_outlined,
                                corIcone: _CoresApp.verdeSucesso,
                                corFundoIcone: _CoresApp.verdeSuave,
                                titulo: 'Conversão & Pix',
                                subtitulo:
                                    'Simule pix e compre moedas com cotações reais.',
                              ),
                              const SizedBox(height: 16),
                              const _BannerAvisoEducativo(),
                              const Spacer(),
                              const SizedBox(height: 24),
                              _BotaoAcaoPrincipal(
                                rotulo: 'Iniciar Simulação',
                                aoPressionar: iniciarSimulacao ?? () {},
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CabecalhoMarca extends StatelessWidget {
  const _CabecalhoMarca();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
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
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'BlockPay',
          style: TextStyle(
            color: _CoresApp.textoPrimario,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _CoresApp.cianoSuave,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'EDU',
            style: TextStyle(
              color: _CoresApp.cianoPrimario,
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CartaoIlustracaoPrincipal extends StatelessWidget {
  final double altura;

  const _CartaoIlustracaoPrincipal({required this.altura});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _CoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _CoresApp.borda,
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carrega a ilustracao exportada do Figma; exibe alternativa visual se ainda nao existir
          Image.asset(
            'assets/images/hero_crypto.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.15),
                    radius: 0.85,
                    colors: [
                      Color(0x2E00E676),
                      Color(0x1F00E5FF),
                      _CoresApp.fundo,
                    ],
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.currency_bitcoin_rounded,
                      size: 84,
                      color: Color(0xE6FFD54F),
                    ),
                  ),
                ),
              );
            },
          ),
          // Gradiente sutil na base para garantir leitura do selo
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xD90B0E17),
                  ],
                ),
              ),
            ),
          ),
          // Selo "SIMULACAO EM TEMPO REAL"
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, left: 16, right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE6151A26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _CoresApp.cianoPrimario,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _CoresApp.verdeSucesso,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'SIMULAÇÃO EM TEMPO REAL',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _CoresApp.textoPrimario,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemFuncionalidade extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final Color corFundoIcone;
  final String titulo;
  final String subtitulo;

  const _ItemFuncionalidade({
    required this.icone,
    required this.corIcone,
    required this.corFundoIcone,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CoresApp.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _CoresApp.borda,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: corFundoIcone,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icone,
              color: corIcone,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: _CoresApp.textoPrimario,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: _CoresApp.textoSecundario,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerAvisoEducativo extends StatelessWidget {
  const _BannerAvisoEducativo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _CoresApp.amareloSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _CoresApp.amareloAlerta,
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.gpp_maybe_outlined,
            color: _CoresApp.amareloAlerta,
            size: 20,
          ),
          SizedBox(width: 10),
          // Expanded garante adaptacao sem estouro em qualquer largura de tela
          Expanded(
            child: Text(
              'Ambiente 100% educativo. Sem dinheiro real envolvido e sem qualquer tipo de risco financeiro.',
              style: TextStyle(
                color: _CoresApp.amareloAlerta,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoAcaoPrincipal extends StatelessWidget {
  final String rotulo;
  final VoidCallback aoPressionar;

  const _BotaoAcaoPrincipal({
    required this.rotulo,
    required this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: aoPressionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: _CoresApp.cianoPrimario,
          foregroundColor: _CoresApp.fundo,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
