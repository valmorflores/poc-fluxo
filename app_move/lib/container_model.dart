import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Modelo base para todos os componentes com informações de posição e hierarquia.
class ContainerModel {
  final int id;
  Offset position;
  ContainerModel? parent;
  List<ContainerModel> children;
  Offset offset;         // Offset relativo a um objeto de referência, se necessário.
  bool isRelative;       // Indica se a posição é relativa.
  ContainerModel? root;  // Referência ao objeto base (root), se for relativo.

  ContainerModel({
    required this.id,
    required this.position,
    this.parent,
    List<ContainerModel>? children,
    this.offset = Offset.zero,
    this.isRelative = false,
    this.root,
  }) : children = children ?? [];
}

/// Exemplo de um componente retangular, que estende o ContainerModel.
class RectangleModel extends ContainerModel {
  final double width;
  final double height;
  final Color color;

  RectangleModel({
    required int id,
    required Offset position,
    this.width = 100,
    this.height = 50,
    this.color = Colors.blue,
    ContainerModel? parent,
    List<ContainerModel>? children,
    Offset offset = Offset.zero,
    bool isRelative = false,
    ContainerModel? root,
  }) : super(
          id: id,
          position: position,
          parent: parent,
          children: children,
          offset: offset,
          isRelative: isRelative,
          root: root,
        );
}

/// Exemplo de um modelo para uma linha que interliga dois ContainerModel.
class LineModel {
  final int id;
  final ContainerModel from;
  final ContainerModel to;

  LineModel({
    required this.id,
    required this.from,
    required this.to,
  });
}

/// Modelo para controle do zoom.
class ZoomModel {
  double factor;

  ZoomModel({this.factor = 1.0});

  void setZoom(double newFactor) {
    factor = newFactor;
  }
}

/// Modelo para controle de movimentação (pan).
class MovementModel {
  Offset offset;

  MovementModel({this.offset = Offset.zero});

  void move(Offset delta) {
    offset += delta;
  }
}

/// Controller GetX que gerencia a lista de componentes, linhas e também os objetos de zoom e movimento.
class ContainerController extends GetxController {
  // Lista observável dos componentes.
  var containerList = <ContainerModel>[].obs;
  // Lista observável para as linhas que interligam componentes.
  var lineList = <LineModel>[].obs;

  // Objeto observável de zoom.
  var zoomModel = ZoomModel(factor: 1.0).obs;
  // Objeto observável para a movimentação (pan) da tela.
  var movementModel = MovementModel(offset: Offset.zero).obs;

  // Métodos para manipulação dos componentes.

  /// Adiciona um novo componente.
  void addContainer(ContainerModel container) {
    containerList.add(container);
  }

  /// Remove um componente e o desassocia do pai, se houver.
  void removeContainer(ContainerModel container) {
    container.parent?.children.remove(container);
    containerList.remove(container);
  }

  /// Atualiza o pai de um componente, atualizando as listas de filhos conforme necessário.
  void updateParent(ContainerModel container, ContainerModel? newParent) {
    container.parent?.children.remove(container);
    container.parent = newParent;
    if (newParent != null) {
      newParent.children.add(container);
    }
  }

  /// Move um componente para uma nova posição.
  void moveContainer(ContainerModel container, Offset newPosition) {
    container.position = newPosition;
    containerList.refresh(); // Atualiza a lista para refletir as mudanças na UI.
  }

  /// Adiciona uma nova linha que conecta dois componentes.
  void addLine(LineModel line) {
    lineList.add(line);
  }

  // Métodos para manipulação do zoom.

  /// Atualiza o fator de zoom.
  void setZoom(double newFactor) {
    zoomModel.update((val) {
      if (val != null) {
        val.setZoom(newFactor);
      }
    });
  }

  // Métodos para manipulação da movimentação (pan).

  /// Move o offset de pan, possibilitando a movimentação da tela.
  void movePan(Offset delta) {
    movementModel.update((val) {
      if (val != null) {
        val.move(delta);
      }
    });
  }
}
