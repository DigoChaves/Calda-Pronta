import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ItemHistorico {
  final String id;
  final String nome;
  final String dataHora;
  final String modoDivisao;
  final double areaTotal;
  final double taxaAplicacao;
  final double cargaAviao;
  final int totalVoos;
  final int voosCheios;
  final double hectaresPorVooPadrao;
  final double cargaVooPadrao;
  final double volumeTotalCalda;
  final double aguaVooPadrao;
  final List<String> produtosVooPadrao;
  final List<Map<String, dynamic>> produtosBase; // Guardas os nomes e doses/ha originais

  // Saideira
  final bool temVooParcial;
  final double areaVooParcial;
  final double cargaVooParcial;
  final double aguaVooParcial;
  final List<String> produtosVooParcial;

  ItemHistorico({
    required this.id,
    required this.nome,
    required this.dataHora,
    required this.modoDivisao,
    required this.areaTotal,
    required this.taxaAplicacao,
    required this.cargaAviao,
    required this.totalVoos,
    required this.voosCheios,
    required this.hectaresPorVooPadrao,
    required this.cargaVooPadrao,
    required this.volumeTotalCalda,
    required this.aguaVooPadrao,
    required this.produtosVooPadrao,
    this.produtosBase = const [],
    this.temVooParcial = false,
    this.areaVooParcial = 0.0,
    this.cargaVooParcial = 0.0,
    this.aguaVooParcial = 0.0,
    this.produtosVooParcial = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'dataHora': dataHora,
        'modoDivisao': modoDivisao,
        'areaTotal': areaTotal,
        'taxaAplicacao': taxaAplicacao,
        'cargaAviao': cargaAviao,
        'totalVoos': totalVoos,
        'voosCheios': voosCheios,
        'hectaresPorVooPadrao': hectaresPorVooPadrao,
        'cargaVooPadrao': cargaVooPadrao,
        'volumeTotalCalda': volumeTotalCalda,
        'aguaVooPadrao': aguaVooPadrao,
        'produtosVooPadrao': produtosVooPadrao,
        'produtosBase': produtosBase,
        'temVooParcial': temVooParcial,
        'areaVooParcial': areaVooParcial,
        'cargaVooParcial': cargaVooParcial,
        'aguaVooParcial': aguaVooParcial,
        'produtosVooParcial': produtosVooParcial,
      };

  factory ItemHistorico.fromJson(Map<String, dynamic> json) => ItemHistorico(
        id: json['id'],
        nome: json['nome'] ?? 'Cálculo',
        dataHora: json['dataHora'],
        modoDivisao: json['modoDivisao'] ?? 'cargaMaxima',
        areaTotal: (json['areaTotal'] as num).toDouble(),
        taxaAplicacao: (json['taxaAplicacao'] as num).toDouble(),
        cargaAviao: (json['cargaAviao'] as num).toDouble(),
        totalVoos: json['totalVoos'] ?? 0,
        voosCheios: json['voosCheios'] ?? 0,
        hectaresPorVooPadrao: ((json['hectaresPorVooPadrao'] ?? json['hectaresPorVooCheio'] ?? 0.0) as num).toDouble(),
        cargaVooPadrao: ((json['cargaVooPadrao'] ?? json['cargaAviao'] ?? 0.0) as num).toDouble(),
        volumeTotalCalda: (json['volumeTotalCalda'] as num).toDouble(),
        aguaVooPadrao: ((json['aguaVooPadrao'] ?? json['aguaVooCheio'] ?? 0.0) as num).toDouble(),
        produtosVooPadrao: List<String>.from(json['produtosVooPadrao'] ?? json['produtosVooCheio'] ?? []),
        produtosBase: List<Map<String, dynamic>>.from(json['produtosBase'] ?? []),
        temVooParcial: json['temVooParcial'] ?? false,
        areaVooParcial: ((json['areaVooParcial'] ?? 0.0) as num).toDouble(),
        cargaVooParcial: ((json['cargaVooParcial'] ?? 0.0) as num).toDouble(),
        aguaVooParcial: ((json['aguaVooParcial'] ?? 0.0) as num).toDouble(),
        produtosVooParcial: List<String>.from(json['produtosVooParcial'] ?? []),
      );
}

class HistoricoService {
  static const String _chave = 'historico_operacoes_ag';

  static Future<List<ItemHistorico>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chave);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => ItemHistorico.fromJson(e)).toList();
  }

  static Future<void> salvar(ItemHistorico item) async {
    final lista = await carregar();
    lista.insert(0, item);

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(lista.map((e) => e.toJson()).toList());
    await prefs.setString(_chave, jsonString);
  }

  static Future<void> deletarItem(String id) async {
    final lista = await carregar();
    lista.removeWhere((item) => item.id == id);

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(lista.map((e) => e.toJson()).toList());
    await prefs.setString(_chave, jsonString);
  }

  static Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}