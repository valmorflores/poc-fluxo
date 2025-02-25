import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Modelo base para os componentes.
/// Quando ancorado (parent != null), o campo [position] representa o offset relativo ao pai.
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

  /// Desancora este componente, convertendo sua posição relativa em absoluta.
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

/// Modelo de retângulo.
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

/// Modelo de círculo redimensionável.
class CircleModel extends ContainerModel {
  double radius;
  final Color color;

  CircleModel({
    required int id,
    required Offset position,
    this.radius = 10.0,
    required this.color,
    bool isRelative = false,
    bool isSelected = false,
  }) : super(
          id: id,
          position: position,
          isRelative: isRelative,
          isSelected: isSelected,
        );
}

/// Modelo de texto editável.
class TextModel extends ContainerModel {
  String text;

  TextModel({
    required int id,
    required Offset position,
    this.text = 'Edit me',
    bool isRelative = false,
    bool isSelected = false,
  }) : super(
          id: id,
          position: position,
          isRelative: isRelative,
          isSelected: isSelected,
        );
}

/// Modelo para uma porta (endpoint) – renderizada como um círculo.
class PortModel extends ContainerModel {
  final double diameter;
  final Color color;

  PortModel({
    required int id,
    required Offset position,
    this.diameter = 10,
    required this.color,
    bool isRelative = true,
    bool isSelected = false,
  }) : super(
          id: id,
          position: position,
          isRelative: isRelative,
          isSelected: isSelected,
        );
}

/// Modelo do "nó de decisão".
/// Será renderizado como um quadrado rotacionado (diamond) com três portas:
/// uma na extremidade esquerda e duas na direita (uma superior e outra inferior).
class DecisionModel extends ContainerModel {
  final double width;
  final double height;
  final Color color;

  DecisionModel({
    required int id,
    required Offset position,
    this.width = 100,
    this.height = 100,
    required this.color,
    bool isRelative = false,
    bool isSelected = false,
  }) : super(
          id: id,
          position: position,
          isRelative: isRelative,
          isSelected: isSelected,
        ) {
    // Porta selecionável à esquerda.
    children.add(PortModel(
      id: id * 10 + 1,
      position: Offset(-10, height / 2 - 5),
      color: Colors.blue,
    ));
    // Porta selecionável no quadrante superior direito.
    children.add(PortModel(
      id: id * 10 + 2,
      position: Offset(width, height / 4 - 5),
      color: Colors.blue,
    ));
    // Porta selecionável no quadrante inferior direito.
    children.add(PortModel(
      id: id * 10 + 3,
      position: Offset(width, (3 * height / 4) - 5),
      color: Colors.blue,
    ));
  }
}

/// Modelo de linha com opção de desenhar com curva.
class LineModel {
  final int id;
  final ContainerModel from;
  final ContainerModel to;
  final bool isCurved;
  final double curveIntensity;

  LineModel({
    required this.id,
    required this.from,
    required this.to,
    this.isCurved = false,
    this.curveIntensity = 20.0,
  });
}

/// Modelo de zoom.
class ZoomModel {
  double factor;
  ZoomModel({this.factor = 1.0});
  void setZoom(double newFactor) {
    factor = newFactor;
  }
}

/// Modelo para pan (movimentação global).
class MovementModel {
  Offset offset;
  MovementModel({this.offset = Offset.zero});
  void move(Offset delta) {
    offset += delta;
  }
}

/// Controller GetX que gerencia componentes, linhas, zoom e pan.
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

  /// Atualiza o pai de um componente – tornando-o relativo ao novo pai.
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

/// Extensão para ancorar um componente a outro.
/// Converte a posição absoluta do componente em uma posição relativa ao novo pai.
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

/// Página visual com área de desenho e painel de controles.
class VisualPage extends StatelessWidget {
  final ContainerController controller = Get.put(ContainerController());
  final RxInt idCounter = 0.obs;

  VisualPage({Key? key}) : super(key: key);

  void toggleSelection(ContainerModel container) {
    container.isSelected = !container.isSelected;
    controller.containerList.refresh();
  }

  // Funções para adicionar os diferentes componentes.
  void _addNewRectangle() {
    final newId = idCounter.value++;
    final newRect = RectangleModel(
      id: newId,
      position: Offset(50 + (idCounter.value * 20).toDouble(),
          50 + (idCounter.value * 20).toDouble()),
      color: Colors.primaries[newId % Colors.primaries.length],
    );
    controller.addContainer(newRect);
  }

  void _addNewText() {
    final newId = idCounter.value++;
    final newText = TextModel(
      id: newId,
      position: Offset(50 + (idCounter.value * 20).toDouble(),
          50 + (idCounter.value * 20).toDouble()),
      text: "Texto $newId",
    );
    controller.addContainer(newText);
  }

  void _addNewCircle() {
    final newId = idCounter.value++;
    final newCircle = CircleModel(
      id: newId,
      position: Offset(50 + (idCounter.value * 20).toDouble(),
          50 + (idCounter.value * 20).toDouble()),
      radius: 10.0,
      color: Colors.purple,
    );
    controller.addContainer(newCircle);
  }

  void _addNewDecision() {
    final newId = idCounter.value++;
    final newDecision = DecisionModel(
      id: newId,
      position: Offset(50 + (idCounter.value * 20).toDouble(),
          50 + (idCounter.value * 20).toDouble()),
      width: 100,
      height: 100,
      color: Colors.orange,
    );
    controller.addContainer(newDecision);
  }

  // Funções de link (reta ou curva), desvinculação, ancoragem, desancoragem e remoção.
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

  void _anchorSelected() {
    final selected = controller.selectedContainers;
    if (selected.length == 2) {
      selected[1].anchorTo(selected[0]);
      controller.containerList.refresh();
    } else {
      Get.snackbar('Ancorar', 'Selecione exatamente 2 elementos para ancorar');
    }
  }

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

  void _zoomIn() {
    final currentZoom = controller.zoomModel.value.factor;
    controller.setZoom(currentZoom + 0.1);
  }

  void _zoomOut() {
    final currentZoom = controller.zoomModel.value.factor;
    if (currentZoom > 0.2) controller.setZoom(currentZoom - 0.1);
  }

  /// Função que constrói o widget para cada componente, conforme seu tipo.
  Widget buildContainerWidget(ContainerModel container) {
    final absPos = container.getAbsolutePosition();
    // Retângulo
    if (container is RectangleModel) {
      return Positioned(
        left: absPos.dx,
        top: absPos.dy,
        child: GestureDetector(
          onTap: () => toggleSelection(container),
          onLongPress: () => toggleSelection(container),
          onPanUpdate: (details) {
            if (container.parent == null) {
              final newPos = container.position + details.delta;
              controller.moveContainer(container, newPos);
            }
          },
          child: Container(
            width: container.width,
            height: container.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: container.color,
              border: Border.all(
                color: container.isSelected
                    ? Colors.orange
                    : (container.parent == null ? Colors.green : Colors.black),
                width: container.isSelected ? 4 : 2,
              ),
            ),
            child: Text('ID: ${container.id}',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    // Círculo redimensionável
    else if (container is CircleModel) {
      return Positioned(
        left: absPos.dx,
        top: absPos.dy,
        child: GestureDetector(
          onTap: () => toggleSelection(container),
          onLongPress: () => toggleSelection(container),
          onPanUpdate: (details) {
            if (container.parent == null) {
              final newPos = container.position + details.delta;
              controller.moveContainer(container, newPos);
            }
          },
          child: Container(
            width: container.radius * 2,
            height: container.radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: container.color,
              border: Border.all(
                color: container.isSelected
                    ? Colors.orange
                    : (container.parent == null ? Colors.green : Colors.black),
                width: container.isSelected ? 4 : 2,
              ),
            ),
            child: Stack(
              children: [
                // Handle para redimensionar (arraste no canto inferior direito)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      double newRadius = container.radius + details.delta.dx;
                      if (newRadius < 5) newRadius = 5;
                      container.radius = newRadius;
                      controller.containerList.refresh();
                    },
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Texto editável
    else if (container is TextModel) {
      return Positioned(
        left: absPos.dx,
        top: absPos.dy,
        child: GestureDetector(
          onTap: () => toggleSelection(container),
          onLongPress: () => toggleSelection(container),
          onPanUpdate: (details) {
            if (container.parent == null) {
              final newPos = container.position + details.delta;
              controller.moveContainer(container, newPos);
            }
          },
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: container.isSelected
                    ? Colors.orange
                    : (container.parent == null ? Colors.green : Colors.black),
                width: container.isSelected ? 4 : 2,
              ),
            ),
            child: container.isSelected
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 200),
                    child: TextField(
                      controller:
                          TextEditingController(text: container.text),
                      onChanged: (val) {
                        container.text = val;
                      },
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : Text(container.text, style: TextStyle(color: Colors.black)),
          ),
        ),
      );
    }
    // Nó de decisão com três portas selecionáveis.
    else if (container is DecisionModel) {
      return Positioned(
        left: absPos.dx,
        top: absPos.dy,
        child: GestureDetector(
          onTap: () => toggleSelection(container),
          onLongPress: () => toggleSelection(container),
          onPanUpdate: (details) {
            if (container.parent == null) {
              final newPos = container.position + details.delta;
              controller.moveContainer(container, newPos);
            }
          },
          child: Container(
            width: container.width,
            height: container.height,
            child: Stack(
              children: [
                // Renderiza o nó de decisão como um quadrado rotacionado (diamond).
                Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: container.width,
                    height: container.height,
                    decoration: BoxDecoration(
                      color: container.color,
                      border: Border.all(
                        color: container.isSelected
                            ? Colors.orange
                            : (container.parent == null ? Colors.green : Colors.black),
                        width: container.isSelected ? 4 : 2,
                      ),
                    ),
                  ),
                ),
                // Renderiza as portas (os filhos do nó de decisão).
                ...container.children.where((child) => child is PortModel).map((port) {
                  final portPos = port.position; // posição relativa ao nó de decisão
                  return Positioned(
                    left: portPos.dx,
                    top: portPos.dy,
                    child: GestureDetector(
                      onTap: () => toggleSelection(port),
                      onLongPress: () => toggleSelection(port),
                      onPanUpdate: (details) {
                        // Permite mover a porta se necessário (caso seja necessário reposicionamento).
                        if (port.parent == null) {
                          final newPos = port.position + details.delta;
                          controller.moveContainer(port, newPos);
                        }
                      },
                      child: Container(
                        width: (port as PortModel).diameter,
                        height: port.diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: port.color,
                          border: Border.all(
                            color: port.isSelected
                                ? Colors.orange
                                : (port.parent == null ? Colors.green : Colors.black),
                            width: port.isSelected ? 4 : 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      );
    }
    // Caso padrão para outros tipos.
    else {
      return Positioned(
        left: absPos.dx,
        top: absPos.dy,
        child: GestureDetector(
          onTap: () => toggleSelection(container),
          onLongPress: () => toggleSelection(container),
          onPanUpdate: (details) {
            if (container.parent == null) {
              final newPos = container.position + details.delta;
              controller.moveContainer(container, newPos);
            }
          },
          child: Container(
            width: 100,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey,
              border: Border.all(
                color: container.isSelected
                    ? Colors.orange
                    : (container.parent == null ? Colors.green : Colors.black),
                width: container.isSelected ? 4 : 2,
              ),
            ),
            child: Text('ID: ${container.id}', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visual Page Demo'),
      ),
      body: Stack(
        children: [
          // Área de desenho com pan e zoom.
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
                    // Desenha as linhas (links) entre os componentes.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinePainter(controller.lineList),
                      ),
                    ),
                    // Renderiza os componentes adicionados.
                    ...controller.containerList.map((c) => buildContainerWidget(c)).toList(),
                  ],
                ),
              );
            }),
          ),
          // Painel superior com botões para adicionar e manipular componentes.
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(onPressed: _addNewRectangle, child: Text('Add Retângulo')),
                    ElevatedButton(onPressed: _addNewText, child: Text('Add Texto')),
                    ElevatedButton(onPressed: _addNewCircle, child: Text('Add Círculo')),
                    ElevatedButton(onPressed: _addNewDecision, child: Text('Add Decisão')),
                    ElevatedButton(onPressed: () => _linkSelected(curved: false), child: Text('Link Reta')),
                    ElevatedButton(onPressed: () => _linkSelected(curved: true, curveIntensity: 30.0), child: Text('Link Curva')),
                    ElevatedButton(onPressed: _unlinkSelected, child: Text('Desvincular Selecionados')),
                    ElevatedButton(onPressed: _detachSelected, child: Text('Desancorar Selecionados')),
                    ElevatedButton(onPressed: _anchorSelected, child: Text('Ancorar Selecionados')),
                    ElevatedButton(onPressed: _removeSelected, child: Text('Apagar Selecionados')),
                    ElevatedButton(onPressed: _zoomIn, child: Text('Zoom In')),
                    ElevatedButton(onPressed: _zoomOut, child: Text('Zoom Out')),
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

/// CustomPainter que desenha as linhas conectando os componentes.
/// Se [isCurved] for true, utiliza uma curva quadrática com [curveIntensity].
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
