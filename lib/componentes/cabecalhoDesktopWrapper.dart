import 'package:flutter/material.dart';
import 'avatarUsuarioWrapper.dart';
import 'coresApp.dart';

class CabecalhoDesktopWrapper extends StatelessWidget {
  final String iniciaisUsuario;
  final int indiceAtivo;
  final String? etiquetaTela;
  final ValueChanged<int>? aoSelecionarAba;
  final VoidCallback? aoClicarPerfil;
  final VoidCallback? aoClicarSair;

  const CabecalhoDesktopWrapper({
    super.key,
    required this.iniciaisUsuario,
    required this.indiceAtivo,
    this.etiquetaTela,
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
          bottom: BorderSide(
            color: CoresApp.borda,
            width: 1,
          ),
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
              if (etiquetaTela != null && etiquetaTela!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: CoresApp.cianoSuave,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    etiquetaTela!,
                    style: const TextStyle(
                      color: CoresApp.cianoPrimario,
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _ItemMenuSuperior(
                icone: Icons.account_balance_wallet_outlined,
                rotulo: 'Início',
                ativo: indiceAtivo == 0,
                aoClicar: () => aoSelecionarAba?.call(0),
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.show_chart_rounded,
                rotulo: 'Mercado',
                ativo: indiceAtivo == 1,
                aoClicar: () => aoSelecionarAba?.call(1),
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.pix_outlined,
                rotulo: 'Pix',
                ativo: indiceAtivo == 2,
                aoClicar: () => aoSelecionarAba?.call(2),
              ),
              const SizedBox(width: 8),
              _ItemMenuSuperior(
                icone: Icons.history_rounded,
                rotulo: 'Histórico',
                ativo: indiceAtivo == 3,
                aoClicar: () => aoSelecionarAba?.call(3),
              ),
              const SizedBox(width: 20),
              AvatarUsuarioWrapper(
                iniciais: iniciaisUsuario,
                aoClicarPerfil: aoClicarPerfil,
                aoClicarSair: aoClicarSair,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemMenuSuperior extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final VoidCallback aoClicar;

  const _ItemMenuSuperior({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    required this.aoClicar,
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
