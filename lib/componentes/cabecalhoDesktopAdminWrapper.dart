import 'package:flutter/material.dart';
import 'coresApp.dart';

class CabecalhoDesktopAdminWrapper extends StatelessWidget {
  final String iniciaisUsuario;
  final int indiceAtivo;
  final String etiquetaTela;
  final ValueChanged<int>? aoSelecionarAba;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const CabecalhoDesktopAdminWrapper({
    super.key,
    required this.iniciaisUsuario,
    required this.indiceAtivo,
    this.etiquetaTela = 'Admin',
    this.aoSelecionarAba,
    this.aoClicarPerfil,
    this.aoClicarSair,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CoresApp.superficie,
        border: Border(
          bottom: BorderSide(color: CoresApp.borda, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CoresApp.cianoSuave,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CoresApp.cianoPrimario,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: CoresApp.cianoPrimario,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'BlockPay',
                style: TextStyle(
                  color: CoresApp.textoPrimario,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CoresApp.cianoSuave,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  etiquetaTela,
                  style: const TextStyle(
                    color: CoresApp.cianoPrimario,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _ItemMenuSuperiorAdmin(
                icone: Icons.grid_view_rounded,
                rotulo: 'Visão geral',
                ativo: indiceAtivo == 0,
                aoClicar: () => aoSelecionarAba?.call(0),
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperiorAdmin(
                icone: Icons.people_outline_rounded,
                rotulo: 'Usuários',
                ativo: indiceAtivo == 1,
                aoClicar: () => aoSelecionarAba?.call(1),
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperiorAdmin(
                icone: Icons.description_outlined,
                rotulo: 'Auditoria',
                ativo: indiceAtivo == 2,
                aoClicar: () => aoSelecionarAba?.call(2),
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperiorAdmin(
                icone: Icons.settings_outlined,
                rotulo: 'Ajustes',
                ativo: indiceAtivo == 3,
                aoClicar: () => aoSelecionarAba?.call(3),
              ),
              const SizedBox(width: 20),
              PopupMenuButton<String>(
                tooltip: 'Opções da conta',
                offset: const Offset(0, 44),
                color: CoresApp.superficie,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: CoresApp.borda, width: 1),
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
                    iniciaisUsuario.toUpperCase(),
                    style: const TextStyle(
                      color: CoresApp.cianoPrimario,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemMenuSuperiorAdmin extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback? aoClicar;

  const _ItemMenuSuperiorAdmin({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? CoresApp.cianoPrimario : CoresApp.textoSecundario;

    return InkWell(
      onTap: aoClicar,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? CoresApp.cianoSuave : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: cor, size: 18),
            const SizedBox(width: 6),
            Text(
              rotulo,
              style: TextStyle(
                color: cor,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
