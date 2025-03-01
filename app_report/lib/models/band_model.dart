import 'package:get/get.dart';

import 'report_element.dart';

enum BandType { header, masterData, detailData, footer }

// Model
class Band {
  final BandType type;
  var elements = <ReportElement>[].obs;
  RxDouble height = 200.0.obs;
  var isSelected = false.obs;
  var dataset = "".obs;
  var relation_dataset = "".obs;
  var relation_fields = "".obs;

  Band(this.type);

  String get title {
    switch (type) {
      case BandType.header:
        return "Header";
      case BandType.masterData:
        return "MasterData";
      case BandType.detailData:
        return "DetailData";
      case BandType.footer:
        return "Footer";
    }
  }

  void addElement(ElementType type) {
    elements.add(ReportElement(type));
  }

  Map<String, dynamic> toJson() => {
        "type": title,
        if (dataset.value != "") "dataset": dataset.value,
        if (relation_dataset.value != "")
          "relation_dataset": relation_dataset.value,
        if (relation_fields.value != "")
          "relation_fields": relation_fields.value,
        "isSelected": isSelected.value,
        "height": height.value,
        "elements": elements.map((e) => e.toJson()).toList(),
      };

  /* Complexa //  
  factory Band.fromJson(Map<String, dynamic> json) {
    Band band = Band(BandType.values
        .firstWhere((e) => e.toString().split('.').last == json["type"]));
    band.isSelected.value = json["isSelected"] ?? false;
    band.elements.addAll((json["elements"] as List)
        .map((e) => ReportElement.fromJson(e))
        .toList());
    return band;
  }*/

  factory Band.fromJson(Map<String, dynamic> json) {
    // Verifica se o JSON tem a chave "type"
    String bandTypeString = json["type"];
    BandType bandType = BandType.header; // Default

    // Verifica qual tipo de banda é
    if (bandTypeString == "MasterData") {
      bandType = BandType.masterData;
    } else if (bandTypeString == "DetailData") {
      bandType = BandType.detailData;
    } else if (bandTypeString == "Footer") {
      bandType = BandType.footer;
    }

    // Cria a banda
    Band band = Band(bandType);

    // Verifica se existe a chave "isSelected" e define o valor
    if (json.containsKey("isSelected")) {
      band.isSelected.value = json["isSelected"];
    }

    if (json.containsKey("dataset")) {
      band.dataset.value = json["dataset"];
    }

    // DetailData precisa disso / Relation Dataseat
    if (json.containsKey("relation_dataset")) {
      band.relation_dataset.value = json["relation_dataset"];
    }

    // DetailData precisa disso / Relation Fields
    if (json.containsKey("relation_fields")) {
      band.relation_fields.value = json["relation_fields"];
    }

    if (json.containsKey("height")) {
      band.height.value = json["height"] ?? 200;
    }

    // Verifica se existe a chave "elements" e adiciona os elementos
    if (json.containsKey("elements") && json["elements"] is List) {
      List<dynamic> elementsList = json["elements"];

      // Percorre a lista de elementos do JSON
      for (var elementJson in elementsList) {
        if (elementJson is Map<String, dynamic>) {
          // Converte o JSON para um objeto ReportElement e adiciona na banda
          ReportElement element = ReportElement.fromJson(elementJson);
          band.elements.add(element);
        }
      }
    }

    return band;
  }
}
