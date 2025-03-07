import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/report_element.dart';

class ResizableElementWidget extends StatelessWidget {
  final ReportElement element;

  ResizableElementWidget({required this.element});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Positioned(
        left: element.left.value,
        top: element.top.value,
        child: GestureDetector(
          onTap: () => element.toggleSelection(),
          onLongPress: () => element.startEditing(),
          onPanUpdate: (details) {
            // 🔹 Movendo dinamicamente o elemento conforme o arrasto
            element.left.value += details.delta.dx;
            element.top.value += details.delta.dy;
          },
          child: Stack(
            children: [
              Container(
                  width: element.width.value,
                  height: element.height.value,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: element.isSelected.value
                          ? Colors.blue
                          : element.showBorder.value
                              ? Colors.black
                              : Colors.black12,
                    ),
                    color: Colors.white,
                  ),
                  child: element.isEditing.value
                      ? TextField(
                          controller: element.controller,
                          onSubmitted: (_) => element.stopEditing(),
                          autofocus: true,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(18.0, 5, 5, 5),
                          child: Text(
                            element.controller.text,
                            style: TextStyle(
                                fontSize: element.fontSize.value / 1,
                                color: element.textColor.value),
                          ),
                        )),
              // 🔹 Ícone de movimentação no canto superior esquerdo
              Positioned(
                left: 0,
                top: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    element.left.value += details.delta.dx;
                    element.top.value += details.delta.dy;
                  },
                  child: const Icon(Icons.drag_indicator,
                      size: 18, color: Colors.black),
                  onTap: () {
                    element.stopEditing();
                  },
                ),
              ),
              // 🔹 Ícone de redimensionamento no canto inferior direito
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    element.width.value += details.delta.dx;
                    element.height.value += details.delta.dy;
                  },
                  child: const Icon(Icons.crop_square,
                      size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
