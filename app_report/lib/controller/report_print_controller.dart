import 'dart:io';
import 'dart:typed_data';
import 'package:app_report/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:printing/printing.dart';

class ReportPrintController {
  final RxString pdfPath = ''.obs;
  
  // Define a fixed page height for A4 paper
  final double pageHeight = PdfPageFormat.a4.height;
  final double pageWidth = PdfPageFormat.a4.width;
  
  // Fator de escala para converter do width do editor (1024) para A4 (595.28)
  // Isso ajudará a posicionar elementos mantendo a proporção visual
  final double scaleFactor = PdfPageFormat.a4.width / 1024;

  Future<Uint8List> generateReport(String jsonString) async {
    final pdf = pw.Document();
    final Map<String, dynamic> reportData = jsonDecode(jsonString);

    // Extract bands and datasets from JSON
    final List<dynamic> bands = reportData['bands'];
    final List<dynamic> datasets = reportData['datasets'];

    // Map datasets by name for easy access
    final Map<String, List<Map<String, dynamic>>> datasetMap = {
      for (var ds in datasets)
        ds['name']: List<Map<String, dynamic>>.from(
            ds['data'].map((e) => Map<String, dynamic>.from(e)))
    };

    // Process bands and generate pages
    final pages = await _processReportPages(bands, datasetMap);
    
    // Add all pages to the document
    for (var page in pages) {
      pdf.addPage(page);
    }

    return await pdf.save();
  }

  Future<List<pw.Page>> _processReportPages(
      List<dynamic> bands,
      Map<String, List<Map<String, dynamic>>> datasetMap) async {
    List<pw.Page> pages = [];
    List<pw.Widget> currentPageWidgets = [];
    double currentY = 0;
    int pageNumber = 1;
    
    // Get header and footer if they exist
    final headerBand = bands.firstWhere(
      (band) => band['type'] == 'Header',
      orElse: () => null,
    );
    final footerBand = bands.firstWhere(
      (band) => band['type'] == 'Footer',
      orElse: () => null,
    );
    
    double headerHeight = headerBand != null ? (headerBand['height']?.toDouble() ?? 0.0) * scaleFactor : 0.0;
    double footerHeight = footerBand != null ? (footerBand['height']?.toDouble() ?? 0.0) * scaleFactor : 0.0;
    
    // Available height for content (excluding header and footer)
    double availableHeight = pageHeight - headerHeight - footerHeight;
    
    // Função para adicionar uma nova página
    void addNewPage() {
      // Completar a página atual com o rodapé
      if (footerBand != null) {
        currentPageWidgets.add(
          pw.Positioned(
            top: pageHeight - footerHeight,
            child: _buildFixedBand(footerBand['elements'], 'Footer', footerHeight, pageNumber)
          )
        );
      }
      
      // Adicionar página ao documento
      pages.add(_createPage(currentPageWidgets, pageHeight));
      pageNumber++;
      
      // Iniciar nova página
      currentPageWidgets = [];
      if (headerBand != null) {
        currentPageWidgets.add(
          pw.Positioned(
            top: 0,
            child: _buildFixedBand(headerBand['elements'], 'Header', headerHeight, pageNumber)
          )
        );
      }
      currentY = headerHeight;
    }
    
    // Add header if it exists
    if (headerBand != null) {
      currentPageWidgets.add(
        pw.Positioned(
          top: 0,
          child: _buildFixedBand(headerBand['elements'], 'Header', headerHeight, pageNumber)
        )
      );
      currentY = headerHeight;
    }
    
    // Process data bands
    for (var band in bands) {
      final String bandType = band['type'];
      if (bandType == 'Header' || bandType == 'Footer') continue;
      
      final List<dynamic> elements = band['elements'];
      final double bandHeight = (band['height']?.toDouble() ?? 0.0) * scaleFactor;
      final String? datasetName = band['dataset'];
      
      // MasterData
      if (bandType == 'MasterData' && datasetName != null) {
        final List<Map<String, dynamic>>? masterDataset = datasetMap[datasetName];
        if (masterDataset != null) {
          for (var masterRow in masterDataset) {
            // Check if we need a new page
            if (currentY + bandHeight > pageHeight - footerHeight) {
              addNewPage();
            }
            
            // Render MasterData
            currentPageWidgets.add(
              pw.Positioned(
                top: currentY,
                child: _buildDataBand(elements, masterRow, datasetName, bandHeight)
              )
            );
            currentY += bandHeight;
            
            // Process related DetailData
            final detailBands = bands.where((b) =>
                b['type'] == 'DetailData' && 
                b['relation_dataset'] == datasetName).toList();
              
            for (var detailBand in detailBands) {
              final String detailDatasetName = detailBand['dataset'];
              final String relationFields = detailBand['relation_fields'] ?? '';
              final double detailBandHeight = (detailBand['height']?.toDouble() ?? 0.0) * scaleFactor;
              final List<dynamic> detailElements = detailBand['elements'];
              final List<Map<String, dynamic>>? detailDataset = datasetMap[detailDatasetName];

              if (detailDataset != null) {
                final relatedDetails = _getRelatedDetails(
                    masterRow, detailDataset, relationFields);
                  
                for (var detailRow in relatedDetails) {
                  // Check if we need a new page
                  if (currentY + detailBandHeight > pageHeight - footerHeight) {
                    addNewPage();
                  }
                  
                  currentPageWidgets.add(
                    pw.Positioned(
                      top: currentY,
                      child: _buildDataBand(detailElements, detailRow, detailDatasetName, detailBandHeight)
                    )
                  );
                  currentY += detailBandHeight;
                }
              }
            }
          }
        }
      }
    }
    
    // Add footer to the last page
    if (footerBand != null) {
      currentPageWidgets.add(
        pw.Positioned(
          top: pageHeight - footerHeight,
          child: _buildFixedBand(footerBand['elements'], 'Footer', footerHeight, pageNumber)
        )
      );
    }
    
    // Add the last page
    if (currentPageWidgets.isNotEmpty) {
      pages.add(_createPage(currentPageWidgets, pageHeight));
    }
    
    return pages;
  }
  
  pw.Page _createPage(List<pw.Widget> pageWidgets, double height) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          width: pageWidth,
          height: height,
          child: pw.Stack(
            children: pageWidgets,
          ),
        );
      },
    );
  }

  pw.Widget _buildFixedBand(List<dynamic> elements, String bandType, double height, int pageNumber) {
    List<pw.Widget> elementWidgets = [];
    
    for (var element in elements) {
      String text = element['text'];
      final double width = element['width'].toDouble() * scaleFactor;
      final double elementHeight = element['height'].toDouble() * scaleFactor;
      final double top = element['top'].toDouble() * scaleFactor;
      final double left = element['left'].toDouble() * scaleFactor;
      final double fontSize = element['fontSize']?.toDouble() ?? 12.0;
      final bool showBorder = element['showBorder'] ?? false;
      final String? fontWeight = element['fontWeight'];
      final String? alignment = element['alignment'];
      
      // Aplicar alinhamento do texto
      pw.TextAlign textAlign = pw.TextAlign.left;
      if (alignment == 'center') {
        textAlign = pw.TextAlign.center;
      } else if (alignment == 'right') {
        textAlign = pw.TextAlign.right;
      }
      
      // Process static text replacements
      if (bandType == 'Header' || bandType == 'Footer') {
        text = text.replaceAll(
            '[DATE]', DateTime.now().toString().split(' ')[0]);
        text = text.replaceAll(
            '[TIME]', DateTime.now().toString().split(' ')[1].substring(0, 8));
        text = text.replaceAll('[PAGE#]', pageNumber.toString());
      }
      
      elementWidgets.add(
        pw.Positioned(
          left: left,
          top: top,
          child: pw.Container(
            width: width,
            height: elementHeight,
            decoration: showBorder 
              ? pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromHex(ColorUtils.exportColorHex(Colors.black))
                  )
                )
              : null,
            alignment: _getPdfAlignment(alignment),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: fontSize * scaleFactor, // Escala a fonte também
                fontWeight: fontWeight == 'bold' ? pw.FontWeight.bold : null,
              ),
              textAlign: textAlign,
            ),
          ),
        )
      );
    }
    
    return pw.Container(
      width: pageWidth,
      height: height,
      child: pw.Stack(
        children: elementWidgets,
      ),
    );
  }

  pw.Widget _buildDataBand(
      List<dynamic> elements, Map<String, dynamic> dataRow, String datasetName, double height) {
    List<pw.Widget> elementWidgets = [];
    
    for (var element in elements) {
      String text = element['text'];
      final double width = element['width'].toDouble() * scaleFactor;
      final double elementHeight = element['height'].toDouble() * scaleFactor;
      final double top = element['top'].toDouble() * scaleFactor;
      final double left = element['left'].toDouble() * scaleFactor;
      final double fontSize = element['fontSize']?.toDouble() ?? 12.0;
      final bool showBorder = element['showBorder'] ?? false;
      final String? fontWeight = element['fontWeight'];
      final String? alignment = element['alignment'];
      final String? format = element['format']; // Formato para números, datas, etc.
      
      // Aplicar alinhamento do texto
      pw.TextAlign textAlign = pw.TextAlign.left;
      if (alignment == 'center') {
        textAlign = pw.TextAlign.center;
      } else if (alignment == 'right') {
        textAlign = pw.TextAlign.right;
      }
      
      // Replace dynamic placeholders
      if (text.startsWith('[') && text.endsWith(']')) {
        final fieldRef = text.substring(1, text.length - 1);
        final parts = fieldRef.split('.');
        if (parts.length == 2 && parts[0] == datasetName) {
          final value = dataRow[parts[1]];
          if (value != null) {
            text = _formatFieldValue(value, format);
          } else {
            text = '';
          }
        }
      }
      
      elementWidgets.add(
        pw.Positioned(
          left: left,
          top: top,
          child: pw.Container(
            width: width,
            height: elementHeight,
            decoration: showBorder 
              ? pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromHex(ColorUtils.exportColorHex(Colors.black))
                  )
                )
              : null,
            alignment: _getPdfAlignment(alignment),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: fontSize * scaleFactor, // Escala a fonte também
                fontWeight: fontWeight == 'bold' ? pw.FontWeight.bold : null,
              ),
              textAlign: textAlign,
            ),
          ),
        )
      );
    }
    
    return pw.Container(
      width: pageWidth,
      height: height,
      child: pw.Stack(
        children: elementWidgets,
      ),
    );
  }

  // Converte o alinhamento do Flutter para o alinhamento do PDF
  pw.Alignment _getPdfAlignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return pw.Alignment.center;
      case 'right':
        return pw.Alignment.centerRight;
      case 'left':
      default:
        return pw.Alignment.centerLeft;
    }
  }
  
  // Função para formatar valores com base no formato especificado
  String _formatFieldValue(dynamic value, String? format) {
    if (format == null) return value.toString();
    
    if (value is num && format.startsWith('currency')) {
      // Formato para moeda (ex: R$ 1.234,56)
      final double numValue = value.toDouble();
      return 'R\$ ${numValue.toStringAsFixed(2).replaceAll('.', ',')}';
    } else if (value is DateTime && format == 'date') {
      // Formato para data (ex: 01/01/2023)
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    } else if (value is num && format == 'percent') {
      // Formato para percentual (ex: 75,5%)
      return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
    }
    
    return value.toString();
  }

  List<Map<String, dynamic>> _getRelatedDetails(Map<String, dynamic> masterRow,
      List<Map<String, dynamic>> detailDataset, String relationFields) {
    final RegExp relationPattern = RegExp(r'(\w+\.\w+)\s*==\s*(\w+\.\w+)');
    final match = relationPattern.firstMatch(relationFields);
    if (match == null) return [];

    final masterField = match.group(1)!.split('.')[1]; // ex.: "ID"
    final detailField = match.group(2)!.split('.')[1]; // ex.: "CLIENTID"

    return detailDataset
        .where((detailRow) => masterRow[masterField] == detailRow[detailField])
        .toList();
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
    } catch (e) {
      print('Erro ao gerar ou imprimir o relatório: $e');
      rethrow;
    }
  }

  Future<void> printSaveReport(String jsonString) async {
    final pdfBytes = await generateReport(jsonString);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}