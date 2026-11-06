import 'package:flutter/material.dart';
import 'calculadora.dart';
import 'historico_service.dart';

class ItemProdutoInput {
  final TextEditingController nomeController;
  final TextEditingController doseController;

  ItemProdutoInput({String nome = '', String dose = ''})
      : nomeController = TextEditingController(text: nome),
        doseController = TextEditingController(text: dose);
}

class TelaCalculadora extends StatefulWidget {
  final ItemHistorico? itemParaEditar; // Item vindo do Histórico

  const TelaCalculadora({super.key, this.itemParaEditar});

  @override
  State<TelaCalculadora> createState() => _TelaCalculadoraState();
}

class _TelaCalculadoraState extends State<TelaCalculadora> {
  final _areaController = TextEditingController();
  final _taxaController = TextEditingController();
  final _cargaController = TextEditingController();

  ModoDivisao _modoDivisao = ModoDivisao.cargaMaxima;
  final List<ItemProdutoInput> _produtosInput = [];

  ResultadoOperacao? _resultado;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    if (widget.itemParaEditar != null) {
      _carregarDadosDoHistorico(widget.itemParaEditar!);
    } else {
      _carregarValoresPadrao();
    }
  }

  void _carregarDadosDoHistorico(ItemHistorico item) {
    _areaController.text = item.areaTotal.toString();
    _taxaController.text = item.taxaAplicacao.toString();
    _cargaController.text = item.cargaAviao.toString();
    _modoDivisao = item.modoDivisao == 'cargaIgual' ? ModoDivisao.cargaIgual : ModoDivisao.cargaMaxima;

    for (var prod in _produtosInput) {
      prod.nomeController.dispose();
      prod.doseController.dispose();
    }
    _produtosInput.clear();

    for (var p in item.produtosBase) {
      _produtosInput.add(ItemProdutoInput(
        nome: p['nome'] ?? '',
        dose: (p['dosePorHa'] ?? 0.0).toString(),
      ));
    }
  }

  void _carregarValoresPadrao() {
    _areaController.clear();
    _taxaController.clear();
    _cargaController.clear();

    for (var item in _produtosInput) {
      item.nomeController.dispose();
      item.doseController.dispose();
    }
    _produtosInput.clear();

    // Deixa 1 linha de produto em branco pronta para digitação
    _produtosInput.add(ItemProdutoInput());
  }

  @override
  void dispose() {
    _areaController.dispose();
    _taxaController.dispose();
    _cargaController.dispose();
    for (var item in _produtosInput) {
      item.nomeController.dispose();
      item.doseController.dispose();
    }
    super.dispose();
  }

  void _adicionarProduto() {
    setState(() {
      _produtosInput.add(ItemProdutoInput());
    });
  }

  void _removerProduto(int index) {
    setState(() {
      _produtosInput[index].nomeController.dispose();
      _produtosInput[index].doseController.dispose();
      _produtosInput.removeAt(index);
    });
  }

  void _limparTudo() {
    setState(() {
      _areaController.clear();
      _taxaController.clear();
      _cargaController.clear();

      for (var item in _produtosInput) {
        item.nomeController.dispose();
        item.doseController.dispose();
      }
      _produtosInput.clear();

      _resultado = null;
      _mensagemErro = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário limpo com sucesso!')),
    );
  }

  void _executarCalculo() {
    // Esconde o teclado da tela
    FocusScope.of(context).unfocus();

    setState(() {
      _mensagemErro = null;
      _resultado = null;
    });

    try {
      final area = double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0;
      final taxa = double.tryParse(_taxaController.text.replaceAll(',', '.')) ?? 0;
      final carga = double.tryParse(_cargaController.text.replaceAll(',', '.')) ?? 0;

      final List<Produto> listaProdutos = [];
        for (var i = 0; i < _produtosInput.length; i++) {
          final nomeInput = _produtosInput[i].nomeController.text.trim();
          final doseText = _produtosInput[i].doseController.text.replaceAll(',', '.');
          final dose = double.tryParse(doseText) ?? 0.0;

          // Se o nome estiver vazio, assume "Produto 1", "Produto 2", etc.
          final nomeFinal = nomeInput.isEmpty ? 'Produto ${i + 1}' : nomeInput;

          if (dose > 0) {
            listaProdutos.add(Produto(nome: nomeFinal, dosePorHa: dose));
          }
        }

      final res = CalculadoraAgricola.calcular(
        areaTotalHa: area,
        taxaAplicacao: taxa,
        cargaAviao: carga,
        produtos: listaProdutos,
        modoDivisao: _modoDivisao,
      );

      setState(() {
        _resultado = res;
      });
    } catch (e) {
      setState(() {
        _mensagemErro = e.toString().replaceAll('Exception: ', '').replaceAll('ArgumentError: ', '');
      });
    }
  }

  Future<void> _salvarCalculo() async {
    if (_resultado == null) return;

    // Garante que nenhum campo da tela principal esteja focado antes de abrir o diálogo
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final historicoAtual = await HistoricoService.carregar();
    final numeroPadrao = historicoAtual.length + 1;
    final String nomeSugerido = 'Cálculo $numeroPadrao';

    final nomeController = TextEditingController();

    if (!mounted) return;

    final String? nomeEscolhido = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar Operação'),
        content: TextField(
          controller: nomeController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nome do Registro / Talhão',
            hintText: nomeSugerido,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = nomeController.text.trim();
              Navigator.pop(ctx, texto.isEmpty ? nomeSugerido : texto);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // Remove qualquer intenção do Flutter de restaurar o foco para os campos de texto da tela
    if (mounted) {
      FocusScope.of(context).requestFocus(FocusNode());
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (nomeEscolhido == null) return;

    final agora = DateTime.now();
    final dataFormatada =
        '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} - ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    final List<String> produtosVooPadrao = [];
    _resultado!.produtosPorVooPadrao.forEach((nome, qtd) {
      produtosVooPadrao.add('$nome: ${qtd.toStringAsFixed(1)} L');
    });

    final List<String> produtosVooParcial = [];
    _resultado!.produtosPorVooParcial.forEach((nome, qtd) {
      produtosVooParcial.add('$nome: ${qtd.toStringAsFixed(1)} L');
    });

    final List<Map<String, dynamic>> produtosBase = [];
    for (var i = 0; i < _produtosInput.length; i++) {
      final p = _produtosInput[i];
      final nomeInput = p.nomeController.text.trim();
      final dose = double.tryParse(p.doseController.text.replaceAll(',', '.')) ?? 0.0;
      final nomeFinal = nomeInput.isEmpty ? 'Produto ${i + 1}' : nomeInput;

      if (dose > 0) {
        produtosBase.add({'nome': nomeFinal, 'dosePorHa': dose});
      }
    }

    final novoItem = ItemHistorico(
      id: agora.millisecondsSinceEpoch.toString(),
      nome: nomeEscolhido,
      dataHora: dataFormatada,
      modoDivisao: _resultado!.modoDivisao == ModoDivisao.cargaIgual ? 'cargaIgual' : 'cargaMaxima',
      areaTotal: _resultado!.areaTotalHa,
      taxaAplicacao: double.parse(_taxaController.text.replaceAll(',', '.')),
      cargaAviao: double.parse(_cargaController.text.replaceAll(',', '.')),
      totalVoos: _resultado!.totalVoos,
      voosCheios: _resultado!.voosCheios,
      hectaresPorVooPadrao: _resultado!.areaPorVooPadrao,
      cargaVooPadrao: _resultado!.cargaVooPadrao,
      volumeTotalCalda: _resultado!.volumeTotalCalda,
      aguaVooPadrao: _resultado!.aguaPorVooPadrao,
      produtosVooPadrao: produtosVooPadrao,
      produtosBase: produtosBase,
      temVooParcial: _resultado!.temVooParcial,
      areaVooParcial: _resultado!.areaVooParcial,
      cargaVooParcial: _resultado!.cargaVooParcial,
      aguaVooParcial: _resultado!.aguaPorVooParcial,
      produtosVooParcial: produtosVooParcial,
    );

    await HistoricoService.salvar(novoItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$nomeEscolhido" salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemParaEditar != null ? 'Reutilizar / Editar Cálculo' : 'Calculadora de Calda Aérea'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CARD 1: DADOS DA OPERAÇÃO
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Parâmetros da Operação',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SELEÇÃO DO MODO DE VOO
                    const Text('Estratégia de Carregamento:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SegmentedButton<ModoDivisao>(
                      segments: const [
                        ButtonSegment(
                          value: ModoDivisao.cargaMaxima,
                          label: Text('Carga Máx + Voo de Fechamento', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.flight_takeoff, size: 16),
                        ),
                        ButtonSegment(
                          value: ModoDivisao.cargaIgual,
                          label: Text('Cargas Igualadas', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.balance, size: 16),
                        ),
                      ],
                      selected: {_modoDivisao},
                      onSelectionChanged: (Set<ModoDivisao> newSelection) {
                        setState(() {
                          _modoDivisao = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Área Total (ha)',
                        border: OutlineInputBorder(),
                        suffixText: 'ha',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taxaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Taxa de Aplicação (L/ha)',
                        border: OutlineInputBorder(),
                        suffixText: 'L/ha',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cargaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Capacidade Máxima do Avião (L)',
                        border: OutlineInputBorder(),
                        helperText: 'Limite máximo permitido no tanque',
                        suffixText: 'L',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CARD 2: PRODUTOS
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produtos / Defensivos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton.filledTonal(
                          onPressed: _adicionarProduto,
                          icon: const Icon(Icons.add),
                          tooltip: 'Adicionar Produto',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_produtosInput.isEmpty)
                      const Text(
                        'Nenhum produto adicionado. Clique no "+" para incluir.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _produtosInput.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _produtosInput[index].nomeController,
                                  decoration: InputDecoration(
                                    labelText: 'Produto ${index + 1}',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _produtosInput[index].doseController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Dose (L/ha)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removerProduto(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BOTÕES DE AÇÃO
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _executarCalculo,
                    icon: const Icon(Icons.calculate),
                    label: const Text('CALCULAR', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _limparTudo,
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    label: const Text('LIMPAR', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),

            if (_mensagemErro != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade400),
                ),
                child: Text(
                  _mensagemErro!,
                  style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            // RESULTADOS
            if (_resultado != null) ...[
              const SizedBox(height: 24),

              // CARD 1: VOO PADRÃO OU IGUALADO
              Card(
                color: Colors.green.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.green.shade600, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _resultado!.modoDivisao == ModoDivisao.cargaIgual ? Icons.balance : Icons.flight_takeoff,
                            color: Colors.green.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _resultado!.modoDivisao == ModoDivisao.cargaIgual
                                  ? 'RECEITA POR VOO (${_resultado!.totalVoos} Voos Igualados)'
                                  : 'RECEITA DO VOO (${_resultado!.voosCheios} ${_resultado!.voosCheios == 1 ? 'Voo' : 'Voos'})',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        'Cobertura por Voo: ${_resultado!.areaPorVooPadrao.toStringAsFixed(1)} ha',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Volume no Tanque: ${_resultado!.cargaVooPadrao.toStringAsFixed(1)} L',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('🧪 Produtos no Tanque:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._resultado!.produtosPorVooPadrao.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                            child: Text(
                              '• ${e.key}: ${e.value.toStringAsFixed(1)} L',
                              style: const TextStyle(fontSize: 15),
                            ),
                          )),
                      const SizedBox(height: 8),
                      Text(
                        '💧 Água: ${_resultado!.aguaPorVooPadrao.toStringAsFixed(1)} Litros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CARD 2: FECHAMENTO
              if (_resultado!.modoDivisao == ModoDivisao.cargaMaxima && _resultado!.temVooParcial) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.shade50,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.orange.shade700, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flight_land, color: Colors.orange.shade900),
                            const SizedBox(width: 8),
                            Text(
                              'ÚLTIMO VOO (FECHAMENTO)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Área do Voo de Fechamento: ${_resultado!.areaVooParcial.toStringAsFixed(1)} ha',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Volume Necessário no Tanque: ${_resultado!.cargaVooParcial.toStringAsFixed(1)} L',
                          style: TextStyle(fontSize: 15, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('🧪 Produtos no Tanque:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._resultado!.produtosPorVooParcial.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                              child: Text(
                                '• ${e.key}: ${e.value.toStringAsFixed(1)} L',
                                style: const TextStyle(fontSize: 15),
                              ),
                            )),
                        const SizedBox(height: 8),
                        Text(
                          '💧 Água: ${_resultado!.aguaPorVooParcial.toStringAsFixed(1)} Litros',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // CARD 3: RESUMO TOTAL
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo Total da Área',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text('• Total de Decolagens: ${_resultado!.totalVoos} voos'),
                      Text('• Volume Total de Calda: ${_resultado!.volumeTotalCalda.toStringAsFixed(1)} L'),
                      Text('• Água Total para a Área: ${_resultado!.aguaTotal.toStringAsFixed(1)} L'),
                      const SizedBox(height: 8),
                      const Text('• Consumo Total de Produtos:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._resultado!.produtosTotais.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                            child: Text('• ${e.key}: ${e.value.toStringAsFixed(1)} L'),
                          )),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _salvarCalculo,
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('Salvar no Histórico'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}