import 'package:flutter/material.dart';
import 'package:get/get.dart';


/// Modelo base para os componentes.
/// Se o componente estiver ancorado (parent != null),
/// seu campo [position] representa o offset relativo ao pai.
class ContainerModel {
  final int id;
  Offset position;
  ContainerModel? parent;
  List<ContainerModel> children;
  bool isRelative; // indica se a posição é relativa (quando ancorado)
  bool isSelected; // para feedback visual

  ContainerModel({
    required this.id,
    required this.position,
    this.parent,
    List<ContainerModel>? children,
    this.isRelative = false,
    this.isSelected = false,
  }) : children = children ?? [];

  /// Calcula recursivamente a posição absoluta do componente.
  Offset getAbsolutePosition() {
    if (parent == null) return position;
    return parent!.getAbsolutePosition() + position;
  }



  /// Desancora o componente:
  /// Converte sua posição relativa (ao pai) em absoluta e remove o vínculo.
  void detach() {
    if (parent != null) {
      // Calcula a posição absoluta
      final absolutePos = getAbsolutePosition();
      // Remove este componente da lista de filhos do pai
      parent!.children.remove(this);
      // Define a posição absoluta e zera a flag de relativo
      position = absolutePos;
      parent = null;
      isRelative = false;
    }
  }
}

extension AnchorExtension on ContainerModel {
  /// Ancorar este componente ao [newParent]:
  /// Converte a posição absoluta em relativa ao novo pai e atualiza a hierarquia.
  void anchorTo(ContainerModel newParent) {
    // Se já estiver ancorado, remove da lista de filhos do pai antigo.
    if (parent != null) {
      parent!.children.remove(this);
    }
    // Calcula a posição absoluta do componente.
    final absolutePos = getAbsolutePosition();
    // Calcula a posição absoluta do novo pai.
    final parentAbs = newParent.getAbsolutePosition();
    // Define a posição relativa (offset) em relação ao novo pai.
    position = absolutePos - parentAbs;
    // Atualiza o pai e a lista de filhos.
    parent = newParent;
    newParent.children.add(this);
    isRelative = true;
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

/// Modelo para uma linha que conecta dois componentes.
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

/// Modelo para controle do pan (movimentação global).
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
class VisualPage extends StatelessWidget {
  final ContainerController controller = Get.put(ContainerController());
  final RxInt idCounter = 0.obs;
  VisualPage({Key? key}) : super(key: key);

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

  void _linkSelected() {
    final selected = controller.selectedContainers;
    if (selected.length == 2) {
      final newLine = LineModel(
        id: DateTime.now().millisecondsSinceEpoch,
        from: selected[0],
        to: selected[1],
      );
      controller.addLine(newLine);
    } else {
      Get.snackbar('Link', 'Selecione exatamente 2 elementos para vincular');
    }
  }
  
  void _anchorSelected() {
    final selected = controller.selectedContainers;
    if (selected.length == 2) {
      selected[0].anchorTo(         selected[1]
      );
      Get.snackbar('Ancora', 'Itens ancorados');
    
    } else {
      Get.snackbar('Ancora', 'Selecione exatamente 2 elementos para vincular');
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

  /// Nova função de desancorar:
  /// Para cada componente selecionado que está ancorado, converte sua posição relativa
  /// em absoluta e remove o vínculo com o pai.
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
                    // Desenha as linhas conectando os componentes.
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
                          // Se o componente estiver livre (desancorado), permite arrastar
                          onPanUpdate: (details) {
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
                              // Se estiver selecionado, borda laranja;
                              // Se livre, borda verde; caso contrário, preta.
                              border: Border.all(
                                color: container.isSelected
                                    ? Colors.orange
                                    : (container.parent == null ? Colors.green : Colors.black),
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
                                // Indicador de componente livre (desancorado).
                                if (container.parent == null)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.lock_open, size: 16, color: Colors.green),
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
          // Painel superior com os botões de ação.
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
                      onPressed: _linkSelected,
                      child: const Text('Vincular Selecionados'),
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
                      onPressed:  _anchorSelected
                   ,
                      child: const Text('Ancorar Selecionados'),
                    ),
                    
                    ElevatedButton(
                      onPressed: _detachSelected,
                      child: const Text('Desancorar Selecionados'),
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

/// CustomPainter que desenha as linhas conectando os componentes.
class LinePainter extends CustomPainter {
  final List<LineModel> lines;
  LinePainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red..strokeWidth = 2;
    for (var line in lines) {
      canvas.drawLine(line.from.getAbsolutePosition(), line.to.getAbsolutePosition(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
