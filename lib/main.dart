import 'package:flutter/material.dart';
import 'historico_service.dart';
import 'tela_calculadora_liquida.dart';
import 'tela_historico.dart';

void main() {
  runApp(const AgApp());
}

class AgApp extends StatelessWidget {
  const AgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calda Pronta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Impede o efeito de esticar e permite que a tela deslize revelando o fundo
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      home: const TelaSplash(),
    );
  }
}

/// TELA DE CARREGAMENTO (SPLASH SCREEN)
class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash> {
  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    // Leitura dos dados gravados localmente
    await HistoricoService.carregar();
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TelaMenuPrincipal()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_takeoff, size: 90, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'CALDA PRONTA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestão Operacional de Pista',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// MENU PRINCIPAL
class TelaMenuPrincipal extends StatelessWidget {
  const TelaMenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços Agrícolas'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecione a Ferramenta:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // BOTÃO 1: CALCULADORA LÍQUIDA
            Card(
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 28,
                  child: Icon(Icons.water_drop, color: Colors.blue.shade800, size: 30),
                ),
                title: const Text(
                  'Calculadora de Calda Líquida',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: const Text('Cálculo de dosagem, receita de voo cheio e fechamento por hectare.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaCalculadora()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // BOTÃO 2: HISTÓRICO DE OPERAÇÕES (FUNCIONAL)
            Card(
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  radius: 28,
                  child: Icon(Icons.history, color: Colors.amber.shade900, size: 30),
                ),
                title: const Text(
                  'Histórico de Operações',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: const Text('Consulte os registros das pulverizações efetuadas.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaHistorico()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // BOTÃO 3: CALCULADORA DE SÓLIDOS (FUTURO)
            Card(
              elevation: 1,
              color: Colors.grey.shade100,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 28,
                  child: Icon(Icons.grain, color: Colors.white, size: 30),
                ),
                title: const Text(
                  'Calculadora de Sólidos (Adubo/Sementes)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                ),
                subtitle: const Text('Em breve: Aplicação de adubo granulado e semeadura.'),
                trailing: const Icon(Icons.lock_clock),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Serviço de sólidos será desenvolvido em breve!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}