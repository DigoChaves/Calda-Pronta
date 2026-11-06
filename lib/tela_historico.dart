import 'package:flutter/material.dart';
import 'historico_service.dart';
import 'tela_calculadora_liquida.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  List<ItemHistorico> _lista = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarHistorico();
  }

  Future<void> _buscarHistorico() async {
    final dados = await HistoricoService.carregar();
    setState(() {
      _lista = dados;
      _carregando = false;
    });
  }

  Future<void> _deletarUnicoItem(String id) async {
    await HistoricoService.deletarItem(id);
    _buscarHistorico();
  }

  Future<void> _limparHistorico() async {
    await HistoricoService.limparTudo();
    _buscarHistorico();
  }

  void _reutilizarCalculo(ItemHistorico item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCalculadora(itemParaEditar: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo acinzentado para criar contraste e fazer os cards brancos "saltarem" na tela
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Histórico de Operações'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_lista.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Limpar Todo o Histórico',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar Todo o Histórico?'),
                    content: const Text('Todos os registros salvos serão apagados permanentemente.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _limparHistorico();
                        },
                        child: const Text('Apagar Tudo', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _lista.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum cálculo salvo ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lista.length,
                  itemBuilder: (context, index) {
                    final item = _lista[index];
                    
                    final isModoIgualado = item.modoDivisao == 'cargaIgual';
                    final isCargaReduzida = item.cargaVooPadrao < (item.cargaAviao - 0.01);
                    final isIgualadoEfetivo = isModoIgualado && isCargaReduzida;

                    Color badgeBgColor;
                    Color badgeTextColor;
                    String badgeText;

                    if (isIgualadoEfetivo) {
                      badgeBgColor = Colors.blue.shade100;
                      badgeTextColor = Colors.blue.shade900;
                      badgeText = '${item.totalVoos} Voos Igualados';
                    } else if (item.temVooParcial) {
                      badgeBgColor = Colors.purple.shade100;
                      badgeTextColor = Colors.purple.shade900;
                      final sufixoCheios = item.voosCheios == 1 ? 'Cheio' : 'Cheios';
                      badgeText = '${item.totalVoos} Voos (${item.voosCheios} $sufixoCheios + 1 Fechamento)';
                    } else {
                      badgeBgColor = Colors.green.shade100;
                      badgeTextColor = Colors.green.shade900;
                      badgeText = item.totalVoos == 1 ? '1 Voo Cheio' : '${item.totalVoos} Voos Cheios';
                    }

                    return Card(
                      elevation: 3,
                      shadowColor: Colors.black38,
                      // Borda sutil verde e cantos bem arredondados para destacar o container
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green.shade300, width: 1.2),
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nome,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                      Text(
                                        item.dataHora,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeBgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: badgeTextColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: Colors.blue, size: 28),
                                  tooltip: 'Reutilizar / Editar',
                                  onPressed: () => _reutilizarCalculo(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Excluir registro',
                                  onPressed: () => _deletarUnicoItem(item.id),
                                ),
                              ],
                            ),
                            const Divider(),

                            Text('• Área Total: ${item.areaTotal.toStringAsFixed(1)} ha | Taxa: ${item.taxaAplicacao.toStringAsFixed(1)} L/ha'),
                            Text('• Calda Total: ${item.volumeTotalCalda.toStringAsFixed(1)} L'),
                            Text(
                              '• Cobertura por Voo: ${item.hectaresPorVooPadrao.toStringAsFixed(1)} ha/voo (${item.cargaVooPadrao.toStringAsFixed(1)} L no tanque)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              isIgualadoEfetivo ? '🧪 Produtos por Voo Igualado:' : '🧪 Produtos por Voo Cheio:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...item.produtosVooPadrao.map((p) => Padding(
                                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                                  child: Text('• $p'),
                                )),
                            const SizedBox(height: 6),

                            Text(
                              '💧 Água por Voo: ${item.aguaVooPadrao.toStringAsFixed(1)} L',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),

                            if (!isIgualadoEfetivo && item.temVooParcial) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.flight_land, size: 20, color: Colors.orange.shade900),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Voo de Fechamento',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    Text(
                                      '• Área Restante: ${item.areaVooParcial.toStringAsFixed(1)} ha | Calda no Tanque: ${item.cargaVooParcial.toStringAsFixed(1)} L',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text('🧪 Produtos no Fechamento:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...item.produtosVooParcial.map((p) => Padding(
                                          padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                                          child: Text('• $p'),
                                        )),
                                    const SizedBox(height: 6),
                                    Text(
                                      '💧 Água no Voo: ${item.aguaVooParcial.toStringAsFixed(1)} L',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}