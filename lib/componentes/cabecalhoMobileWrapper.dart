import 'package:flutter/material.dart';
import 'avatarUsuarioWrapper.dart';
import 'coresApp.dart';

class CabecalhoMobileWrapper extends StatelessWidget {
  final String titulo;
  final String iniciaisUsuario;
  final bool mostrarBotaoVoltar;
  final VoidCallback? aoVoltar;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const CabecalhoMobileWrapper({
    super.key,
    required this.titulo,
    required this.iniciaisUsuario,
    this.mostrarBotaoVoltar = false,
    this.aoVoltar,
    this.aoClicarPerfil,
    this.aoClicarSair,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (mostrarBotaoVoltar) ...[
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
