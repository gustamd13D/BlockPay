import 'package:flutter/material.dart';
import '../telas/boasvindas.dart';
import 'routerController.dart';
import 'baseController.dart';

class BoasVindasController extends BaseController {
  Widget construirTela(BuildContext context) {
    return TelaBoasVindas(
      iniciarSimulacao: () {
        Navigator.pushNamed(context, RotasApp.login);
      },
    );
  }
}
