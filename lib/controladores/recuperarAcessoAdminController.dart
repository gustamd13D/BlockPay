import 'package:flutter/material.dart';
import '../componentes/coresApp.dart';
import '../modelos/clienteModelo.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/recuperarAcessoAdmin.dart';
import 'baseController.dart';
import 'loginController.dart';
import 'routerController.dart';

class RecuperarAcessoAdminController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  RecuperarAcessoAdminController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  void _voltarParaAjustes(BuildContext context, ClienteModelo admin) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(
        context,
        RotasApp.adminAjustes,
        arguments: admin,
      );
    }
  }

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return RecuperarAcessoAdmin(
      iniciaisUsuario: extrairIniciais(args.nome),
      aoVoltar: () => _voltarParaAjustes(context, args),
      aoCancelar: () => _voltarParaAjustes(context, args),
      aoClicarPerfil: () => abrirPerfil(context, args),
      aoClicarSair: () => sairDaConta(context),
      aoSelecionarAba: (indice) => navegarPeloMenuAdmin(context, args, indice),
      aoConfirmarAlteracao: (senhaAtual, novaSenha) async {
        var salva = false;

        await executarComCarregamento(context, () async {
          await _servicoFirestore.redefinirSenha(
            cpf: args.cpf,
            novaSenha: novaSenha,
            senhaAtual: senhaAtual,
          );
          salva = true;
        });

        if (salva && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha master alterada com sucesso!'),
              backgroundColor: CoresApp.verdePositivo,
            ),
          );
          _voltarParaAjustes(context, args);
        }
      },
    );
  }
}
