import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../componentes/cabecalhoDesktopWrapper.dart';
import '../componentes/cabecalhoMobileWrapper.dart';
import '../componentes/coresApp.dart';
import '../componentes/menuInferiorWrapper.dart';

class TransferirCripto extends StatefulWidget {
  final String iniciaisUsuario;
  final double saldoBtc;
  final double saldoEth;
  final double saldoSol;
  final double saldoAda;
  final String? emailRemetente;
  final String? cpfRemetente;

  /// Callback assincrono executado ao confirmar a transferencia.
  /// Deve retornar null se concluir com sucesso ou uma mensagem de erro
  /// caso o destinatario nao exista no banco.
  final Future<String?> Function(
    String destinatario,
    String ativo,
    double quantidade,
  )? aoTransferir;

  /// Callbacks de navegacao
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;
  final ValueChanged<int>? aoSelecionarAba;

  const TransferirCripto({
    super.key,
    this.iniciaisUsuario = 'AL',
    this.saldoBtc = 0.034,
    this.saldoEth = 0.25,
    this.saldoSol = 0.0,
    this.saldoAda = 0.0,
    this.emailRemetente,
    this.cpfRemetente,
    this.aoTransferir,
    this.aoClicarPerfil,
    this.aoClicarSair,
    this.aoSelecionarAba,
  });

  @override
  State<TransferirCripto> createState() => _TransferirCriptoState();
}

class _TransferirCriptoState extends State<TransferirCripto> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorDestinatario = TextEditingController();
  final _controladorQuantidade = TextEditingController();

  String _ativoSelecionado = '';
  String? _erroDestinatario;
  bool _verificandoEnvio = false;

  @override
  void initState() {
    super.initState();
    _sincronizarAtivoSelecionado();
  }

  @override
  void didUpdateWidget(covariant TransferirCripto oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizarAtivoSelecionado();
  }

  @override
  void dispose() {
    _controladorDestinatario.dispose();
    _controladorQuantidade.dispose();
    super.dispose();
  }

  double _saldoPorSigla(String sigla) {
    switch (sigla) {
      case 'BTC':
        return widget.saldoBtc;
      case 'ETH':
        return widget.saldoEth;
      case 'SOL':
        return widget.saldoSol;
      case 'ADA':
        return widget.saldoAda;
      default:
        return 0.0;
    }
  }

  /// Retorna apenas os ativos em que o usuario possui saldo maior que zero
  List<dynamic> get _ativosDisponiveis {
    const todosAtivos = [
      {'sigla': 'BTC', 'nome': 'Bitcoin'},
      {'sigla': 'ETH', 'nome': 'Ethereum'},
      {'sigla': 'SOL', 'nome': 'Solana'},
      {'sigla': 'ADA', 'nome': 'Cardano'},
    ];

    return todosAtivos
        .where((ativo) => _saldoPorSigla(ativo['sigla']!) > 1e-9)
        .toList();
  }

  /// Garante que o ativo selecionado sempre exista na lista de saldos positivos
  void _sincronizarAtivoSelecionado() {
    final disponiveis = _ativosDisponiveis;
    if (disponiveis.isEmpty) {
      _ativoSelecionado = '';
      return;
    }

    final aindaPossuiSaldo =
        disponiveis.any((ativo) => ativo['sigla'] == _ativoSelecionado);
    if (!aindaPossuiSaldo) {
      _ativoSelecionado = disponiveis.first['sigla']!;
    }
  }

  double get _saldoDisponivelAtual => _saldoPorSigla(_ativoSelecionado);

  static String _formatarQuantidade(double valor) {
    var texto = valor.toStringAsFixed(6).replaceAll('.', ',');
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    if (texto.endsWith(',')) {
      texto = '${texto}00';
    }
    return texto;
  }

  double? _converterQuantidade(String texto) {
    final normalizado = texto.trim().replaceAll(',', '.');
    return double.tryParse(normalizado);
  }

  String? _validarDestinatario(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe o e-mail ou CPF do usuário cadastrado';
    }

    final regexEmail = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    final apenasDigitos = texto.replaceAll(RegExp(r'\D'), '');
    final regexCarteira = RegExp(r'^(0x)?[a-zA-Z0-9]{12,64}$');

    if (!regexEmail.hasMatch(texto) &&
        apenasDigitos.length != 11 &&
        !regexCarteira.hasMatch(texto)) {
      return 'Informe um e-mail, CPF ou endereço válido';
    }

    final emailProprio = (widget.emailRemetente ?? '').trim().toLowerCase();
    final cpfProprio =
        (widget.cpfRemetente ?? '').replaceAll(RegExp(r'\D'), '');

    if ((emailProprio.isNotEmpty && texto.toLowerCase() == emailProprio) ||
        (cpfProprio.isNotEmpty &&
            apenasDigitos.length == 11 &&
            apenasDigitos == cpfProprio)) {
      return 'Você não pode transferir para sua própria conta';
    }

    return null;
  }

  String? _validarQuantidade(String? valor) {
    if (_ativosDisponiveis.isEmpty) {
      return 'Você não possui saldo em criptomoedas';
    }

    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return 'Informe a quantidade para transferir';
    }

    final quantidade = _converterQuantidade(texto);
    if (quantidade == null || quantidade <= 0) {
      return 'Informe um valor maior que zero';
    }

    if (quantidade > _saldoDisponivelAtual + 1e-9) {
      return 'Saldo insuficiente de $_ativoSelecionado';
    }

    return null;
  }

  Future<void> _processarTransferencia() async {
    if (_verificandoEnvio || _ativosDisponiveis.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _erroDestinatario = null;
    });

    if (!(_chaveFormulario.currentState?.validate() ?? false)) {
      return;
    }

    final destinatario = _controladorDestinatario.text.trim();
    final quantidade = _converterQuantidade(_controladorQuantidade.text)!;

    if (widget.aoTransferir == null) return;

    setState(() {
      _verificandoEnvio = true;
    });

    try {
      final erroRetornado = await widget.aoTransferir!(
        destinatario,
        _ativoSelecionado,
        quantidade,
      );

      if (!mounted) return;
      if (erroRetornado != null && erroRetornado.isNotEmpty) {
        setState(() {
          _erroDestinatario = erroRetornado;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _verificandoEnvio = false;
        });
      }
    }
  }

  Widget _construirIconeAtivo(String sigla) {
    switch (sigla) {
      case 'BTC':
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: CoresApp.amareloSuave,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.currency_bitcoin_rounded,
            color: CoresApp.amareloBitcoin,
            size: 16,
          ),
        );
      case 'ETH':
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: CoresApp.cianoSuave,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.toll_rounded,
            color: CoresApp.cianoPrimario,
            size: 16,
          ),
        );
      case 'SOL':
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: CoresApp.roxoSuave,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'SOL',
            style: TextStyle(
              color: CoresApp.roxoSolana,
              fontSize: 8.5,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      case 'ADA':
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: CoresApp.azulSuave,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'ADA',
            style: TextStyle(
              color: CoresApp.azulCardano,
              fontSize: 8.5,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      default:
        return const SizedBox(width: 24, height: 24);
    }
  }

  DropdownMenuItem<String> _construirItemAtivo(String sigla, String nome) {
    return DropdownMenuItem(
      value: sigla,
      child: Row(
        children: [
          _construirIconeAtivo(sigla),
          const SizedBox(width: 10),
          Text(
            '$nome ($sigla)',
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario({required bool telaGrande}) {
    final ativosDisponiveis = _ativosDisponiveis;
    final possuiAtivos = ativosDisponiveis.isNotEmpty;

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
                  'Transferir cripto',
                  style: TextStyle(
                    color: CoresApp.textoPrimario,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Destinatário (e-mail ou endereço)',
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controladorDestinatario,
            enabled: possuiAtivos,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validarDestinatario,
            onChanged: (_) {
              if (_erroDestinatario != null) {
                setState(() {
                  _erroDestinatario = null;
                });
              }
            },
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            cursorColor: CoresApp.cianoPrimario,
            decoration: InputDecoration(
              hintText: 'usuario@exemplo.com',
              errorText: _erroDestinatario,
              errorMaxLines: 2,
              hintStyle: const TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 14,
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
                Icons.person_outline_rounded,
                color: CoresApp.textoSecundario,
                size: 20,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CoresApp.borda,
                  width: 1,
                ),
              ),
              disabledBorder: OutlineInputBorder(
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
          const SizedBox(height: 18),
          const Text(
            'Selecione o ativo',
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (possuiAtivos)
            DropdownButtonFormField<String>(
              value: _ativoSelecionado,
              dropdownColor: CoresApp.superficie,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: CoresApp.textoSecundario,
                size: 22,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: CoresApp.superficie,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
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
              ),
              items: ativosDisponiveis
                  .map(
                    (ativo) => _construirItemAtivo(
                      ativo['sigla']!,
                      ativo['nome']!,
                    ),
                  )
                  .toList(),
              onChanged: _verificandoEnvio
                  ? null
                  : (novoAtivo) {
                      if (novoAtivo == null) return;
                      setState(() {
                        _ativoSelecionado = novoAtivo;
                      });
                      if (_controladorQuantidade.text.trim().isNotEmpty) {
                        _chaveFormulario.currentState?.validate();
                      }
                    },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: CoresApp.superficie,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CoresApp.borda,
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: CoresApp.textoSecundario,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nenhuma cripto com saldo disponível',
                      style: TextStyle(
                        color: CoresApp.textoSecundario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Quantidade',
            style: TextStyle(
              color: CoresApp.textoSecundario,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controladorQuantidade,
            enabled: possuiAtivos,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: _validarQuantidade,
            onFieldSubmitted: (_) => _processarTransferencia(),
            style: const TextStyle(
              color: CoresApp.textoPrimario,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
            cursorColor: CoresApp.cianoPrimario,
            decoration: InputDecoration(
              hintText: '0.001',
              hintStyle: const TextStyle(
                color: CoresApp.textoSecundario,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: CoresApp.superficie,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      possuiAtivos ? _ativoSelecionado : '---',
                      style: const TextStyle(
                        color: CoresApp.cianoPrimario,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: CoresApp.borda,
                  width: 1,
                ),
              ),
              disabledBorder: OutlineInputBorder(
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                possuiAtivos
                    ? 'Disponível: ${_formatarQuantidade(_saldoDisponivelAtual)} $_ativoSelecionado'
                    : 'Compre criptomoedas na aba Mercado para transferir',
                style: const TextStyle(
                  color: CoresApp.textoTerciario,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (possuiAtivos)
                InkWell(
                  onTap: _verificandoEnvio
                      ? null
                      : () {
                          _controladorQuantidade.text =
                              _saldoDisponivelAtual.toString();
                          _chaveFormulario.currentState?.validate();
                        },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Usar máximo',
                      style: TextStyle(
                        color: CoresApp.cianoPrimario,
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_verificandoEnvio || !possuiAtivos)
                  ? null
                  : _processarTransferencia,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoresApp.cianoPrimario,
                disabledBackgroundColor:
                    CoresApp.cianoPrimario.withOpacity(0.35),
                foregroundColor: CoresApp.fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _verificandoEnvio
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: CoresApp.fundo,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Verificando destinatário...',
                          style: TextStyle(
                            color: CoresApp.fundo,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuar transferência',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.send_outlined,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
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
                  ? Column(
                      children: [
                        CabecalhoDesktopWrapper(
                          iniciaisUsuario: widget.iniciaisUsuario,
                          indiceAtivo: 0,
                          etiquetaTela: 'Transferir Cripto',
                          aoSelecionarAba: widget.aoSelecionarAba,
                          aoClicarPerfil: widget.aoClicarPerfil,
                          aoClicarSair: widget.aoClicarSair,
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
                                    color: CoresApp.superficie,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: CoresApp.borda,
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
                            CabecalhoMobileWrapper(
                              titulo: 'Transferir cripto',
                              iniciaisUsuario: widget.iniciaisUsuario,
                              mostrarBotaoVoltar: true,
                              aoVoltar: () => Navigator.pop(context),
                              aoClicarPerfil: widget.aoClicarPerfil,
                              aoClicarSair: widget.aoClicarSair,
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
                : MenuInferiorWrapper(
                    indiceAtivo: 0,
                    aoSelecionarAba: widget.aoSelecionarAba,
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
          color: CoresApp.superficieAvatar,
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
