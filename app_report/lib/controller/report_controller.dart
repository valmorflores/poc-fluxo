import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/band_model.dart';
import 'package:http/http.dart' as http;

import 'report_data_controller.dart';
import 'report_print_controller.dart';

class ReportController extends GetxController {
  var bands = <Band>[].obs;
  var datasets = <ReportDataset>[].obs; // Lista de datasets
  var includeDatasets = true.obs; // Flag para incluir datasets no JSON

  // 🔹 Adiciona um novo dataset ao relatório
  void addDataset(String name, List<Map<String, dynamic>> data) {
    datasets.add(ReportDataset(name: name, data: data));
  }

  // 🔹 Remove um dataset pelo nome
  void removeDataset(String name) {
    datasets.removeWhere((dataset) => dataset.name == name);
  }

  void addBand(BandType type) {
    bands.add(Band(type));
  }

  void deleteSelected() {
    bands.removeWhere((band) => band.isSelected.value);
    for (var band in bands) {
      band.elements.removeWhere((element) => element.isSelected.value);
    }
  }

  void saveReport() {
    Map<String, dynamic> reportJson = {
      "bands": bands.map((band) => band.toJson()).toList(),
    };

    if (includeDatasets.value) {
      reportJson["datasets"] =
          datasets.map((dataset) => dataset.toJson()).toList();
    }

    String jsonString = jsonEncode(reportJson);
    Clipboard.setData(ClipboardData(text: jsonString));
    Get.snackbar("Salvo!", "Estrutura copiada para a área de transferência.");
  }

  String getJsonReport() {
    Map<String, dynamic> reportJson = {
      "bands": bands.map((band) => band.toJson()).toList(),
    };

    if (includeDatasets.value) {
      reportJson["datasets"] =
          datasets.map((dataset) => dataset.toJson()).toList();
    }

    String jsonString = jsonEncode(reportJson);
    return jsonString;
  }

  Future<void> loadJSONOld(String path) async {
    if (path.isEmpty) {
      Get.snackbar("Erro", "Digite um caminho válido para carregar o JSON.");
      return;
    }

    try {
      String jsonString;
      if (path.startsWith("http")) {
        // Carregar JSON de uma URL
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          jsonString = response.body;
        } else {
          throw Exception("Erro ao carregar JSON da URL.");
        }
      } else {
        // Carregar JSON de um arquivo local
        jsonString = await rootBundle.loadString(path);
      }

      List<dynamic> jsonData = jsonDecode(jsonString);

      bands.clear();
      for (var bandData in jsonData) {
        Band band = Band.fromJson(bandData);
        bands.add(band);
      }

      bands.clear();
      datasets.clear();

      Get.snackbar("Sucesso", "Relatório carregado com sucesso!");
    } catch (e) {
      Get.snackbar("Erro", "Falha ao carregar JSON: $e");
    }
  }

  Future<void> loadJSON(String path) async {
    if (path.isEmpty) {
      Get.snackbar("Erro", "Digite um caminho válido para carregar o JSON.");
      return;
    }

    try {
      String jsonString;

      if (path.startsWith("http")) {
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          jsonString = response.body;
        } else {
          throw Exception("Erro ao carregar JSON da URL.");
        }
      } else {
        jsonString = await rootBundle.loadString(path);
      }

      // 🔹 Converte o JSON para um objeto Dart
      dynamic jsonData = jsonDecode(jsonString);

      // 🔹 Se jsonData for uma lista, pega o primeiro item
      if (jsonData is List) {
        if (jsonData.isEmpty) {
          throw Exception("O JSON está vazio.");
        }
        jsonData = jsonData.first; // Usa o primeiro elemento da lista
      }

      // 🔹 Agora verifica se é um Map<String, dynamic>
      if (jsonData is! Map<String, dynamic>) {
        throw Exception(
            "Formato de JSON inválido. Esperado um objeto JSON com chaves.");
      }

      bands.clear();
      datasets.clear();

      // 🔹 Se existem bandas, adiciona ao relatório
      if (jsonData.containsKey("bands") && jsonData["bands"] is List) {
        for (var bandData in jsonData["bands"]) {
          if (bandData is Map<String, dynamic>) {
            bands.add(Band.fromJson(bandData));
          }
        }
      }

      // 🔹 Se existem datasets, adiciona à lista de datasets
      if (jsonData.containsKey("datasets") && jsonData["datasets"] is List) {
        for (var datasetData in jsonData["datasets"]) {
          if (datasetData is Map<String, dynamic>) {
            datasets.add(ReportDataset.fromJson(datasetData));
          }
        }
      }

      Get.snackbar("Sucesso", "Relatório carregado com sucesso!");
    } catch (e) {
      Get.snackbar("Erro", "Falha ao carregar JSON: $e");
    }
  }

  void toggleBandSelection(Band band) {
    bool newState = !band.isSelected.value;
    band.isSelected.value = newState;
    for (var element in band.elements) {
      element.isSelected.value = newState;
    }
  }

  void printPDF() {
    final controller = ReportPrintController();

    Map<String, dynamic> reportJson = {
      "bands": bands.map((band) => band.toJson()).toList(),
    };

    reportJson["datasets"] =
        datasets.map((dataset) => dataset.toJson()).toList();

    String jsonString = jsonEncode(reportJson);

    /*
  const jsonString = '''
  {
    "bands": [
      {
        "type": "Header",
        "isSelected": false,
        "elements": [
          {"type": "text", "text": "Id", "width": 100.0, "height": 40.0, "isSelected": false, "isEditing": true},
          {"type": "field", "text": "Nome", "width": 100.0, "height": 40.0, "isSelected": false, "isEditing": false},
          {"type": "text", "text": "Endereço", "width": 643.0, "height": 42.0, "isSelected": false, "isEditing": true}
        ]
      },
      {
        "type": "MasterData",
        "dataset": "SQLQuery1",
        "isSelected": false,
        "elements": [
          {"type": "text", "text": "[SQLQuery1.COMPANY]", "width": 392.0, "height": 41.0, "isSelected": false, "isEditing": false}
        ]
      }
    ],
    "datasets": [
      {
        "type": "Dataset",
        "name": "SQLQuery1",
        "data": [
          {"ID": 1, "COMPANY": "TechNova Soluções", "ADDRESS": "Rua das Flores, 123", "CITY": "São Paulo", "STATE": "SP", "ZIP": "01234-567", "EMAIL": "contato@technova.com.br"},
          {"ID": 2, "COMPANY": "XyZ", "ADDRESS": "Rua das Rosas, 456", "CITY": "Rio de Janeiro", "STATE": "RJ", "ZIP": "98765-432", "EMAIL": "suporte@xyz.com"}
        ]
      }
    ]
  }
  ''';*/

    controller.printReport(jsonString);
    //Get.snackbar("Sucesso", "Relatório gerado com sucesso");
  }
}
