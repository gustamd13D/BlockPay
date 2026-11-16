import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'servicos/servicoFirestore.dart';
import 'telas/boasvindas.dart';
import 'telas/login.dart';
import 'telas/cadastroCliente.dart';
import 'telas/recuperarAcesso.dart';
import 'telas/validarCodigo.dart';
import 'telas/alterarSenha.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bem-vindo, ${cliente.nome}! Saldo: R\$ ${cliente.saldoBrl.toStringAsFixed(2)}',
              ),
              backgroundColor: const Color(0xFF151A26),
            ),
          );
          // Quando criar a tela principal, navegue para o painel:
          // Navigator.pushNamedAndRemoveUntil(context, '/painel', (_) => false, arguments: cliente);
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
                  const SnackBar(
                    content: Text('Senha alterada com sucesso! Faça login.'),
                    backgroundColor: Color(0xFF00C853),
                  ),
                );
                // Limpa as telas intermediarias e retorna direto ao login
                Navigator.popUntil(context, ModalRoute.withName('/login'));
              }
            },
          );
        },
      },
    );
  }
}
