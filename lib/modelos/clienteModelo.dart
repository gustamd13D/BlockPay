import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteModelo {
  final String nome;
  final String cpf;
  final String email;
  final String pinHash;
  final String telefone;
  final double saldoBrl;
  final double saldoBtc;
  final double saldoEth;
  final double saldoSol;
  final double saldoAda;
  final Map<String, dynamic>? ultimaTransacaoCripto;
  final bool ativo;

  const ClienteModelo({
    required this.nome,
    required this.cpf,
    required this.email,
    this.pinHash = '',
    this.telefone = '',
    this.saldoBrl = 10000.0,
    this.saldoBtc = 0.034,
    this.saldoEth = 0.25,
    this.saldoSol = 0.0,
    this.saldoAda = 0.0,
    this.ultimaTransacaoCripto,
    this.ativo = true,
  });

  factory ClienteModelo.deMapa(Map<String, dynamic> mapa) {
    return ClienteModelo(
      nome: mapa['nome']?.toString() ?? '',
      cpf: mapa['cpf']?.toString() ?? '',
      email: mapa['email']?.toString() ?? '',
      pinHash: mapa['pinHash']?.toString() ?? '',
      telefone: mapa['telefone']?.toString() ?? '',
      saldoBrl: (mapa['saldoBrl'] as num?)?.toDouble() ?? 10000.0,
      saldoBtc: (mapa['saldoBtc'] as num?)?.toDouble() ?? 0.034,
      saldoEth: (mapa['saldoEth'] as num?)?.toDouble() ?? 0.25,
      saldoSol: (mapa['saldoSol'] as num?)?.toDouble() ?? 0.0,
      saldoAda: (mapa['saldoAda'] as num?)?.toDouble() ?? 0.0,
      ultimaTransacaoCripto:
          mapa['ultimaTransacaoCripto'] as Map<String, dynamic>?,
      ativo: mapa['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> paraMapa({bool incluirDataServidor = false}) {
    return {
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'pinHash': pinHash,
      'telefone': telefone,
      'saldoBrl': saldoBrl,
      'saldoBtc': saldoBtc,
      'saldoEth': saldoEth,
      'saldoSol': saldoSol,
      'saldoAda': saldoAda,
      if (ultimaTransacaoCripto != null)
        'ultimaTransacaoCripto': ultimaTransacaoCripto,
      'ativo': ativo,
      if (incluirDataServidor) ...{
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
    };
  }
}
