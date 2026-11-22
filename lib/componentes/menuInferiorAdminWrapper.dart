import 'package:flutter/material.dart';
import 'coresApp.dart';

class MenuInferiorAdminWrapper extends StatelessWidget {
  final int indiceAtivo;
  final ValueChanged<int>? aoSelecionarAba;

  const MenuInferiorAdminWrapper({
    super.key,
    required this.indiceAtivo,
    this.aoSelecionarAba,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CoresApp.superficie,
        border: Border(
          top: BorderSide(
            color: CoresApp.borda,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ItemMenuAdminRodape(
                    icone: Icons.grid_view_rounded,
                    rotulo: 'Visão geral',
                    ativo: indiceAtivo == 0,
                    aoClicar: () => aoSelecionarAba?.call(0),
                  ),
                  _ItemMenuAdminRodape(
                    icone: Icons.people_outline_rounded,
                    rotulo: 'Usuários',
                    ativo: indiceAtivo == 1,
                    aoClicar: () => aoSelecionarAba?.call(1),
                  ),
                  _ItemMenuAdminRodape(
                    icone: Icons.description_outlined,
                    rotulo: 'Auditoria',
                    ativo: indiceAtivo == 2,
                    aoClicar: () => aoSelecionarAba?.call(2),
                  ),
                  _ItemMenuAdminRodape(
                    icone: Icons.settings_outlined,
                    rotulo: 'Ajustes',
                    ativo: indiceAtivo == 3,
                    aoClicar: () => aoSelecionarAba?.call(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemMenuAdminRodape extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback? aoClicar;

  const _ItemMenuAdminRodape({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? CoresApp.cianoPrimario : CoresApp.textoSecundario;

    return Expanded(
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                color: cor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                rotulo,
                style: TextStyle(
                  color: cor,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
