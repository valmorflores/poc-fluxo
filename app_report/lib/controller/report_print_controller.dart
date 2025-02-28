import 'dart:io';
import 'dart:typed_data';
import 'package:get/get_rx/get_rx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';

import 'package:printing/printing.dart';

class ReportPrintController {
  final RxString pdfPath = ''.obs;

  Future<Uint8List> generateReport(String jsonString) async {
    final pdf = pw.Document();
    final Map<String, dynamic> reportData = jsonDecode(jsonString);

    // Extrair bands e datasets do JSON
    final List<dynamic> bands = reportData['bands'];
    final List<dynamic> datasets = reportData['datasets'];

    // Mapear datasets por nome para fácil acesso
    final Map<String, List<dynamic>> datasetMap = {
      for (var ds in datasets) ds['name']: ds['data']
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _buildBands(bands, datasetMap),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  List<pw.Widget> _buildBands(
      List<dynamic> bands, Map<String, List<dynamic>> datasetMap) {
    List<pw.Widget> widgets = [];
    double totalTop = 0.0; // Deslocamento vertical acumulado

    for (var band in bands) {
      final String bandType = band['type'];
      final List<dynamic> elements = band['elements'];
      final String? datasetName = band['dataset'];
      final double bandHeight =
          band['height']?.toDouble() ?? 0.0; // Altura da banda

      // Se não houver dataset, renderiza apenas uma vez
      if (datasetName == null) {
        widgets.add(_buildBandSection(bandType, elements, null, totalTop));
        totalTop +=
            bandHeight; // Incrementa o deslocamento pela altura da banda
      }
      // Se houver dataset (como MasterData), faz loop nos dados
      else {
        final List<dynamic>? dataset = datasetMap[datasetName];
        if (dataset != null) {
          for (var dataRow in dataset) {
            widgets
                .add(_buildBandSection(bandType, elements, dataRow, totalTop));
            totalTop +=
                bandHeight; // Incrementa o deslocamento pela altura da banda para cada registro
          }
        }
      }
    }

    return widgets;
  }

  pw.Widget _buildBandSection(String bandType, List<dynamic> elements,
      Map<String, dynamic>? dataRow, double totalTop) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Título da banda (opcional, apenas para visualização)
          if (bandType == 'Header')
            pw.Text(
              bandType,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          pw.Row(
            children: elements.map((element) {
              String text = element['text'];
              final double width = element['width'].toDouble();
              final double height = element['height'].toDouble();
              final double top =
                  element['top'].toDouble(); // Top inicial do elemento
              final double left = element['left'].toDouble();

              // Substituir placeholders [Dataset.Field] pelos valores reais
              if (dataRow != null &&
                  text.startsWith('[') &&
                  text.endsWith(']')) {
                final fieldRef = text.substring(1, text.length - 1);
                final parts = fieldRef.split('.');
                if (parts.length == 2) {
                  final value = dataRow[parts[1]];
                  text = value?.toString() ?? '';
                }
              }

              // Usar totalTop como base para o deslocamento vertical, somado ao top inicial
              return pw.Positioned(
                left: left,
                top:
                    totalTop + top, // Deslocamento acumulado mais o top inicial
                child: pw.Container(
                  width: width,
                  height: height,
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight:
                          bandType == 'Header' ? pw.FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 10), // Espaçamento entre seções
        ],
      ),
    );
  }

  Future<String> savePdfTemporarily(Uint8List pdfBytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/report_temp.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  Future<void> printReport(String jsonString) async {
    try {
      final pdfBytes = await generateReport(jsonString);
      final pdfPath = await savePdfTemporarily(pdfBytes);
      this.pdfPath.value = pdfPath;
      // Aqui, você pode usar PdfPreview em sua UI. Por exemplo, em um GetX controller ou StatefulWidget:
      // - Se usar GetX, atualize o estado com o pdfPath ou pdfBytes.
      // - Se usar um StatefulWidget, chame setState para exibir o PdfPreview.
      /*await Printing.layoutPdf(
          onLayout: (format) async =>
              pdfBytes); // Mantém a impressão como opção-**/
    } catch (e) {
      print('Erro ao gerar ou imprimir o relatório: $e');
      rethrow;
    }
  }

  // Método para salvar ou visualizar o PDF
  Future<void> printSaveReport(String jsonString) async {
    final pdfBytes = await generateReport(jsonString);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}

/*
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:printing/printing.dart';

class ReportPrintController {
  Future<Uint8List> generateReport(String jsonString) async {
    final pdf = pw.Document();
    final Map<String, dynamic> reportData = jsonDecode(jsonString);

    // Extrair bands e datasets do JSON
    final List<dynamic> bands = reportData['bands'] ?? [];
    final List<dynamic> datasets = reportData['datasets'] ?? [];

    // Mapear datasets por nome para fácil acesso
    final Map<String, List<dynamic>> datasetMap = {
      for (var ds in datasets) ds['name']: ds['data'] ?? []
    };

    // Limitar o número de páginas
    const int maxPages = 10;
    int pageCount = 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: maxPages,
        build: (pw.Context context) {
          List<pw.Widget> pages = [];
          List<pw.Widget> currentPageWidgets = [];

          for (var band in bands) {
            final String bandType = band['type'] ?? 'Unknown';
            final List<dynamic> elements = band['elements'] ?? [];
            final String? datasetName = band['dataset'];

            print(
                'Processando banda: $bandType, dataset: $datasetName, elementos: ${elements.length}');

            // Se não houver dataset, renderiza apenas uma vez
            if (datasetName == null) {
              currentPageWidgets
                  .add(_buildBandSection(bandType, elements, null));
            }
            // Se houver dataset, faz loop nos dados (não deve ser o caso para Header)
            else {
              final List<dynamic>? dataset = datasetMap[datasetName];
              if (dataset != null && dataset.isNotEmpty) {
                for (var dataRow in dataset) {
                  currentPageWidgets
                      .add(_buildBandSection(bandType, elements, dataRow));
                }
              }
            }

            // Forçar nova página para evitar acumulação excessiva
            if (currentPageWidgets.isNotEmpty) {
              pages.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: currentPageWidgets,
              ));
              currentPageWidgets = [];
              pageCount++;
              if (pageCount >= maxPages) {
                throw Exception(
                    'Número máximo de páginas ($maxPages) atingido.');
              }
            }
          }

          return pages;
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildBandSection(
      String bandType, List<dynamic> elements, Map<String, dynamic>? dataRow) {
    return pw.Container(
      height: 842, // Tamanho máximo da página A4 (em pontos)
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (bandType == 'Header')
            pw.Text(
              bandType,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          // Usar Row em vez de Stack para testar
          pw.Row(
            children: (elements ?? []).map((element) {
              String text = element['text'] ?? '';
              final double width = element['width']?.toDouble() ?? 100.0;
              final double height = element['height']?.toDouble() ?? 20.0;
              final double left = element['left']?.toDouble() ?? 0.0;
              final double top = element['top']?.toDouble() ?? 0.0;

              print(
                  'Elemento: text=$text, width=$width, height=$height, left=$left, top=$top');

              // Usar uma fonte padrão com suporte a Unicode (por exemplo, Times Roman)
              final font = pw.Font.times();

              // Substituir placeholders [Dataset.Field] pelos valores reais
              if (dataRow != null &&
                  text.startsWith('[') &&
                  text.endsWith(']')) {
                final fieldRef = text.substring(1, text.length - 1);
                final parts = fieldRef.split('.');
                if (parts.length == 2) {
                  final value = dataRow[parts[1]];
                  text = value?.toString() ?? '';
                }
              }

              return pw.Container(
                width: width,
                height: height,
                alignment: pw.Alignment.topLeft, // Garantir alinhamento correto
                child: pw.Text(
                  text,
                  maxLines:
                      1, // Limitar a uma linha para evitar expansão vertical
                  overflow: pw.TextOverflow.clip, // Truncar texto longo
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    fontWeight:
                        bandType == 'Header' ? pw.FontWeight.bold : null,
                  ),
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> printReport(String jsonString) async {
    try {
      final pdfBytes = await generateReport(jsonString);
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      print('Erro ao gerar ou imprimir o relatório: $e');
      rethrow;
    }
  }
}
*/
