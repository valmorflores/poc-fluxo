import 'dart:convert';
import 'package:get/get.dart';

class ReportDataController {
  // Lista de conjuntos de dados (Datasets)
  var datasets = <ReportDataset>[].obs;

  // 🔹 Construtor Padrão Corrigido
  ReportDataController();

  // Adiciona um novo dataset
  void addDataset(String name, List<Map<String, dynamic>> data) {
    datasets.add(ReportDataset(name: name, data: data));
  }

  // Encontra um valor pelo nome do dataset e campo
  String? getValue(String reference) {
    if (!reference.startsWith("[") || !reference.endsWith("]")) {
      return null;
    }

    String cleanRef = reference.substring(1, reference.length - 1);
    List<String> parts = cleanRef.split(".");
    if (parts.length != 2) {
      return null;
    }

    String datasetName = parts[0];
    String fieldName = parts[1];

    for (var dataset in datasets) {
      if (dataset.name == datasetName) {
        if (dataset.data.isNotEmpty &&
            dataset.data.first.containsKey(fieldName)) {
          return dataset.data.first[fieldName].toString();
        }
      }
    }

    return null;
  }

  // 🔹 Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      "type": "Dataset",
      "datasets": datasets.map((dataset) => dataset.toJson()).toList(),
    };
  }

  // 🔹 Construtor para criar um ReportDataController a partir de JSON
  factory ReportDataController.fromJson(Map<String, dynamic> json) {
    ReportDataController controller = ReportDataController();

    if (json.containsKey("datasets") && json["datasets"] is List) {
      for (var datasetJson in json["datasets"]) {
        if (datasetJson is Map<String, dynamic>) {
          controller.datasets.add(ReportDataset.fromJson(datasetJson));
        }
      }
    }

    return controller;
  }
}

class ReportDataset {
  String name;
  List<Map<String, dynamic>> data;

  // 🔹 Construtor Padrão Corrigido
  ReportDataset({required this.name, required this.data});

  // 🔹 Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      "type": "Dataset",
      "name": name,
      "data": data,
    };
  }

  // 🔹 Construtor para criar um Dataset a partir de JSON
  factory ReportDataset.fromJson(Map<String, dynamic> json) {
    return ReportDataset(
      name: json["name"] ?? "",
      data: (json["data"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}
