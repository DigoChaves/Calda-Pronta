import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'historico_service.dart';

class PdfService {
  static Future<Uint8List> gerarPdf(ItemHistorico item, {String prefixoAviao = '', String cultura = ''}) async {
    final pdf = pw.Document();

    final isIgualado = item.modoDivisao == 'cargaIgual';
    final isCargaReduzida = item.cargaVooPadrao < (item.cargaAviao - 0.01);
    final isIgualadoEfetivo = isIgualado && isCargaReduzida;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. CABEÇALHO TIPO FICHA OPERACIONAL
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green800,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RELATÓRIO OPERACIONAL DE APLICAÇÃO',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'CALDA PRONTA - AVIAÇÃO AGRÍCOLA',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'DATA: ${item.dataHora}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        ),
                        if (prefixoAviao.isNotEmpty)
                          pw.Text(
                            'AERONAVE: $prefixoAviao',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.yellow300),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 2. DADOS DO CLIENTE E OPERAÇÃO
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Operação / Cliente: ${item.nome}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        if (cultura.isNotEmpty) pw.Text('Cultura / Alvo: $cultura', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Área Total: ${item.areaTotal.toStringAsFixed(1)} ha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Vazão / Taxa: ${item.taxaAplicacao.toStringAsFixed(1)} L/ha', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 3. RESUMO DA CALDA E DIVISÃO DE VOOS
              pw.Text('RESUMO DE CARGA E PLANO DE VOO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green900)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [
                      pw.Text('Volume Total Calda', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('${item.volumeTotalCalda.toStringAsFixed(1)} L', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Capacidade Tanque', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('${item.cargaAviao.toStringAsFixed(1)} L', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Total de Voos', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('${item.totalVoos}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green900)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Cobertura / Voo', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('${item.hectaresPorVooPadrao.toStringAsFixed(1)} ha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 4. DOSAGEM DE PRODUTOS POR VOO PADRÃO
              pw.Text(
                isIgualadoEfetivo ? 'DOSAGEM DE PRODUTOS POR VOO IGUALADO' : 'DOSAGEM DE PRODUTOS POR VOO CHEIO',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green900),
              ),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: ['Produto / Insumo', 'Dose p/ Hectare', 'Qtd. por Voo (${item.cargaVooPadrao.toStringAsFixed(0)}L)'],
                data: item.produtosBase.map((p) {
                  final dose = (p['dosePorHa'] as num).toDouble();
                  final qtdVoo = dose * item.hectaresPorVooPadrao;
                  return [
                    p['nome'].toString(),
                    '${dose.toStringAsFixed(2)} L/ha',
                    '${qtdVoo.toStringAsFixed(2)} L',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 4),
              pw.Text('💧 Água de Diluição por Voo: ${item.aguaVooPadrao.toStringAsFixed(1)} L', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
              pw.SizedBox(height: 14),

              // 5. VOO DE FECHAMENTO (SE HOUVER)
              if (!isIgualadoEfetivo && item.temVooParcial) ...[
                pw.Text('DETALHAMENTO DO VOO DE FECHAMENTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.orange900)),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.orange300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Área do Fechamento: ${item.areaVooParcial.toStringAsFixed(1)} ha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('Volume no Tanque: ${item.cargaVooParcial.toStringAsFixed(1)} L', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Produtos no Voo de Fechamento:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ...item.produtosVooParcial.map((p) => pw.Text('  • $p', style: const pw.TextStyle(fontSize: 9))),
                      pw.SizedBox(height: 2),
                      pw.Text('💧 Água na Saideira/Fechamento: ${item.aguaVooParcial.toStringAsFixed(1)} L', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // 6. CAMPO DE REGISTRO CLIMÁTICO DE PISTA (ESTILO RELATÓRIO OFICIAL)
              pw.Text('CONDIÇÕES CLIMÁTICAS DE PISTA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Temp: ______ °C', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Umidade: ______ %', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Vento: ______ km/h', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Direção: ________', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),

              pw.Spacer(),

              // 7. ASSINATURAS E CAMPO DE VALIDAÇÃO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Container(width: 160, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Piloto Agrícola / Reg. ANAC', style: const pw.TextStyle(fontSize: 9)),
                  ]),
                  pw.Column(children: [
                    pw.Container(width: 160, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Resp. Técnico / Cliente', style: const pw.TextStyle(fontSize: 9)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gerado por Calda Pronta Mobile', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Documento Operacional de Campo', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> compartilharOuImprimir(ItemHistorico item) async {
    final pdfBytes = await gerarPdf(item);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Relatorio_Aplicacao_${item.nome.replaceAll(' ', '_')}.pdf',
    );
  }
}