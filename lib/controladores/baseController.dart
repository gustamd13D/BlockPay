import 'dart:async';
import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import 'routerController.dart';

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
          color: CoresApp.cianoPrimario,
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
            backgroundColor: CoresApp.vermelhoNegativo,
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
        backgroundColor: CoresApp.superficie,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Abre a tela de edicao de conta do usuario logado
  void abrirPerfil(BuildContext context, ClienteModelo cliente) {
    if (ModalRoute.of(context)?.settings.name == RotasApp.editarConta) {
      return;
    }
    Navigator.pushNamed(
      context,
      RotasApp.editarConta,
      arguments: cliente,
    );
  }

  /// Encerra a sessao atual e retorna para a tela de login
  void sairDaConta(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RotasApp.login,
      (_) => false,
    );
  }

  /// Gerencia a navegacao padrao das abas (0: Inicio, 1: Mercado, 2: Pix, 3: Historico)
  void navegarPeloMenu(
    BuildContext context,
    ClienteModelo cliente,
    int indiceAba,
  ) {
    final rotaAtual = ModalRoute.of(context)?.settings.name;

    switch (indiceAba) {
      case 0:
        if (rotaAtual == RotasApp.painel) return;
        Navigator.popUntil(context, ModalRoute.withName(RotasApp.painel));
        break;

      case 1:
        if (rotaAtual == RotasApp.mercadoCripto) return;
        if (rotaAtual == RotasApp.painel) {
          Navigator.pushNamed(
            context,
            RotasApp.mercadoCripto,
            arguments: cliente,
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            RotasApp.mercadoCripto,
            arguments: cliente,
          );
        }
        break;

      case 2:
        if (rotaAtual == RotasApp.depositarComPix) return;
        if (rotaAtual == RotasApp.painel) {
          Navigator.pushNamed(
            context,
            RotasApp.depositarComPix,
            arguments: cliente,
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            RotasApp.depositarComPix,
            arguments: cliente,
          );
        }
        break;

      case 3:
        Navigator.pushNamed(
          context,
          RotasApp.historico,
          arguments: cliente,
        );
        break;
    }
  }
}
