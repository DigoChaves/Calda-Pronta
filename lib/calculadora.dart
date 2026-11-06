enum ModoDivisao {
  cargaMaxima, // Voos cheios na capacidade + saideira
  cargaIgual,  // Carga dividida igualmente em todos os voos
}

class Produto {
  final String nome;
  final double dosePorHa; // L/ha

  Produto({
    required this.nome,
    required this.dosePorHa,
  });
}

class ResultadoOperacao {
  final ModoDivisao modoDivisao;
  final double areaTotalHa;
  final double hectaresPorVooCheio; // Capacidade máxima teórica em ha
  final int totalVoos;
  final double volumeTotalCalda;

  // Receita do Voo Padrão (Em Carga Máxima = Voo Cheio / Em Carga Igual = Voo Igualado)
  final double areaPorVooPadrao;
  final double cargaVooPadrao;
  final Map<String, double> produtosPorVooPadrao;
  final double aguaPorVooPadrao;

  // Dados exclusivos do modo Carga Máxima (Saideira)
  final int voosCheios;
  final bool temVooParcial;
  final double areaVooParcial;
  final double cargaVooParcial;
  final Map<String, double> produtosPorVooParcial;
  final double aguaPorVooParcial;

  // Totais do Talhão
  final Map<String, double> produtosTotais;
  final double aguaTotal;

  ResultadoOperacao({
    required this.modoDivisao,
    required this.areaTotalHa,
    required this.hectaresPorVooCheio,
    required this.totalVoos,
    required this.volumeTotalCalda,
    required this.areaPorVooPadrao,
    required this.cargaVooPadrao,
    required this.produtosPorVooPadrao,
    required this.aguaPorVooPadrao,
    required this.voosCheios,
    required this.temVooParcial,
    required this.areaVooParcial,
    required this.cargaVooParcial,
    required this.produtosPorVooParcial,
    required this.aguaPorVooParcial,
    required this.produtosTotais,
    required this.aguaTotal,
  });
}

class CalculadoraAgricola {
  static ResultadoOperacao calcular({
    required double areaTotalHa,
    required double taxaAplicacao,
    required double cargaAviao,
    required List<Produto> produtos,
    ModoDivisao modoDivisao = ModoDivisao.cargaMaxima,
  }) {
    if (taxaAplicacao <= 0 || cargaAviao <= 0 || areaTotalHa <= 0) {
      throw ArgumentError('Os valores de área, taxa e carga devem ser maiores que zero.');
    }

    final hectaresPorVooCheio = cargaAviao / taxaAplicacao;
    final totalVoos = (areaTotalHa / hectaresPorVooCheio).ceil();
    final volumeTotalCalda = areaTotalHa * taxaAplicacao;

    final Map<String, double> produtosTotais = {};
    double somaVolumeProdTotais = 0.0;

    for (var p in produtos) {
      final qtdTotal = areaTotalHa * p.dosePorHa;
      produtosTotais[p.nome] = qtdTotal;
      somaVolumeProdTotais += qtdTotal;
    }

    final aguaTotal = volumeTotalCalda - somaVolumeProdTotais;

    if (modoDivisao == ModoDivisao.cargaIgual) {
      // === MODO CARGAS IGUALADAS ===
      final areaPorVooPadrao = areaTotalHa / totalVoos;
      final cargaVooPadrao = volumeTotalCalda / totalVoos;

      if (cargaVooPadrao > cargaAviao) {
        throw Exception('A carga calculada por voo excede a capacidade do avião.');
      }

      final Map<String, double> produtosPorVooPadrao = {};
      double somaVolumeProdVooPadrao = 0.0;

      for (var p in produtos) {
        final qtdVoo = areaPorVooPadrao * p.dosePorHa;
        produtosPorVooPadrao[p.nome] = qtdVoo;
        somaVolumeProdVooPadrao += qtdVoo;
      }

      final aguaPorVooPadrao = cargaVooPadrao - somaVolumeProdVooPadrao;

      return ResultadoOperacao(
        modoDivisao: modoDivisao,
        areaTotalHa: areaTotalHa,
        hectaresPorVooCheio: hectaresPorVooCheio,
        totalVoos: totalVoos,
        volumeTotalCalda: volumeTotalCalda,
        areaPorVooPadrao: areaPorVooPadrao,
        cargaVooPadrao: cargaVooPadrao,
        produtosPorVooPadrao: produtosPorVooPadrao,
        aguaPorVooPadrao: aguaPorVooPadrao,
        voosCheios: totalVoos,
        temVooParcial: false,
        areaVooParcial: 0.0,
        cargaVooParcial: 0.0,
        produtosPorVooParcial: {},
        aguaPorVooParcial: 0.0,
        produtosTotais: produtosTotais,
        aguaTotal: aguaTotal,
      );
    } else {
      // === MODO CARGA MÁXIMA + SAIDEIRA ===
      final voosCheios = (areaTotalHa / hectaresPorVooCheio).floor();
      final areaAtendidaVoosCheios = voosCheios * hectaresPorVooCheio;
      final areaVooParcial = double.parse((areaTotalHa - areaAtendidaVoosCheios).toStringAsFixed(2));
      final temVooParcial = areaVooParcial > 0.01;

      final Map<String, double> produtosPorVooCheio = {};
      final Map<String, double> produtosPorVooParcial = {};
      double somaVolumeProdVooCheio = 0.0;
      double somaVolumeProdVooParcial = 0.0;

      for (var p in produtos) {
        final qtdVooCheio = hectaresPorVooCheio * p.dosePorHa;
        final qtdVooParcial = temVooParcial ? (areaVooParcial * p.dosePorHa) : 0.0;

        produtosPorVooCheio[p.nome] = qtdVooCheio;
        produtosPorVooParcial[p.nome] = qtdVooParcial;

        somaVolumeProdVooCheio += qtdVooCheio;
        somaVolumeProdVooParcial += qtdVooParcial;
      }

      if (somaVolumeProdVooCheio > cargaAviao) {
        throw Exception('A soma dos produtos (${somaVolumeProdVooCheio.toStringAsFixed(1)}L) excede a capacidade do avião.');
      }

      final aguaPorVooCheio = cargaAviao - somaVolumeProdVooCheio;
      final cargaVooParcial = temVooParcial ? (areaVooParcial * taxaAplicacao) : 0.0;
      final aguaPorVooParcial = temVooParcial ? (cargaVooParcial - somaVolumeProdVooParcial) : 0.0;

      return ResultadoOperacao(
        modoDivisao: modoDivisao,
        areaTotalHa: areaTotalHa,
        hectaresPorVooCheio: hectaresPorVooCheio,
        totalVoos: totalVoos,
        volumeTotalCalda: volumeTotalCalda,
        areaPorVooPadrao: hectaresPorVooCheio,
        cargaVooPadrao: cargaAviao,
        produtosPorVooPadrao: produtosPorVooCheio,
        aguaPorVooPadrao: aguaPorVooCheio,
        voosCheios: voosCheios,
        temVooParcial: temVooParcial,
        areaVooParcial: areaVooParcial,
        cargaVooParcial: cargaVooParcial,
        produtosPorVooParcial: produtosPorVooParcial,
        aguaPorVooParcial: aguaPorVooParcial,
        produtosTotais: produtosTotais,
        aguaTotal: aguaTotal,
      );
    }
  }
}