import 'package:flutter/material.dart';

class ColorUtils {
  /// Exporta uma cor do Flutter para formato HEX (#RRGGBB ou #AARRGGBB)
  static String exportColorHex(Color color, {bool includeAlpha = false}) {
    String hex = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    return includeAlpha ? "#$hex" : "#${hex.substring(2)}";
  }

  /// Importa uma cor no formato HEX (#RRGGBB ou #AARRGGBB) para um objeto Color no Flutter
  static Color importColorHex(String hexColor) {
    hexColor = hexColor.trim().replaceAll("#", "");

    if (hexColor.length == 6) {
      hexColor =
          "FF$hexColor"; // Adiciona opacidade total caso seja apenas RRGGBB
    }

    if (hexColor.length != 8) {
      throw FormatException("Formato de cor inválido: #$hexColor");
    }

    int colorValue = int.parse(hexColor, radix: 16);
    return Color(colorValue);
  }
}
