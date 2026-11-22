import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';

class DepositarComPix extends StatefulWidget {
  final String iniciaisUsuario;
  final String chavePixRecebedor;
  final String nomeRecebedor;
  final String cidadeRecebedor;
  final void Function(String payloadPix)? aoGerarQrCode;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const DepositarComPix({
    super.key,
    this.iniciaisUsuario = 'AL',
    this.chavePixRecebedor = 'a1b2c3d4-e5f6-4789-abcd-1234567890ab',
    this.nomeRecebedor = 'BLOCKPAY EDU',
    this.cidadeRecebedor = 'SAO PAULO',
    this.aoGerarQrCode,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<DepositarComPix> createState() => _DepositarComPixState();
}

class _DepositarComPixState extends State<DepositarComPix> {
  String? _payloadPixGerado;

  /// Formata um campo TLV (Tag + Tamanho em 2 digitos + Valor)
  String _formatarTlv(String tag, String valor) {
    final tamanho = utf8.encode(valor).length.toString().padLeft(2, '0');
    return '$tag$tamanho$valor';
  }

  /// Calcula o checksum oficial CRC-16/CCITT-FALSE exigido pelo Banco Central
  String _calcularCrc16(String payload) {
    int crc = 0xFFFF;
    const int polinomio = 0x1021;
    final bytes = utf8.encode(payload);

    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ polinomio) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }

    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Gera um identificador alfanumerico valido (TXID) de ate 25 caracteres
  String _gerarTxId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final aleatorio = Random.secure();
    final sufixo = List.generate(
      8,
      (_) => chars[aleatorio.nextInt(chars.length)],
    ).join();
    return 'BLOCKPAY$sufixo';
  }

  /// Remove acentos e caracteres fora do padrao ASCII para compatibilidade bancaria
  String _normalizarAscii(String texto, int limiteMax) {
    const comAcento = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑáàâãäéèêëíìîïóòôõöúùûüçñ';
    const semAcento = 'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn';

    var resultado = texto.trim();
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    resultado =
        resultado.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '').toUpperCase();
    if (resultado.length > limiteMax) {
      resultado = resultado.substring(0, limiteMax);
    }
    return resultado.isEmpty ? 'BLOCKPAY' : resultado;
  }

  /// Monta a string completa do Pix Copia e Cola / QR Code no padrao EMVCo
  String _montarBrCodePix() {
    final gui = _formatarTlv('00', 'br.gov.bcb.pix');
    final chave = _formatarTlv('01', widget.chavePixRecebedor.trim());
    final merchantAccountInfo = _formatarTlv('26', '$gui$chave');

    final nomeNormalizado = _normalizarAscii(widget.nomeRecebedor, 25);
    final cidadeNormalizada = _normalizarAscii(widget.cidadeRecebedor, 15);
    final txId = _gerarTxId();

    final payloadSemCrc = [
      _formatarTlv('00', '01'), // Payload Format Indicator
      merchantAccountInfo, // Merchant Account Information (Pix)
      _formatarTlv('52', '0000'), // Merchant Category Code
      _formatarTlv('53', '986'), // Moeda: 986 = BRL
      _formatarTlv('58', 'BR'), // Pais: BR
      _formatarTlv('59', nomeNormalizado), // Nome do recebedor
      _formatarTlv('60', cidadeNormalizada), // Cidade do recebedor
      _formatarTlv('62', _formatarTlv('05', txId)), // TXID da transacao
      '6304', // Tag e tamanho do CRC16
    ].join();

    final crc16 = _calcularCrc16(payloadSemCrc);
    return '$payloadSemCrc$crc16';
  }

  void _gerarQrCodePix() {
    final brCode = _montarBrCodePix();
    setState(() {
      _payloadPixGerado = brCode;
    });
    widget.aoGerarQrCode?.call(brCode);
  }

  Future<void> _copiarCodigoPix() async {
    if (_payloadPixGerado == null) return;
    await Clipboard.setData(ClipboardData(text: _payloadPixGerado!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código Pix Copia e Cola copiado!'),
        backgroundColor: Color(0xFF00C853),
      ),
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
                    indiceAtivo: 2,
                    aoSelecionarAba: widget.aoSelecionarAba,
                  ),
          ),
        );
      },
    );
  }

  Widget _construirConteudoPix() {
    final bool qrGerado = _payloadPixGerado != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card informativo superior
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CoresApp.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CoresApp.borda,
              width: 1,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deposite via Pix',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Use o Pix para adicionar saldo à sua carteira de forma rápida e segura.',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card destaque verde com botao de gerar QR Code
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x1200E676),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CoresApp.verdePositivo,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.payments_outlined,
                color: CoresApp.verdePositivo,
                size: 36,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _gerarQrCodePix,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.verdePositivo,
                    foregroundColor: CoresApp.fundo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    qrGerado ? 'Gerar novo QR Code Pix' : 'Gerar QR Code Pix',
                    style: const TextStyle(
                      color: CoresApp.fundo,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'O saldo será creditado após a confirmação do pagamento',
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
        ),
        const SizedBox(height: 24),

        // Area de exibicao do QR Code Pix
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'QR Code Pix',
              style: TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: qrGerado ? 200 : 140,
              height: qrGerado ? 200 : 140,
              padding: EdgeInsets.all(qrGerado ? 12 : 20),
              decoration: BoxDecoration(
                color: qrGerado ? Colors.white : CoresApp.superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: qrGerado ? CoresApp.verdePositivo : CoresApp.borda,
                  width: qrGerado ? 2 : 1,
                ),
              ),
              child: qrGerado
                  ? QrImageView(
                      data: _payloadPixGerado!,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    )
                  : const Center(
                      child: _IconePlaceholderQr(),
                    ),
            ),
            if (qrGerado) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _copiarCodigoPix,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: CoresApp.cianoPrimario,
                ),
                label: const Text(
                  'Copiar código Pix',
                  style: TextStyle(
                    color: CoresApp.cianoPrimario,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CoresApp.borda, width: 1),
                  backgroundColor: CoresApp.superficie,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Confira os dados antes de concluir o pagamento no aplicativo do seu banco.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CoresApp.textoTerciario,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
              titulo: 'Adicionar saldo',
              iniciaisUsuario: widget.iniciaisUsuario,
              mostrarBotaoVoltar: true,
              aoVoltar: widget.aoVoltar,
              aoClicarPerfil: widget.aoClicarPerfil,
              aoClicarSair: widget.aoClicarSair,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _construirConteudoPix(),
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
          indiceAtivo: 2,
          etiquetaTela: 'Pix',
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
                        _BotaoVoltar(aoClicar: widget.aoVoltar),
                        const SizedBox(width: 12),
                        const Text(
                          'Adicionar saldo',
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
                    _construirConteudoPix(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icone placeholder de 4 quadrantes exibido antes de gerar o QR Code real
class _IconePlaceholderQr extends StatelessWidget {
  const _IconePlaceholderQr();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CoresApp.textoSecundario.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: 2,
              color: CoresApp.textoSecundario.withValues(alpha: 0.7),
            ),
          ),
          Center(
            child: Container(
              width: 2,
              height: double.infinity,
              color: CoresApp.textoSecundario.withValues(alpha: 0.7),
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
