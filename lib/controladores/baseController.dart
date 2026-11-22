import 'dart:async';
import 'package:flutter/material.dart';

abstract class BaseController {
  /// Exibe um indicador de carregamento modal enquanto executa uma operacao assincrona
  Future<T?> executarComCarregamento<T>(
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

  /// Extrai as iniciais do nome do usuario para o avatar
  String extrairIniciais(String nomeCompleto) {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'BP';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  /// Formata valores monetarios no padrao brasileiro (R$ 10.000,00)
  String formatarMoedaBr(double valor) {
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

  /// Exibe feedback padrao para modulos ainda em desenvolvimento
  void avisarTelaEmBreve(BuildContext context, String nomeTela) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tela de $nomeTela em desenvolvimento.'),
        backgroundColor: const Color(0xFF151A26),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
