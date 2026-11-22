import 'package:flutter/material.dart';
import '../modelos/clienteModelo.dart';
import '../servicos/servicoFirestore.dart';
import '../telas/depositarComPix.dart';
import 'baseController.dart';
import 'loginController.dart';

class DepositarComPixController extends BaseController {
  final ServicoFirestore _servicoFirestore;

  DepositarComPixController({ServicoFirestore? servicoFirestore})
      : _servicoFirestore = servicoFirestore ?? ServicoFirestore();

  Widget construirTela(BuildContext context, Object? args) {
    if (args is! ClienteModelo) {
      return LoginController().construirTela(context);
    }

    return DepositarComPix(
      iniciaisUsuario: extrairIniciais(args.nome),
      nomeRecebedor: 'BLOCKPAY EDU',
      cidadeRecebedor: 'SAO PAULO',
      aoConfirmarDeposito: (valorBrl) async {
        if (valorBrl < 1.0) {
          return 'O valor mínimo para depósito via Pix é R\$ 1,00.';
        }

        try {
          final registroBlockchain =
              await _servicoFirestore.registrarDepositoPix(
            cpf: args.cpf,
            valorBrl: valorBrl,
          );

          if (context.mounted) {
            final valorFormatado = formatarMoedaBr(valorBrl);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Depósito de $valorFormatado confirmado! Registrado no Bloco #${registroBlockchain.indiceBloco}.',
                ),
                backgroundColor: const Color(0xFF00C853),
              ),
            );

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              navegarPeloMenu(context, args, 0);
            }
          }
          return null;
        } on ExcecaoAutenticacao catch (erro) {
          return erro.mensagem;
        } catch (_) {
          return 'Não foi possível confirmar o depósito Pix agora.';
        }
      },
      aoVoltar: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          navegarPeloMenu(context, args, 0);
        }
      },
      aoClicarPerfil: () => abrirPerfil(context, args),
      aoClicarSair: () => sairDaConta(context),
      aoSelecionarAba: (indice) => navegarPeloMenu(context, args, indice),
    );
  }
}
