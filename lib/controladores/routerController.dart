import 'package:flutter/material.dart';
import 'alterarSenhaController.dart';
import 'boasVindasController.dart';
import 'cadastroClienteController.dart';
import 'comprarCriptoController.dart';
import 'dashboardController.dart';
import 'editarContaController.dart';
import 'loginController.dart';
import 'mercadoCriptoController.dart';
import 'recuperarAcessoController.dart';
import 'statusBlockchainController.dart';
import 'transferirCriptoController.dart';
import 'validarCodigoController.dart';

abstract class RotasApp {
  static const String boasVindas = '/';
  static const String login = '/login';
  static const String painel = '/painel';
  static const String mercadoCripto = '/mercado-cripto';
  static const String comprarCripto = '/comprar-cripto';
  static const String transferirCripto = '/transferir-cripto';
  static const String statusBlockchain = '/status-blockchain';
  static const String editarConta = '/editar-conta';
  static const String cadastro = '/cadastro';
  static const String recuperarAcesso = '/recuperar-acesso';
  static const String validarCodigo = '/validar-codigo';
  static const String alterarSenha = '/alterar-senha';
}

class RouterController {
  static final BoasVindasController _boasVindasController =
      BoasVindasController();
  static final LoginController _loginController = LoginController();
  static final CadastroClienteController _cadastroClienteController =
      CadastroClienteController();
  static final RecuperarAcessoController _recuperarAcessoController =
      RecuperarAcessoController();
  static final ValidarCodigoController _validarCodigoController =
      ValidarCodigoController();
  static final AlterarSenhaController _alterarSenhaController =
      AlterarSenhaController();
  static final DashboardController _dashboardController = DashboardController();
  static final MercadoCriptoController _mercadoCriptoController =
      MercadoCriptoController();
  static final ComprarCriptoController _comprarCriptoController =
      ComprarCriptoController();
  static final EditarContaController _editarContaController =
      EditarContaController();
  static final TransferirCriptoController _transferirCriptoController =
      TransferirCriptoController();
  static final StatusBlockchainController _statusBlockchainController =
      StatusBlockchainController();

  static Route<dynamic> gerarRota(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case RotasApp.boasVindas:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => _boasVindasController.construirTela(context),
        );

      case RotasApp.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => _loginController.construirTela(context),
        );

      case RotasApp.cadastro:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _cadastroClienteController.construirTela(context),
        );

      case RotasApp.recuperarAcesso:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _recuperarAcessoController.construirTela(context),
        );

      case RotasApp.validarCodigo:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _validarCodigoController.construirTela(context, args),
        );

      case RotasApp.alterarSenha:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _alterarSenhaController.construirTela(context, args),
        );

      case RotasApp.painel:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _dashboardController.construirTela(context, args),
        );

      case RotasApp.mercadoCripto:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _mercadoCriptoController.construirTela(context, args),
        );

      case RotasApp.comprarCripto:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _comprarCriptoController.construirTela(context, args),
        );

      case RotasApp.editarConta:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _editarContaController.construirTela(context, args),
        );

      case RotasApp.transferirCripto:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _transferirCriptoController.construirTela(context, args),
        );

      case RotasApp.statusBlockchain:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _statusBlockchainController.construirTela(context, args),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => _loginController.construirTela(context),
        );
    }
  }
}
