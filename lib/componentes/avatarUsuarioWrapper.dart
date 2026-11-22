import 'package:flutter/material.dart';
import 'coresApp.dart';

class AvatarUsuarioWrapper extends StatelessWidget {
  final String iniciais;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const AvatarUsuarioWrapper({
    super.key,
    required this.iniciais,
    this.aoClicarPerfil,
    this.aoClicarSair,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Opções da conta',
      offset: const Offset(0, 44),
      color: CoresApp.superficie,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: CoresApp.borda,
          width: 1,
        ),
      ),
      onSelected: (opcao) {
        if (opcao == 'conta') {
          aoClicarPerfil?.call();
        } else if (opcao == 'sair') {
          aoClicarSair?.call();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'conta',
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: CoresApp.cianoPrimario,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Minha Conta',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'sair',
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: CoresApp.vermelhoNegativo,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Sair',
                style: TextStyle(
                  color: CoresApp.vermelhoNegativo,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CoresApp.superficieAvatar,
          shape: BoxShape.circle,
        ),
        child: Text(
          iniciais.toUpperCase(),
          style: const TextStyle(
            color: CoresApp.cianoPrimario,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
