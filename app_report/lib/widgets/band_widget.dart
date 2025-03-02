import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/report_controller.dart';
import 'resizable_element_widget.dart';

class BandWidget extends StatelessWidget {
  final int bandIndex;
  final ReportController controller = Get.find();

  BandWidget({required this.bandIndex});

  @override
  Widget build(BuildContext context) {
    final band = controller.bands[bandIndex];

    return GestureDetector(
      onTap: () => controller.toggleBandSelection(band),
      child: Obx(() {
        return Container(
          height: band.height.value +
              100, // Altura convencional + espaço para margens visuais apenas
          decoration: BoxDecoration(
            border: Border.all(
                color: band.isSelected.value ? Colors.blue : Colors.transparent,
                width: 2),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      band.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    if (band.relation_dataset.value != "")
                      Chip(
                          label: Row(
                        children: [
                          Text(band.relation_dataset.value + ' : '),
                          if (band.relation_fields.value != "")
                            Text(band.relation_fields.value),
                        ],
                      )),
                    SizedBox(
                      width: 20,
                    ),
                    Text(band.dataset.value),
                  ]),
                  const SizedBox(height: 8),
                  // 🔹 Substituindo `Wrap` por `Stack`
                  Expanded(
                    child: Stack(
                      children: band.elements
                          .map((e) => ResizableElementWidget(element: e))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
