import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Modelo base para os componentes.
/// Quando ancorado (parent != null), [position] é considerado como offset relativo ao pai.
class ContainerModel {
  final int id;
  Offset position;
  ContainerModel? parent;
  List<ContainerModel> children;
  bool isRelative;
  bool isSelected;

  ContainerModel({
    required this.id,
    required this.position,
    this.parent,
    List<ContainerModel>? children,
    this.isRelative = false,
    this.isSelected = false,
  }) : children = children ?? [];

  /// Retorna a posição absoluta deste componente.
  Offset getAbsolutePosition() {
    if (parent == null) return position;
    return parent!.getAbsolutePosition() + position;
  }

  /// Desancora o componente, convertendo sua posição relativa em absoluta.
  void detach() {
    if (parent != null) {
      final absPos = getAbsolutePosition();
      parent!.children.remove(this);
      parent = null;
      isRelative = false;
      position = absPos;
    }
  }
}

/// Exemplo de componente retangular.
class RectangleModel extends ContainerModel {
  final double width;
  final double height;
  final Color color;

  RectangleModel({
    required int id,
    required Offset position,
    this.width = 100,
    this.height = 50,
    required this.color,
    ContainerModel? parent,
    List<ContainerModel>? children,
    bool isRelative = false,
    bool isSelected = false,
  }) : super(
          id: id,
          position: position,
          parent: parent,
          children: children,
          isRelative: isRelative,
          isSelected: isSelected,
        );
}

/// Modelo para a linha que conecta dois componentes, com opção de curva.
class LineModel {
  final int id;
  final ContainerModel from;
  final ContainerModel to;
  final bool isCurved;        // Se true, a linha será desenhada com curva.
  final double curveIntensity; // Intensidade da curva.

  LineModel({
    required this.id,
    required this.from,
    required this.to,
    this.isCurved = false,
    this.curveIntensity = 20.0,
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

/// Modelo para controle do pan (movimentação global).
class MovementModel {
  Offset offset;
  MovementModel({this.offset = Offset.zero});
  void move(Offset delta) {
    offset += delta;
  }
}

/// Controller GetX que gerencia os componentes, linhas, zoom e pan.
class ContainerController extends GetxController {
  var containerList = <ContainerModel>[].obs;
  var lineList = <LineModel>[].obs;
  var zoomModel = ZoomModel(factor: 1.0).obs;
  var movementModel = MovementModel(offset: Offset.zero).obs;

  void addContainer(ContainerModel container) {
    containerList.add(container);
  }

  void removeContainer(ContainerModel container) {
    container.parent?.children.remove(container);
    containerList.remove(container);
  }

  /// Atualiza o pai de um componente e marca como relativo.
  void updateParent(ContainerModel container, ContainerModel? newParent) {
    container.parent?.children.remove(container);
    container.parent = newParent;
    if (newParent != null) {
      newParent.children.add(container);
      container.isRelative = true;
    }
    containerList.refresh();
  }

  void moveContainer(ContainerModel container, Offset newPosition) {
    container.position = newPosition;
    containerList.refresh();
  }

  void addLine(LineModel line) {
    lineList.add(line);
  }

  void removeLine(LineModel line) {
    lineList.remove(line);
  }

  void setZoom(double newFactor) {
    zoomModel.update((val) {
      if (val != null) val.setZoom(newFactor);
    });
  }

  void movePan(Offset delta) {
    movementModel.update((val) {
      if (val != null) val.move(delta);
    });
  }

  List<ContainerModel> get selectedContainers =>
      containerList.where((c) => c.isSelected).toList();
}

/// Página visual com área de desenho e controles.
class VisualSinglePage extends StatelessWidget {
  final ContainerController controller = Get.put(ContainerController());
  final RxInt idCounter = 0.obs;

  VisualSinglePage({Key? key}) : super(key: key);

  /// Cria um novo retângulo com posição incremental.
  void _addNewRectangle() {
    final newId = idCounter.value++;
    final newRect = RectangleModel(
      id: newId,
      position: Offset(50 + (idCounter.value * 20), 50 + (idCounter.value * 20)),
      color: Colors.primaries[newId % Colors.primaries.length],
    );
    controller.addContainer(newRect);
  }

  /// Vincula dois componentes selecionados, criando uma linha.
  /// Parâmetro [curved] define se a linha será curva; [curveIntensity] ajusta a intensidade.
  void _linkSelected({bool curved = false, double curveIntensity = 20.0}) {
    final selected = controller.selectedContainers;
    if (selected.length == 2) {
      final newLine = LineModel(
        id: DateTime.now().millisecondsSinceEpoch,
        from: selected[0],
        to: selected[1],
        isCurved: curved,
        curveIntensity: curveIntensity,
      );
      controller.addLine(newLine);
    } else {
      Get.snackbar('Link', 'Selecione exatamente 2 elementos para vincular');
    }
  }

  void _unlinkSelected() {
    final selected = controller.selectedContainers;
    if (selected.length == 2) {
      final lineToRemove = controller.lineList.firstWhere(
        (line) =>
            (line.from.id == selected[0].id && line.to.id == selected[1].id) ||
            (line.from.id == selected[1].id && line.to.id == selected[0].id),
        
      );
      if (lineToRemove != null) {
        controller.removeLine(lineToRemove);
      } else {
        Get.snackbar('Desvincular', 'Não há linha entre os elementos selecionados');
      }
    } else {
      Get.snackbar('Desvincular', 'Selecione exatamente 2 elementos para desvincular');
    }
  }

  void _removeSelected() {
    final selected = controller.selectedContainers;
    if (selected.isNotEmpty) {
      for (var container in selected) {
        controller.removeContainer(container);
      }
    } else {
      Get.snackbar('Remover', 'Nenhum elemento selecionado');
    }
  }

  /// Desancora os componentes selecionados, convertendo sua posição relativa em absoluta.
  void _detachSelected() {
    final selected = controller.selectedContainers;
    if (selected.isNotEmpty) {
      for (var container in selected) {
        if (container.parent != null) {
          container.detach();
        }
      }
      controller.containerList.refresh();
    } else {
      Get.snackbar('Desancorar', 'Nenhum elemento selecionado');
    }
  }

  /// Função para ancorar um item em outro.
  /// Ao selecionar exatamente 2 elementos, o segundo será ancorado no primeiro.
  void _anchorSelected() {
    final selected = controller.selectedContainers;
    if (selected.length == 2) {
      selected[1].anchorTo(selected[0]);
      controller.containerList.refresh();
    } else {
      Get.snackbar('Ancorar', 'Selecione exatamente 2 elementos para ancorar');
    }
  }

  void _zoomIn() {
    final currentZoom = controller.zoomModel.value.factor;
    controller.setZoom(currentZoom + 0.1);
  }

  void _zoomOut() {
    final currentZoom = controller.zoomModel.value.factor;
    if (currentZoom > 0.2) controller.setZoom(currentZoom - 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Page Demo'),
      ),
      body: Stack(
        children: [
          // Área de desenho com zoom e pan.
          GestureDetector(
            onPanUpdate: (details) {
              controller.movePan(details.delta);
            },
            child: Obx(() {
              return Transform(
                transform: Matrix4.identity()
                  ..translate(controller.movementModel.value.offset.dx,
                      controller.movementModel.value.offset.dy)
                  ..scale(controller.zoomModel.value.factor),
                child: Stack(
                  children: [
                    // Desenha as linhas entre os componentes.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinePainter(controller.lineList),
                      ),
                    ),
                    // Desenha cada componente na posição absoluta.
                    ...controller.containerList.map((container) {
                      final absPos = container.getAbsolutePosition();
                      return Positioned(
                        left: absPos.dx,
                        top: absPos.dy,
                        child: GestureDetector(
                          onLongPress: () {
                            container.isSelected = !container.isSelected;
                            controller.containerList.refresh();
                          },
                          onTap: () {
                            container.isSelected = !container.isSelected;
                            controller.containerList.refresh();
                          },
                          onPanUpdate: (details) {
                            // Permite arrastar livremente apenas se estiver desancorado.
                            if (container.parent == null) {
                              final newPos = container.position + details.delta;
                              controller.moveContainer(container, newPos);
                            }
                          },
                          child: Container(
                            width: container is RectangleModel
                                ? (container as RectangleModel).width
                                : 100,
                            height: container is RectangleModel
                                ? (container as RectangleModel).height
                                : 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: container is RectangleModel
                                  ? (container as RectangleModel).color
                                  : Colors.grey,
                              border: Border.all(
                                color: container.isSelected
                                    ? Colors.orange
                                    : (container.parent == null
                                        ? Colors.green
                                        : Colors.black),
                                width: container.isSelected ? 4 : 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    'ID: ${container.id}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                if (container.parent != null)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.lock_open,
                                        size: 16, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }),
          ),
          // Painel superior com botões de ação.
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: _addNewRectangle,
                      child: const Text('Adicionar Elemento'),
                    ),
                    ElevatedButton(
                      onPressed: () => _linkSelected(curved: false),
                      child: const Text('Link Reta'),
                    ),
                    ElevatedButton(
                      onPressed: () => _linkSelected(curved: true, curveIntensity: 30.0),
                      child: const Text('Link Curva'),
                    ),
                    ElevatedButton(
                      onPressed: _unlinkSelected,
                      child: const Text('Desvincular Selecionados'),
                    ),
                    ElevatedButton(
                      onPressed: _removeSelected,
                      child: const Text('Remover Selecionados'),
                    ),
                    ElevatedButton(
                      onPressed: _detachSelected,
                      child: const Text('Desancorar Selecionados'),
                    ),
                    ElevatedButton(
                      onPressed: _anchorSelected,
                      child: const Text('Ancorar Selecionados'),
                    ),
                    ElevatedButton(
                      onPressed: _zoomIn,
                      child: const Text('Zoom In'),
                    ),
                    ElevatedButton(
                      onPressed: _zoomOut,
                      child: const Text('Zoom Out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extensão para adicionar a funcionalidade de ancorar um componente a outro.
extension AnchorExtension on ContainerModel {
  void anchorTo(ContainerModel newParent) {
    if (parent != null) {
      parent!.children.remove(this);
    }
    final absPos = getAbsolutePosition();
    final parentAbs = newParent.getAbsolutePosition();
    position = absPos - parentAbs;
    parent = newParent;
    newParent.children.add(this);
    isRelative = true;
  }
}

/// CustomPainter para desenhar as linhas conectando os componentes.
/// Se [isCurved] for true, desenha uma curva com base em [curveIntensity]; caso contrário, desenha uma reta.
class LinePainter extends CustomPainter {
  final List<LineModel> lines;
  LinePainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var line in lines) {
      final start = line.from.getAbsolutePosition();
      final end = line.to.getAbsolutePosition();

      if (line.isCurved) {
        final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        final perpendicular = len != 0 ? Offset(-dy / len, dx / len) : Offset.zero;
        final controlPoint = midPoint + perpendicular * line.curveIntensity;
        final path = Path();
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


