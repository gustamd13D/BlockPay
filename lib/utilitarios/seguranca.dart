import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitario para protecao de dados sensiveis antes de enviar ao banco
abstract class SegurancaUtil {
  /// Gera o hash SHA-256 do PIN para nao salvar senha em texto puro no Firestore
  static String gerarHashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
