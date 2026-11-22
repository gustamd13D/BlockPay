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
  final Future<String?> Function(double valorBrl)? aoConfirmarDeposito;
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
    this.aoConfirmarDeposito,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<DepositarComPix> createState() => _DepositarComPixState();
}

class _DepositarComPixState extends State<DepositarComPix> {
  final TextEditingController _valorController = TextEditingController(
    text: '500,00',
  );

  String? _payloadPixGerado;
  double _valorQrGerado = 0.0;
  bool _confirmandoPagamento = false;

  static const List<double> _atalhosValores = [100.0, 500.0, 1000.0, 5000.0];

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  double _parseValorReais() {
    final limpo = _valorController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(limpo) ?? 0.0;
  }

  String _formatarValorCampo(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final centavos = partes[1];
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(inteiro[i]);
    }
    return '${buffer.toString()},$centavos';
  }

  void _selecionarAtalhoValor(double valor) {
    setState(() {
      _valorController.text = _formatarValorCampo(valor);
      _payloadPixGerado = null;
      _valorQrGerado = 0.0;
    });
  }

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
  String _montarBrCodePix(double valor) {
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
      if (valor > 0)
        _formatarTlv('54', valor.toStringAsFixed(2)), // Valor do Pix
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
    final valor = _parseValorReais();
    if (valor < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor mínimo de R\$ 1,00 para depositar.'),
          backgroundColor: CoresApp.vermelhoNegativo,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final brCode = _montarBrCodePix(valor);
    setState(() {
      _payloadPixGerado = brCode;
      _valorQrGerado = valor;
    });
    widget.aoGerarQrCode?.call(brCode);
  }

  Future<void> _confirmarPagamentoPix() async {
    if (_confirmandoPagamento ||
        _payloadPixGerado == null ||
        _valorQrGerado < 1.0) {
      return;
    }

    if (widget.aoConfirmarDeposito == null) return;

    setState(() => _confirmandoPagamento = true);

    final erro = await widget.aoConfirmarDeposito!(_valorQrGerado);

    if (!mounted) return;
    setState(() => _confirmandoPagamento = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: CoresApp.vermelhoNegativo,
        ),
      );
    }
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
        // Card informativo superior + campo de valor do deposito
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deposite via Pix',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Informe o valor que deseja adicionar à sua carteira BlockPay.',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Valor do depósito (BRL)',
                style: TextStyle(
                  color: CoresApp.textoSecundario,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _valorController,
                enabled: !_confirmandoPagamento,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _FormatadorMoedaPixInput(),
                ],
                onChanged: (_) {
                  if (_payloadPixGerado != null) {
                    setState(() {
                      _payloadPixGerado = null;
                      _valorQrGerado = 0.0;
                    });
                  }
                },
                style: const TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(
                    color: CoresApp.verdePositivo,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: CoresApp.fundo,
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
                      color: CoresApp.verdePositivo,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < _atalhosValores.length; i++) ...[
                    Expanded(
                      child: InkWell(
                        onTap: _confirmandoPagamento
                            ? null
                            : () => _selecionarAtalhoValor(_atalhosValores[i]),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: CoresApp.fundo,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CoresApp.borda,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'R\$ ${_atalhosValores[i].toInt()}',
                            style: const TextStyle(
                              color: CoresApp.textoPrimario,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < _atalhosValores.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
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
                  onPressed: _confirmandoPagamento ? null : _gerarQrCodePix,
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

        // Area de exibicao do QR Code Pix e confirmacao do pagamento
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              qrGerado
                  ? 'QR Code Pix — R\$ ${_formatarValorCampo(_valorQrGerado)}'
                  : 'QR Code Pix',
              style: const TextStyle(
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
                onPressed: _confirmandoPagamento ? null : _copiarCodigoPix,
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _confirmandoPagamento ? null : _confirmarPagamentoPix,
                  icon: _confirmandoPagamento
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CoresApp.fundo,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: CoresApp.fundo,
                        ),
                  label: Text(
                    _confirmandoPagamento
                        ? 'Registrando na blockchain...'
                        : 'Confirmar pagamento Pix',
                    style: const TextStyle(
                      color: CoresApp.fundo,
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

/// Formata os digitos digitados no padrao monetario brasileiro (ex: 50000 -> 500,00)
class _FormatadorMoedaPixInput extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) {
      return const TextEditingValue(
        text: '0,00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    final centavosInt = int.tryParse(digitos) ?? 0;
    final valor = centavosInt / 100.0;
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final centavos = partes[1];

    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(inteiro[i]);
    }

    final textoFormatado = '${buffer.toString()},$centavos';
    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
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
