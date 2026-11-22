import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/clienteModelo.dart';
import '../utilitarios/seguranca.dart';
import 'servicoBlockchain.dart';

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
  final ServicoBlockchain _servicoBlockchain;

  static const String colecaoClientes = 'clientes';
  static const String colecaoAdmins = 'admins';
  static const String colecaoTransacoes = 'transacoes';
  static const String subcolecaoCarteira = 'carteira';
  static const String subcolecaoTransacoes = 'transacoes';
  static const double saldoInicialSimulacao = 10000.0;

  ServicoFirestore({
    FirebaseFirestore? banco,
    ServicoBlockchain? servicoBlockchain,
  })  : _banco = banco ?? FirebaseFirestore.instance,
        _servicoBlockchain = servicoBlockchain ?? ServicoBlockchain.instancia;

  DocumentReference<MapaDados> _referenciaCliente(String cpf) {
    return _banco.collection(colecaoClientes).doc(cpf);
  }

  /// Busca o documento do usuario na colecao clientes e, se nao existir, em admins
  Future<DocumentSnapshot<MapaDados>?> _buscarSnapshotUsuario(
    String cpfLimpo,
  ) async {
    final snapshotCliente = await _referenciaCliente(cpfLimpo).get();
    if (snapshotCliente.exists && snapshotCliente.data() != null) {
      return snapshotCliente;
    }

    final snapshotAdmin =
        await _banco.collection(colecaoAdmins).doc(cpfLimpo).get();
    if (snapshotAdmin.exists && snapshotAdmin.data() != null) {
      return snapshotAdmin;
    }

    return null;
  }

  /// Cadastra um novo cliente com status pendente e registra hash no bloco atual
  Future<ClienteModelo> cadastrarCliente({
    required String nome,
    required String cpf,
    required String email,
    required String pin,
    bool isAdmin = false,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final docCliente = _referenciaCliente(cpfLimpo);

    final novoCliente = ClienteModelo(
      nome: nome.trim(),
      cpf: cpfLimpo,
      email: email.trim().toLowerCase(),
      pinHash: SegurancaUtil.gerarHashPin(pin),
      saldoBrl: saldoInicialSimulacao,
      status: 'pendente',
      ativo: true,
      isAdmin: isAdmin,
    );

    try {
      await _banco.runTransaction((transacao) async {
        // 1. Todas as leituras primeiro
        final snapshot = await transacao.get(docCliente);
        final prepBloco =
            await _servicoBlockchain.prepararRegistroNaTransacao(transacao);

        if (snapshot.exists) {
          throw const ExcecaoAutenticacao(
            'Este CPF já possui uma conta cadastrada.',
          );
        }

        // 2. Calculo da hash derivada do bloco ativo
        final registroTx = _servicoBlockchain.calcularRegistroTransacao(
          prepBloco,
          resumoDados: 'BONUS_CADASTRO|$cpfLimpo|$saldoInicialSimulacao',
        );

        final mapaCliente = novoCliente.paraMapa(incluirDataServidor: true);
        mapaCliente['status'] = 'pendente';
        mapaCliente['ativo'] = true;
        mapaCliente['isAdmin'] = isAdmin;
        mapaCliente['tipo'] = isAdmin ? 'admin' : 'cliente';

        // 3. Todas as escritas depois
        transacao.set(docCliente, mapaCliente);

        final docTransacaoSub =
            docCliente.collection(subcolecaoTransacoes).doc();
        transacao.set(docTransacaoSub, {
          'tipo': 'BONUS_INICIAL',
          'descricao': 'Saldo inicial educativo BlockPay EDU',
          'valorBrl': saldoInicialSimulacao,
          'hash': registroTx.hashTransacao,
          'indiceBloco': registroTx.indiceBloco,
          'hashBloco': registroTx.hashBloco,
          'dataHora': FieldValue.serverTimestamp(),
        });

        final docTransacaoGlobal = _banco.collection(colecaoTransacoes).doc();
        transacao.set(docTransacaoGlobal, {
          'cpfCliente': cpfLimpo,
          'tipo': 'deposito',
          'titulo': 'Bônus de cadastro',
          'valorBrl': saldoInicialSimulacao,
          'status': 'Confirmada',
          'hash': registroTx.hashTransacao,
          'indiceBloco': registroTx.indiceBloco,
          'hashBloco': registroTx.hashBloco,
          'hashBlocoAnterior': registroTx.hashBlocoAnterior,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        _servicoBlockchain.aplicarEscritaNaTransacao(
          transacao,
          prepBloco,
          registroTx,
        );
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

  /// Registra um deposito via Pix creditando o saldo BRL e gerando hash na blockchain
  Future<RegistroTransacaoBlockchain> registrarDepositoPix({
    required String cpf,
    required double valorBrl,
    String titulo = 'Depósito Pix',
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final docCliente = _referenciaCliente(cpfLimpo);

    try {
      late RegistroTransacaoBlockchain registroGerado;

      await _banco.runTransaction((transacao) async {
        // 1. Leituras primeiro
        final snapshot = await transacao.get(docCliente);
        final prepBloco =
            await _servicoBlockchain.prepararRegistroNaTransacao(transacao);

        if (!snapshot.exists || snapshot.data() == null) {
          throw const ExcecaoAutenticacao('Conta do cliente não encontrada.');
        }

        final dados = snapshot.data()!;
        final saldoAtual = (dados['saldoBrl'] as num?)?.toDouble() ?? 0.0;
        final novoSaldo = double.parse(
          (saldoAtual + valorBrl).toStringAsFixed(2),
        );

        // 2. Calculo da hash derivada do bloco
        registroGerado = _servicoBlockchain.calcularRegistroTransacao(
          prepBloco,
          resumoDados: 'DEPOSITO_PIX|$cpfLimpo|$valorBrl',
        );

        // 3. Escritas depois
        transacao.update(docCliente, {
          'saldoBrl': novoSaldo,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });

        final docTransacaoGlobal = _banco.collection(colecaoTransacoes).doc();
        transacao.set(docTransacaoGlobal, {
          'cpfCliente': cpfLimpo,
          'tipo': 'deposito',
          'titulo': titulo,
          'valorBrl': valorBrl,
          'status': 'Confirmada',
          'hash': registroGerado.hashTransacao,
          'indiceBloco': registroGerado.indiceBloco,
          'hashBloco': registroGerado.hashBloco,
          'hashBlocoAnterior': registroGerado.hashBlocoAnterior,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        _servicoBlockchain.aplicarEscritaNaTransacao(
          transacao,
          prepBloco,
          registroGerado,
        );
      });

      return registroGerado;
    } on ExcecaoAutenticacao {
      rethrow;
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao registrar depósito Pix (${erro.code}).',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Não foi possível processar o depósito Pix agora.',
      );
    }
  }

  /// Valida CPF e PIN no Firestore, ativa conta pendente no primeiro acesso e registra ultimo acesso
  Future<ClienteModelo> autenticarCliente({
    required String cpf,
    required String pin,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    try {
      final snapshot = await _buscarSnapshotUsuario(cpfLimpo);

      if (snapshot == null || snapshot.data() == null) {
        throw const ExcecaoAutenticacao('CPF não encontrado. Crie uma conta.');
      }

      final dadosUsuario = snapshot.data()!;
      final encontradoNaColecaoAdmins =
          snapshot.reference.parent.id == colecaoAdmins;

      final mapaNormalizado = <String, dynamic>{
        ...dadosUsuario,
        'cpf': dadosUsuario['cpf'] ?? cpfLimpo,
        if (encontradoNaColecaoAdmins) 'isAdmin': true,
      };

      final cliente = ClienteModelo.deMapa(mapaNormalizado);
      final status =
          (dadosUsuario['status'] ?? 'ativo').toString().toLowerCase().trim();

      if (status == 'bloqueado') {
        throw const ExcecaoAutenticacao(
          'Esta conta está bloqueada. Entre em contato com o suporte.',
        );
      }

      if (!cliente.ativo) {
        throw const ExcecaoAutenticacao('Esta conta está desativada.');
      }

      final hashInformado = SegurancaUtil.gerarHashPin(pin);
      if (cliente.pinHash != hashInformado) {
        throw const ExcecaoAutenticacao('PIN incorreto. Tente novamente.');
      }

      // No primeiro acesso, promove o status de pendente para ativo
      final bool primeiroAcessoPendente = status == 'pendente';
      final atualizacoes = <String, dynamic>{
        'ultimoAcesso': FieldValue.serverTimestamp(),
        if (primeiroAcessoPendente) ...{
          'status': 'ativo',
          'ativo': true,
          'atualizadoEm': FieldValue.serverTimestamp(),
        },
      };

      try {
        await snapshot.reference.update(atualizacoes);
      } catch (_) {}

      if (primeiroAcessoPendente) {
        return ClienteModelo.deMapa({
          ...mapaNormalizado,
          'status': 'ativo',
          'ativo': true,
        });
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

  /// Stream em tempo real de todos os documentos da colecao clientes (uso Admin)
  Stream<QuerySnapshot<MapaDados>> streamClientes() {
    return _banco.collection(colecaoClientes).snapshots();
  }

  /// Stream em tempo real de todas as movimentacoes registradas (uso Admin)
  Stream<QuerySnapshot<MapaDados>> streamTransacoes() {
    return _banco.collection(colecaoTransacoes).snapshots();
  }

  /// Atualiza o status de um cliente ('ativo', 'pendente' ou 'bloqueado')
  Future<void> atualizarStatusCliente({
    required String cpf,
    required String novoStatus,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final statusNormalizado = novoStatus.toLowerCase().trim();

    try {
      await _referenciaCliente(cpfLimpo).update({
        'status': statusNormalizado,
        'ativo': statusNormalizado != 'bloqueado',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao atualizar status (${erro.code}).',
      );
    }
  }

  /// Exclui um usuario e suas subcolecoes (uso Admin)
  Future<void> excluirUsuario({required String cpf}) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final docUsuario = _referenciaCliente(cpfLimpo);

    try {
      final carteiraSnap =
          await docUsuario.collection(subcolecaoCarteira).get();
      for (final item in carteiraSnap.docs) {
        await item.reference.delete();
      }

      final transacoesSnap =
          await docUsuario.collection(subcolecaoTransacoes).get();
      for (final item in transacoesSnap.docs) {
        await item.reference.delete();
      }

      await docUsuario.delete();
    } on FirebaseException catch (erro) {
      throw ExcecaoAutenticacao(
        'Erro ao excluir usuário (${erro.code}).',
      );
    } catch (_) {
      throw const ExcecaoAutenticacao(
        'Não foi possível excluir o usuário agora.',
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

    try {
      final snapshot = await _buscarSnapshotUsuario(cpfLimpo);

      if (snapshot == null || snapshot.data() == null) {
        throw const ExcecaoAutenticacao(
          'CPF ou e-mail não correspondem a uma conta ativa.',
        );
      }

      final dados = snapshot.data()!;
      final cliente = ClienteModelo.deMapa({
        ...dados,
        'cpf': dados['cpf'] ?? cpfLimpo,
      });

      if (cliente.email.toLowerCase() != emailNormalizado) {
        throw const ExcecaoAutenticacao(
          'CPF ou e-mail não correspondem a uma conta ativa.',
        );
      }

      final aleatorio = Random.secure();
      final codigo = (100000 + aleatorio.nextInt(900000)).toString();
      final expiracao = DateTime.now().add(const Duration(minutes: 15));

      await snapshot.reference.update({
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

  /// Etapa 2: Valida o codigo de 6 digitos salvo no documento do usuario
  Future<void> validarCodigoRecuperacao({
    required String cpf,
    required String codigo,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    try {
      final snapshot = await _buscarSnapshotUsuario(cpfLimpo);

      if (snapshot == null || snapshot.data() == null) {
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

  /// Etapa 3: Atualiza o hash da senha/PIN e limpa o codigo temporario (clientes e admins)
  Future<void> redefinirSenha({
    required String cpf,
    required String novaSenha,
    String? senhaAtual,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    try {
      final snapshot = await _buscarSnapshotUsuario(cpfLimpo);

      if (snapshot == null || snapshot.data() == null) {
        throw const ExcecaoAutenticacao('Conta não encontrada.');
      }

      if (senhaAtual != null) {
        final dados = snapshot.data()!;
        final cliente = ClienteModelo.deMapa({
          ...dados,
          'cpf': dados['cpf'] ?? cpfLimpo,
        });
        final hashAtual = SegurancaUtil.gerarHashPin(senhaAtual);
        if (cliente.pinHash != hashAtual) {
          throw const ExcecaoAutenticacao('A senha atual está incorreta.');
        }
      }

      await snapshot.reference.update({
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
