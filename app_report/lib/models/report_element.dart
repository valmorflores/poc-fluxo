import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ElementType { text, field }

class ReportElement {
  final ElementType type;
  var width = 100.0.obs;
  var height = 40.0.obs;
  var left = 10.0.obs;
  var top = 10.0.obs;
  var isSelected = false.obs;
  var isEditing = false.obs;
  final TextEditingController controller = TextEditingController();

  ReportElement(this.type);

  void toggleSelection() {
    isSelected.value = !isSelected.value;
  }

  void startEditing() {
    isEditing.value = true;
  }

  void stopEditing() {
    isEditing.value = false;
  }

  factory ReportElement.fromJson(Map<String, dynamic> json) {
    ReportElement element = ReportElement(ElementType.values
        .firstWhere((e) => e.toString().split('.').last == json["type"]));
    element.controller.text = json["text"];
    element.width.value = json["width"];
    element.height.value = json["height"];
    element.left.value = json["left"];
    element.top.value = json["top"];
    element.isSelected.value = json["isSelected"] ?? false;
    element.isEditing.value = json["isEditing"] ?? false;
    return element;
  }

  // 🔹 **Função `toJson()` Atualizada**
  Map<String, dynamic> toJson() => {
        "type": type
            .toString()
            .split('.')
            .last, // Converte enum para string legível
        "text": controller.text, // Texto do elemento
        "width": width.value, // Largura do elemento
        "height": height.value, // Altura do elemento
        "left": left.value, // Left
        "top": top.value, // Top
        "isSelected": isSelected.value, // Se está selecionado
        "isEditing": isEditing.value, // Se está em edição
      };
}
