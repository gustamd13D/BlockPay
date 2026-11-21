import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'modelos/clienteModelo.dart';
import 'servicos/servicoFirestore.dart';
import 'telas/boasvindas.dart';
import 'telas/login.dart';
import 'telas/cadastroCliente.dart';
import 'telas/recuperarAcesso.dart';
import 'telas/validarCodigo.dart';
import 'telas/alterarSenha.dart';
import 'telas/dashboard.dart';
import 'telas/editarConta.dart';
import 'telas/transferirCripto.dart';
import 'telas/statusBlockchain.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(BlockPayApp());
}

class BlockPayApp extends StatelessWidget {
  final ServicoFirestore _servicoFirestore = ServicoFirestore();

  BlockPayApp({super.key});

  Future<T?> _executarComCarregamento<T>(
    BuildContext context,
    Future<T> Function() operacao,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00E5FF),
        ),
      ),
    );

    try {
      final resultado = await operacao();
      if (context.mounted) Navigator.pop(context);
      return resultado;
    } catch (erro) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString()),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
      return null;
    }
  }

  String _extrairIniciais(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'BP';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  String _gerarHashBlockchain() {
    final aleatorio = Random.secure();
    const hexChars = '0123456789abcdef';
    final buffer = StringBuffer('0x');
    for (var i = 0; i < 64; i++) {
      buffer.write(hexChars[aleatorio.nextInt(hexChars.length)]);
    }
    return buffer.toString();
  }

  String _formatarMoedaBr(double valor) {
    final partes = valor.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final centavos = partes[1];
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiro[i]);
    }
    return 'R\$ ${buffer.toString()},$centavos';
  }

  void _avisarTelaEmBreve(BuildContext context, String nomeTela) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tela de $nomeTela em desenvolvimento.'),
        backgroundColor: const Color(0xFF151A26),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Busca um cliente cadastrado no Firestore por e-mail, CPF ou endereco
  Future<DocumentSnapshot?> _buscarDestinatarioCadastrado(
    FirebaseFirestore firestore,
    String destinatario,
  ) async {
    final texto = destinatario.trim();
    final textoMinusculo = texto.toLowerCase();

    // 1. Busca por e-mail (exato e minusculo)
    var consulta = await firestore
        .collection('clientes')
        .where('email', isEqualTo: textoMinusculo)
        .limit(1)
        .get();

    if (consulta.docs.isEmpty && texto != textoMinusculo) {
      consulta = await firestore
          .collection('clientes')
          .where('email', isEqualTo: texto)
          .limit(1)
          .get();
    }
    if (consulta.docs.isNotEmpty) return consulta.docs.first;

    // 2. Busca por CPF (11 digitos)
    final apenasDigitos = texto.replaceAll(RegExp(r'\D'), '');
    if (apenasDigitos.length == 11) {
      final docPorCpf =
          await firestore.collection('clientes').doc(apenasDigitos).get();
      if (docPorCpf.exists) return docPorCpf;
    }

    // 3. Busca por endereco de carteira (se cadastrado no documento)
    final consultaCarteira = await firestore
        .collection('clientes')
        .where('enderecoCarteira', isEqualTo: texto)
        .limit(1)
        .get();
    if (consultaCarteira.docs.isNotEmpty) return consultaCarteira.docs.first;

    return null;
  }

  Widget _construirTelaLogin(BuildContext context) {
    return Login(
      entrar: (cpf, pin) async {
        final cliente = await _executarComCarregamento(
          context,
          () => _servicoFirestore.autenticarCliente(
            cpf: cpf,
            pin: pin,
          ),
        );

        if (cliente != null && context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/painel',
            (_) => false,
            arguments: cliente,
          );
        }
      },
      esquecerSenha: () {
        Navigator.pushNamed(context, '/recuperar-acesso');
      },
      criarConta: () {
        Navigator.pushNamed(context, '/cadastro');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BlockPay EDU',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0B0E17),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF151A26),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => TelaBoasVindas(
              iniciarSimulacao: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
        '/login': (context) => _construirTelaLogin(context),
        '/painel': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! ClienteModelo) {
            return _construirTelaLogin(context);
          }

          return StreamBuilder<ClienteModelo>(
            stream: FirebaseFirestore.instance
                .collection('clientes')
                .doc(args.cpf)
                .snapshots()
                .map((doc) {
              final dados = doc.data();
              return dados != null ? ClienteModelo.deMapa(dados) : args;
            }),
            builder: (context, snapshot) {
              final clienteAtual = snapshot.data ?? args;
              final ultimaTx = clienteAtual.ultimaTransacaoCripto;

              String descricaoAtividade = 'Bônus de cadastro';
              String valorAtividade =
                  '+${_formatarMoedaBr(clienteAtual.saldoBrl)}';
              bool atividadePositiva = true;

              if (ultimaTx != null) {
                final tipo = ultimaTx['tipo']?.toString() ?? 'envio';
                final ativo = ultimaTx['ativo']?.toString() ?? 'BTC';
                final qtd = (ultimaTx['quantidade'] as num?)?.toDouble() ?? 0.0;
                final qtdStr = qtd.toString().replaceAll('.', ',');

                if (tipo == 'recebimento') {
                  descricaoAtividade = 'Recebimento de $ativo';
                  valorAtividade = '+$qtdStr $ativo';
                  atividadePositiva = true;
                } else {
                  descricaoAtividade = 'Transferência de $ativo';
                  valorAtividade = '-$qtdStr $ativo';
                  atividadePositiva = false;
                }
              }

              return Dashboard(
                iniciaisUsuario: _extrairIniciais(clienteAtual.nome),
                saldoBrl: clienteAtual.saldoBrl,
                quantidadeBtc: clienteAtual.saldoBtc,
                quantidadeEth: clienteAtual.saldoEth,
                descricaoUltimaAtividade: descricaoAtividade,
                valorUltimaAtividadeFormatado: valorAtividade,
                atividadePositiva: atividadePositiva,
                aoClicarPerfil: () {
                  Navigator.pushNamed(
                    context,
                    '/editar-conta',
                    arguments: clienteAtual,
                  );
                },
                aoClicarSair: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                },
                aoClicarVerTodas: () =>
                    _avisarTelaEmBreve(context, 'Histórico'),
                aoClicarTransferir: () {
                  Navigator.pushNamed(
                    context,
                    '/transferir-cripto',
                    arguments: clienteAtual,
                  );
                },
                aoClicarBlockchain: () {
                  Navigator.pushNamed(
                    context,
                    '/status-blockchain',
                    arguments: {
                      'cliente': clienteAtual,
                      'animar': false,
                    },
                  );
                },
                aoClicarInicio: () {},
                aoClicarMercado: () => _avisarTelaEmBreve(context, 'Mercado'),
                aoClicarPix: () => _avisarTelaEmBreve(context, 'Pix'),
                aoClicarHistorico: () =>
                    _avisarTelaEmBreve(context, 'Histórico'),
              );
            },
          );
        },
        '/transferir-cripto': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! ClienteModelo) {
            return _construirTelaLogin(context);
          }

          return TransferirCripto(
            iniciaisUsuario: _extrairIniciais(args.nome),
            saldoBtc: args.saldoBtc,
            saldoEth: args.saldoEth,
            emailRemetente: args.email,
            cpfRemetente: args.cpf,
            aoTransferir: (destinatario, ativo, quantidade) async {
              final firestore = FirebaseFirestore.instance;

              // 1. Verifica se o destinatario realmente existe no Firestore
              final docDestinatario =
                  await _buscarDestinatarioCadastrado(firestore, destinatario);

              if (docDestinatario == null) {
                return 'Usuário não encontrado. Só é possível enviar para usuários cadastrados no BlockPay.';
              }

              if (docDestinatario.id == args.cpf) {
                return 'Você não pode transferir para sua própria conta.';
              }

              final dadosDest =
                  (docDestinatario.data() as Map<String, dynamic>?) ?? {};
              if (dadosDest['ativo'] == false) {
                return 'A conta deste destinatário está inativa.';
              }

              // 2. Calcula os novos saldos do remetente e do destinatario
              final hashGerada = _gerarHashBlockchain();
              final campoSaldo = ativo == 'BTC' ? 'saldoBtc' : 'saldoEth';
              final saldoPadrao = ativo == 'BTC' ? 0.034 : 0.25;

              final saldoAnteriorRemetente =
                  ativo == 'BTC' ? args.saldoBtc : args.saldoEth;
              final novoSaldoRemetente = double.parse(
                (saldoAnteriorRemetente - quantidade)
                    .clamp(0.0, double.infinity)
                    .toStringAsFixed(8),
              );

              final saldoAnteriorDestinatario =
                  (dadosDest[campoSaldo] as num?)?.toDouble() ?? saldoPadrao;
              final novoSaldoDestinatario = double.parse(
                (saldoAnteriorDestinatario + quantidade).toStringAsFixed(8),
              );

              final dadosTransacaoEnvio = {
                'tipo': 'envio',
                'hash': hashGerada,
                'ativo': ativo,
                'quantidade': quantidade,
                'destinatario': destinatario,
                'nomeDestinatario': dadosDest['nome'] ?? destinatario,
                'status': 'Confirmado na blockchain',
              };

              final dadosTransacaoRecebimento = {
                'tipo': 'recebimento',
                'hash': hashGerada,
                'ativo': ativo,
                'quantidade': quantidade,
                'remetente': args.email,
                'nomeRemetente': args.nome,
                'status': 'Confirmado na blockchain',
              };

              // 3. Executa atualizacao atomica no Firestore
              final lote = firestore.batch();

              lote.update(firestore.collection('clientes').doc(args.cpf), {
                campoSaldo: novoSaldoRemetente,
                'ultimaTransacaoCripto': dadosTransacaoEnvio,
              });

              lote.update(docDestinatario.reference, {
                campoSaldo: novoSaldoDestinatario,
                'ultimaTransacaoCripto': dadosTransacaoRecebimento,
              });

              lote.set(firestore.collection('transacoes').doc(), {
                'cpfRemetente': args.cpf,
                'cpfDestinatario': docDestinatario.id,
                ...dadosTransacaoEnvio,
                'criadoEm': FieldValue.serverTimestamp(),
              });

              await lote.commit();

              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/status-blockchain',
                  arguments: {
                    'cliente': args,
                    'transacao': dadosTransacaoEnvio,
                    'animar': true,
                  },
                );
              }
              return null;
            },
            aoClicarPerfil: () {
              Navigator.pushNamed(
                context,
                '/editar-conta',
                arguments: args,
              );
            },
            aoClicarInicio: () => Navigator.pop(context),
            aoClicarMercado: () => _avisarTelaEmBreve(context, 'Mercado'),
            aoClicarPix: () => _avisarTelaEmBreve(context, 'Pix'),
            aoClicarHistorico: () => _avisarTelaEmBreve(context, 'Histórico'),
          );
        },
        '/status-blockchain': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _construirTelaLogin(context);
          }

          final cliente = args['cliente'] as ClienteModelo;
          final animar = args['animar'] as bool? ?? false;
          final transacao = (args['transacao'] as Map<String, dynamic>?) ??
              cliente.ultimaTransacaoCripto;

          return StatusBlockchain(
            iniciaisUsuario: _extrairIniciais(cliente.nome),
            hashTransacao: transacao?['hash']?.toString() ?? '',
            ativo: transacao?['ativo']?.toString(),
            quantidade: (transacao?['quantidade'] as num?)?.toDouble(),
            destinatario: transacao?['destinatario']?.toString(),
            animarConfirmacao: animar,
            aoClicarPerfil: () {
              Navigator.pushNamed(
                context,
                '/editar-conta',
                arguments: cliente,
              );
            },
            aoClicarInicio: () => Navigator.pop(context),
            aoClicarMercado: () => _avisarTelaEmBreve(context, 'Mercado'),
            aoClicarPix: () => _avisarTelaEmBreve(context, 'Pix'),
            aoClicarHistorico: () => _avisarTelaEmBreve(context, 'Histórico'),
          );
        },
        '/editar-conta': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! ClienteModelo) {
            return _construirTelaLogin(context);
          }

          return EditarConta(
            nome: args.nome,
            cpf: args.cpf,
            email: args.email,
            telefone: args.telefone,
            aoClicarAlterarSenha: () {
              Navigator.pushNamed(
                context,
                '/alterar-senha',
                arguments: {'cpf': args.cpf, 'exigirSenhaAtual': true},
              );
            },
            salvarAlteracoes: (novoNome, novoEmail, novoTelefone) async {
              var salvo = false;
              await _executarComCarregamento(context, () async {
                await FirebaseFirestore.instance
                    .collection('clientes')
                    .doc(args.cpf)
                    .update({
                  'nome': novoNome,
                  'email': novoEmail,
                  'telefone': novoTelefone,
                });
                salvo = true;
              });

              if (salvo && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados da conta atualizados com sucesso!'),
                    backgroundColor: Color(0xFF00C853),
                  ),
                );
                Navigator.pop(context);
              }
            },
            aoClicarInicio: () => Navigator.pop(context),
            aoClicarMercado: () => _avisarTelaEmBreve(context, 'Mercado'),
            aoClicarPix: () => _avisarTelaEmBreve(context, 'Pix'),
            aoClicarHistorico: () => _avisarTelaEmBreve(context, 'Histórico'),
          );
        },
        '/cadastro': (context) => CadastroCliente(
              cadastrar: (nome, cpf, email, pin) async {
                final clienteCriado = await _executarComCarregamento(
                  context,
                  () => _servicoFirestore.cadastrarCliente(
                    nome: nome,
                    cpf: cpf,
                    email: email,
                    pin: pin,
                  ),
                );

                if (clienteCriado != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Conta criada com sucesso! Você recebeu R\$ 10.000,00 fictícios.',
                      ),
                      backgroundColor: Color(0xFF00C853),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            ),
        '/recuperar-acesso': (context) => RecuperarAcesso(
              enviarSolicitacao: (cpf, email) async {
                final codigoGerado = await _executarComCarregamento(
                  context,
                  () => _servicoFirestore.solicitarCodigoRecuperacao(
                    cpf: cpf,
                    email: email,
                  ),
                );

                if (codigoGerado != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 10),
                      content: Text(
                        'Código de verificação enviado para $email.',
                      ),
                      backgroundColor: const Color(0xFF151A26),
                    ),
                  );

                  Navigator.pushNamed(
                    context,
                    '/validar-codigo',
                    arguments: {'cpf': cpf, 'email': email},
                  );
                }
              },
            ),
        '/validar-codigo': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, String>) {
            return _construirTelaLogin(context);
          }

          final cpf = args['cpf']!;
          final email = args['email']!;

          return ValidarCodigo(
            cpf: cpf,
            email: email,
            validarCodigo: (codigo) async {
              var validado = false;
              await _executarComCarregamento(context, () async {
                await _servicoFirestore.validarCodigoRecuperacao(
                  cpf: cpf,
                  codigo: codigo,
                );
                validado = true;
              });

              if (validado && context.mounted) {
                Navigator.pushNamed(
                  context,
                  '/alterar-senha',
                  arguments: {'cpf': cpf, 'exigirSenhaAtual': false},
                );
              }
            },
            reenviarCodigo: () async {
              final novoCodigo = await _executarComCarregamento(
                context,
                () => _servicoFirestore.solicitarCodigoRecuperacao(
                  cpf: cpf,
                  email: email,
                ),
              );

              if (novoCodigo != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 10),
                    content: Text(
                      'Novo código de verificação enviado para $email.',
                    ),
                    backgroundColor: const Color(0xFF151A26),
                  ),
                );
              }
            },
          );
        },
        '/alterar-senha': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _construirTelaLogin(context);
          }

          final cpf = args['cpf'] as String;
          final exigirSenhaAtual = args['exigirSenhaAtual'] as bool? ?? false;

          return AlterarSenha(
            cpf: cpf,
            exigirSenhaAtual: exigirSenhaAtual,
            salvarSenha: (senhaAtual, novaSenha) async {
              var salva = false;
              await _executarComCarregamento(context, () async {
                await _servicoFirestore.redefinirSenha(
                  cpf: cpf,
                  novaSenha: novaSenha,
                  senhaAtual: senhaAtual,
                );
                salva = true;
              });

              if (salva && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      exigirSenhaAtual
                          ? 'Senha alterada com sucesso!'
                          : 'Senha alterada com sucesso! Faça login.',
                    ),
                    backgroundColor: const Color(0xFF00C853),
                  ),
                );
                if (exigirSenhaAtual) {
                  Navigator.pop(context);
                } else {
                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                }
              }
            },
          );
        },
      },
    );
  }
}
