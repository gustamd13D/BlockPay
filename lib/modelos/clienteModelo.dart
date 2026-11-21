import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados do cliente armazenado na colecao 'clientes'
class ClienteModelo {
  final String nome;
  final String cpf;
  final String email;
  final String telefone;
  final String pinHash;
  final double saldoBrl;
  final double saldoBtc;
  final double saldoEth;
  final Map<String, dynamic>? ultimaTransacaoCripto;
  final DateTime? criadoEm;
  final bool ativo;

  const ClienteModelo({
    required this.nome,
    required this.cpf,
    required this.email,
    this.telefone = '',
    required this.pinHash,
    required this.saldoBrl,
    this.saldoBtc = 0.034,
    this.saldoEth = 0.25,
    this.ultimaTransacaoCripto,
    this.criadoEm,
    this.ativo = true,
  });

  /// Converte o objeto Dart para o formato aceito pelo Firestore
  Map<String, dynamic> paraMapa({bool incluirDataServidor = false}) {
    return {
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'telefone': telefone,
      'pinHash': pinHash,
      'saldoBrl': saldoBrl,
      'saldoBtc': saldoBtc,
      'saldoEth': saldoEth,
      if (ultimaTransacaoCripto != null)
        'ultimaTransacaoCripto': ultimaTransacaoCripto,
      'ativo': ativo,
      if (incluirDataServidor) 'criadoEm': FieldValue.serverTimestamp(),
    };
  }

  /// Reconstroi o objeto ClienteModelo a partir de um documento do Firestore
  factory ClienteModelo.deMapa(Map<String, dynamic> mapa) {
    final timestamp = mapa['criadoEm'];
    final ultimaTx = mapa['ultimaTransacaoCripto'];
    return ClienteModelo(
      nome: mapa['nome'] as String? ?? '',
      cpf: mapa['cpf'] as String? ?? '',
      email: mapa['email'] as String? ?? '',
      telefone: mapa['telefone'] as String? ?? '',
      pinHash: mapa['pinHash'] as String? ?? '',
      saldoBrl: (mapa['saldoBrl'] as num?)?.toDouble() ?? 0.0,
      saldoBtc: (mapa['saldoBtc'] as num?)?.toDouble() ?? 0.034,
      saldoEth: (mapa['saldoEth'] as num?)?.toDouble() ?? 0.25,
      ultimaTransacaoCripto: ultimaTx is Map<String, dynamic> ? ultimaTx : null,
      criadoEm: timestamp is Timestamp ? timestamp.toDate() : null,
      ativo: mapa['ativo'] as bool? ?? true,
    );
  }
}
