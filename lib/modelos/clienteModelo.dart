import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados do cliente armazenado na colecao 'clientes'
class ClienteModelo {
  final String nome;
  final String cpf;
  final String email;
  final String pinHash;
  final double saldoBrl;
  final DateTime? criadoEm;
  final bool ativo;

  const ClienteModelo({
    required this.nome,
    required this.cpf,
    required this.email,
    required this.pinHash,
    required this.saldoBrl,
    this.criadoEm,
    this.ativo = true,
  });

  /// Converte o objeto Dart para o formato aceito pelo Firestore
  Map<String, dynamic> paraMapa({bool incluirDataServidor = false}) {
    return {
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'pinHash': pinHash,
      'saldoBrl': saldoBrl,
      'ativo': ativo,
      if (incluirDataServidor) 'criadoEm': FieldValue.serverTimestamp(),
    };
  }

  /// Reconstroi o objeto ClienteModelo a partir de um documento do Firestore
  factory ClienteModelo.deMapa(Map<String, dynamic> mapa) {
    final timestamp = mapa['criadoEm'];
    return ClienteModelo(
      nome: mapa['nome'] as String? ?? '',
      cpf: mapa['cpf'] as String? ?? '',
      email: mapa['email'] as String? ?? '',
      pinHash: mapa['pinHash'] as String? ?? '',
      saldoBrl: (mapa['saldoBrl'] as num?)?.toDouble() ?? 0.0,
      criadoEm: timestamp is Timestamp ? timestamp.toDate() : null,
      ativo: mapa['ativo'] as bool? ?? true,
    );
  }
}
