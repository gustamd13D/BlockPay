import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/criarUsuario.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class CriarUsuarioController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  CriarUsuarioController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  void _voltarParaGerenciarUsuarios(BuildContext context, ClienteModelo admin) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(
        context,
        RotasApp.gerenciarUsuarios,
        arguments: admin,
      );
    }
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return CriarUsuario(
      iniciaisAdmin: extrairIniciais(args.nome),
      aoVoltar: () => _voltarParaGerenciarUsuarios(context, args),
      aoCancelar: () => _voltarParaGerenciarUsuarios(context, args),
      aoClicarPerfil: () => abrirPerfil(context, args),
      aoClicarSair: () => sairDaConta(context),
      aoSelecionarAba: (indice) => navegarPeloMenuAdmin(context, args, indice),
      aoCriarUsuario: (nome, cpf, email, pin, isAdmin) async {
        final criado = await executarComCarregamento(context, () async {
          await _servicoFirestore.cadastrarCliente(
            nome: nome,
            cpf: cpf,
            email: email,
            pin: pin,
            isAdmin: isAdmin,
          );
          return true;
        });

        if (criado == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário criado com sucesso!'),
              backgroundColor: CoresApp.verdePositivo,
            ),
          );
          _voltarParaGerenciarUsuarios(context, args);
        }
      },
    );
  }
}
