import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/clienteModelo.dart';
import '../utilitarios/seguranca.dart';

typedef MapaDados = Map<String, dynamic>;

/// Excecao personalizada para exibir mensagens amigaveis na interface
class ExcecaoAutenticacao implements Exception {
  final String mensagem;
  const ExcecaoAutenticacao(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Servico central de acesso ao Cloud Firestore do BlockPay
class ServicoFirestore {
  final FirebaseFirestore _banco;

  static const String colecaoClientes = 'clientes';
  static const String subcolecaoCarteira = 'carteira';
  static const String subcolecaoTransacoes = 'transacoes';
  static const double saldoInicialSimulacao = 10000.0;

  ServicoFirestore({FirebaseFirestore? banco})
      : _banco = banco ?? FirebaseFirestore.instance;

  DocumentReference<MapaDados> _referenciaCliente(String cpf) {
    return _banco.collection(colecaoClientes).doc(cpf);
  }

  /// Cadastra um novo cliente usando transacao atomica e cria o historico inicial
  Future<ClienteModelo> cadastrarCliente({
    required String nome,
    required String cpf,
    required String email,
    required String pin,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final docCliente = _referenciaCliente(cpfLimpo);

    final novoCliente = ClienteModelo(
      nome: nome.trim(),
      cpf: cpfLimpo,
      email: email.trim().toLowerCase(),
      pinHash: SegurancaUtil.gerarHashPin(pin),
      saldoBrl: saldoInicialSimulacao,
    );

    try {
      await _banco.runTransaction((transacao) async {
        final snapshot = await transacao.get(docCliente);

        if (snapshot.exists) {
          throw const ExcecaoAutenticacao(
            'Este CPF já possui uma conta cadastrada.',
          );
        }

        transacao.set(
          docCliente,
          novoCliente.paraMapa(incluirDataServidor: true),
        );

        final docTransacaoInicial =
            docCliente.collection(subcolecaoTransacoes).doc();

        transacao.set(docTransacaoInicial, {
          'tipo': 'BONUS_INICIAL',
          'descricao': 'Saldo inicial educativo BlockPay EDU',
          'valorBrl': saldoInicialSimulacao,
          'dataHora': FieldValue.serverTimestamp(),
        });
      });

      return novoCliente;
    } on ExcecaoAutenticacao {
      rethrow;
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao conectar com o servidor (${erro.code}). Tente novamente.',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Não foi possível concluir o cadastro agora.',
      );
    }
  }

  /// Valida CPF e PIN no Firestore e retorna os dados do cliente autenticado
  Future<ClienteModelo> autenticarCliente({
    required String cpf,
    required String pin,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    try {
      final snapshot = await _referenciaCliente(cpfLimpo).get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw const ExcecaoAutenticacao('CPF não encontrado. Crie uma conta.');
      }

      final cliente = ClienteModelo.deMapa(snapshot.data()!);

      if (!cliente.ativo) {
        throw const ExcecaoAutenticacao('Esta conta está desativada.');
      }

      final hashInformado = SegurancaUtil.gerarHashPin(pin);
      if (cliente.pinHash != hashInformado) {
        throw const ExcecaoAutenticacao('PIN incorreto. Tente novamente.');
      }

      return cliente;
    } on ExcecaoAutenticacao {
      rethrow;
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Falha na comunicação com o banco (${erro.code}).',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Erro inesperado ao realizar login.',
      );
    }
  }

  /// Etapa 1: Confere CPF e e-mail e gera um codigo de 6 digitos valido por 15 min
  Future<String> solicitarCodigoRecuperacao({
    required String cpf,
    required String email,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final emailNormalizado = email.trim().toLowerCase();
    final docCliente = _referenciaCliente(cpfLimpo);

    try {
      final snapshot = await docCliente.get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw const ExcecaoAutenticacao(
          'CPF ou e-mail não correspondem a uma conta ativa.',
        );
      }

      final cliente = ClienteModelo.deMapa(snapshot.data()!);

      if (cliente.email.toLowerCase() != emailNormalizado) {
        throw const ExcecaoAutenticacao(
          'CPF ou e-mail não correspondem a uma conta ativa.',
        );
      }

      final aleatorio = Random.secure();
      final codigo = (100000 + aleatorio.nextInt(900000)).toString();
      final expiracao = DateTime.now().add(const Duration(minutes: 15));

      await docCliente.update({
        'codigoRecuperacao': codigo,
        'expiracaoCodigo': Timestamp.fromDate(expiracao),
      });

      return codigo;
    } on ExcecaoAutenticacao {
      rethrow;
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao solicitar recuperação (${erro.code}).',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Não foi possível processar a solicitação agora.',
      );
    }
  }

  /// Etapa 2: Valida o codigo de 6 digitos salvo no documento do cliente
  Future<void> validarCodigoRecuperacao({
    required String cpf,
    required String codigo,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    try {
      final snapshot = await _referenciaCliente(cpfLimpo).get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw const ExcecaoAutenticacao('Conta não encontrada.');
      }

      final dados = snapshot.data()!;
      final codigoSalvo = dados['codigoRecuperacao'] as String?;
      final expiracao = dados['expiracaoCodigo'];

      if (codigoSalvo == null || codigoSalvo != codigo.trim()) {
        throw const ExcecaoAutenticacao(
          'Código incorreto. Verifique e tente novamente.',
        );
      }

      if (expiracao is Timestamp &&
          DateTime.now().isAfter(expiracao.toDate())) {
        throw const ExcecaoAutenticacao(
          'Este código expirou. Solicite um novo código.',
        );
      }
    } on ExcecaoAutenticacao {
      rethrow;
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao validar código (${erro.code}).',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Erro inesperado ao validar o código.',
      );
    }
  }

  /// Etapa 3: Atualiza o hash da senha/PIN e limpa o codigo temporario
  Future<void> redefinirSenha({
    required String cpf,
    required String novaSenha,
    String? senhaAtual,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final docCliente = _referenciaCliente(cpfLimpo);

    try {
      final snapshot = await docCliente.get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw const ExcecaoAutenticacao('Conta não encontrada.');
      }

      // Se a senha atual foi informada (modo configuracoes), valida antes de trocar
      if (senhaAtual != null) {
        final cliente = ClienteModelo.deMapa(snapshot.data()!);
        final hashAtual = SegurancaUtil.gerarHashPin(senhaAtual);
        if (cliente.pinHash != hashAtual) {
          throw const ExcecaoAutenticacao('A senha atual está incorreta.');
        }
      }

      await docCliente.update({
        'pinHash': SegurancaUtil.gerarHashPin(novaSenha),
        'codigoRecuperacao': FieldValue.delete(),
        'expiracaoCodigo': FieldValue.delete(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on ExcecaoAutenticacao {
      rethrow;
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao salvar nova senha (${erro.code}).',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Não foi possível salvar a nova senha.',
      );
    }
  }
}
