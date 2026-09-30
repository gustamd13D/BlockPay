import 'package:flutter/material.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BlockPay EDU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 80),
              const Text(
                'Aprenda a investir em cripto sem riscos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Simule carteiras, faça conversões instantâneas '
                'e envie transferências na blockchain usando '
                'um saldo fictício educativo.',
                style: TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Text(
                'Carteira Simulada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comece com R\$ 10.000,00 fictícios para praticar.',
                style: TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Conversão & Pix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Simule pix e compre moedas com cotações reais.',
                style: TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Ambiente 100% educativo. Sem dinheiro real envolvido '
                'e sem qualquer tipo de risco financeiro.',
                style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Iniciar Simulação'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}