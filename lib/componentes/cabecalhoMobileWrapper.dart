import 'package:flutter/material.dart';
import 'avatarUsuarioWrapper.dart';
import 'coresApp.dart';

class CabecalhoMobileWrapper extends StatelessWidget {
  final String titulo;
  final String iniciaisUsuario;
  final bool mostrarBotaoVoltar;
  final bool estiloAdmin;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const CabecalhoMobileWrapper({
    super.key,
    required this.titulo,
    required this.iniciaisUsuario,
    this.mostrarBotaoVoltar = false,
    this.estiloAdmin = false,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mostrarBotaoVoltar && estiloAdmin ? 12 : 20,
        14,
        20,
        14,
      ),
      child: Row(
        children: [
          if (mostrarBotaoVoltar && estiloAdmin) ...[
            InkWell(
              onTap: aoVoltar ?? () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: CoresApp.cianoPrimario,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ] else if (mostrarBotaoVoltar) ...[
            InkWell(
              onTap: aoVoltar ?? () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: CoresApp.superficieAvatar,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: CoresApp.textoPrimario,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: CoresApp.textoPrimario,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AvatarUsuarioWrapper(
            iniciais: iniciaisUsuario,
            aoClicarPerfil: aoClicarPerfil,
            aoClicarSair: aoClicarSair,
          ),
        ],
      ),
    );
  }
}
