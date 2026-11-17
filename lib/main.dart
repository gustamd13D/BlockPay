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

Future<void> main() async {
  // Garante que os canais nativos estejam prontos antes de iniciar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(BlockPayApp());
}

class BlockPayApp extends StatelessWidget {
  final ServicoFirestore _servicoFirestore = ServicoFirestore();

  BlockPayApp({super.key});

  /// Exibe um indicador de carregamento sobre a tela enquanto consulta o Firestore
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

  /// Extrai as iniciais do primeiro e ultimo nome para o avatar do topo
  String _extrairIniciais(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'BP';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
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

  /// Constroi a tela de Login com os callbacks conectados ao Firestore
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

              return Dashboard(
                iniciaisUsuario: _extrairIniciais(clienteAtual.nome),
                saldoBrl: clienteAtual.saldoBrl,
                aoClicarPerfil: () {
                  Navigator.pushNamed(
                    context,
                    '/editar-conta',
                    arguments: clienteAtual,
                  );
                },
                aoClicarVerTodas: () =>
                    _avisarTelaEmBreve(context, 'Histórico'),
                aoClicarTransferir: () =>
                    _avisarTelaEmBreve(context, 'Transferência'),
                aoClicarBlockchain: () =>
                    _avisarTelaEmBreve(context, 'Blockchain'),
                aoClicarInicio: () {},
                aoClicarMercado: () => _avisarTelaEmBreve(context, 'Mercado'),
                aoClicarPix: () => _avisarTelaEmBreve(context, 'Pix'),
                aoClicarHistorico: () =>
                    _avisarTelaEmBreve(context, 'Histórico'),
              );
            },
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
