import 'package:flutter/material.dart';
import 'adminAjustesController.dart';
import 'alterarSenhaController.dart';
import 'auditoriaController.dart';
import 'boasVindasController.dart';
import 'cadastroClienteController.dart';
import 'comprarCriptoController.dart';
import 'criarUsuarioController.dart';
import 'dashboardAdminController.dart';
import 'dashboardController.dart';
import 'depositarComPixController.dart';
import 'detalhesUsuarioController.dart';
import 'editarContaController.dart';
import 'editarUsuarioController.dart';
import 'gerenciarUsuariosController.dart';
import 'historicoTransacoesController.dart';
import 'loginController.dart';
import 'mercadoCriptoController.dart';
import 'recuperarAcessoAdminController.dart';
import 'recuperarAcessoController.dart';
import 'statusBlockchainController.dart';
import 'transferirCriptoController.dart';
import 'validarCodigoController.dart';

abstract class RotasApp {
  static const String boasVindas = '/';
  static const String login = '/login';
  static const String painel = '/painel';
  static const String painelAdmin = '/painel-admin';
  static const String gerenciarUsuarios = '/gerenciar-usuarios';
  static const String detalhesUsuario = '/detalhes-usuario';
  static const String criarUsuario = '/criar-usuario';
  static const String editarUsuario = '/editar-usuario';
  static const String auditoria = '/auditoria';
  static const String adminAjustes = '/admin-ajustes';
  static const String recuperarAcessoAdmin = '/recuperar-acesso-admin';
  static const String mercadoCripto = '/mercado-cripto';
  static const String comprarCripto = '/comprar-cripto';
  static const String depositarComPix = '/depositar-com-pix';
  static const String historico = '/historico';
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
  static final RecuperarAcessoAdminController _recuperarAcessoAdminController =
      RecuperarAcessoAdminController();
  static final ValidarCodigoController _validarCodigoController =
      ValidarCodigoController();
  static final AlterarSenhaController _alterarSenhaController =
      AlterarSenhaController();
  static final DashboardController _dashboardController = DashboardController();
  static final DashboardAdminController _dashboardAdminController =
      DashboardAdminController();
  static final GerenciarUsuarioController _gerenciarUsuariosController =
      GerenciarUsuarioController();
  static final DetalhesUsuarioController _detalhesUsuarioController =
      DetalhesUsuarioController();
  static final CriarUsuarioController _criarUsuarioController =
      CriarUsuarioController();
  static final EditarUsuarioController _editarUsuarioController =
      EditarUsuarioController();
  static final AuditoriaController _auditoriaController = AuditoriaController();
  static final AdminAjustesController _adminAjustesController =
      AdminAjustesController();
  static final MercadoCriptoController _mercadoCriptoController =
      MercadoCriptoController();
  static final ComprarCriptoController _comprarCriptoController =
      ComprarCriptoController();
  static final DepositarComPixController _depositarComPixController =
      DepositarComPixController();
  static final HistoricoTransacoesController _historicoTransacoesController =
      HistoricoTransacoesController();
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

      case RotasApp.recuperarAcessoAdmin:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _recuperarAcessoAdminController.construirTela(context, args),
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

      case RotasApp.painelAdmin:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _dashboardAdminController.construirTela(context, args),
        );

      case RotasApp.gerenciarUsuarios:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _gerenciarUsuariosController.construirTela(context, args),
        );

      case RotasApp.detalhesUsuario:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _detalhesUsuarioController.construirTela(context, args),
        );

      case RotasApp.criarUsuario:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _criarUsuarioController.construirTela(context, args),
        );

      case RotasApp.editarUsuario:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _editarUsuarioController.construirTela(context, args),
        );

      case RotasApp.auditoria:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _auditoriaController.construirTela(context, args),
        );

      case RotasApp.adminAjustes:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _adminAjustesController.construirTela(context, args),
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

      case RotasApp.depositarComPix:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _depositarComPixController.construirTela(context, args),
        );

      case RotasApp.historico:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              _historicoTransacoesController.construirTela(context, args),
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
