import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gerador de Relatórios',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ReportGeneratorPage(),
    );
  }
}

class ReportGeneratorPage extends StatelessWidget {
  final ReportController controller = Get.put(ReportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Gerador de Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: controller.deleteSelected,
          ),
        ],
      ),
      body: Row(
        children: [
          // Menu lateral
          Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[800],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opções',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SidebarButton(label: "Header", onPressed: () => controller.addBand(BandType.header)),
                SidebarButton(label: "MasterData", onPressed: () => controller.addBand(BandType.masterData)),
                SidebarButton(label: "DetailData", onPressed: () => controller.addBand(BandType.detailData)),
                SidebarButton(label: "Footer", onPressed: () => controller.addBand(BandType.footer)),
              ],
            ),
          ),
          // Área de relatório
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))],
                ),
                child: Obx(() => ListView.builder(
                      itemCount: controller.bands.length,
                      itemBuilder: (context, index) {
                        return BandWidget(bandIndex: index);
                      },
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  SidebarButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[600]),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

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
          decoration: BoxDecoration(
            border: Border.all(color: band.isSelected.value ? Colors.blue : Colors.transparent, width: 2),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    band.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: band.elements.map((e) => ResizableElementWidget(element: e)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_fields),
                        onPressed: () => band.addElement(ElementType.text),
                      ),
                      IconButton(
                        icon: const Icon(Icons.input),
                        onPressed: () => band.addElement(ElementType.field),
                      ),
                    ],
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

class ResizableElementWidget extends StatelessWidget {
  final ReportElement element;

  ResizableElementWidget({required this.element});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => element.startEditing(),
      onTap: () => element.toggleSelection(),
      child: Obx(() {
        return Container(
          width: element.width.value,
          height: element.height.value,
          decoration: BoxDecoration(
            border: Border.all(color: element.isSelected.value ? Colors.blue : Colors.grey),
          ),
          child: Stack(
            children: [
              if (element.isEditing.value)
                SizedBox(
                  width: element.width.value,
                  child: TextField(
                    controller: element.controller,
                    onSubmitted: (_) => element.stopEditing(),
                    autofocus: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                )
              else
                Positioned.fill(
                  child: Center(
                    child: Text(element.controller.text),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    element.width.value += details.delta.dx;
                    element.height.value += details.delta.dy;
                  },
                  child: const Icon(Icons.coronavirus_outlined, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Controller
class ReportController extends GetxController {
  var bands = <Band>[].obs;

  void addBand(BandType type) {
    bands.add(Band(type));
  }

  void deleteSelected() {
    bands.removeWhere((band) => band.isSelected.value);
    for (var band in bands) {
      band.elements.removeWhere((element) => element.isSelected.value);
    }
  }

  void toggleBandSelection(Band band) {
    bool newState = !band.isSelected.value;
    band.isSelected.value = newState;
    for (var element in band.elements) {
      element.isSelected.value = newState;
    }
  }
}

// Model
class Band {
  final BandType type;
  var elements = <ReportElement>[].obs;
  var isSelected = false.obs;

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
}

enum BandType { header, masterData, detailData, footer }
enum ElementType { text, field }

class ReportElement {
  final ElementType type;
  var isSelected = false.obs;
  var isEditing = false.obs;
  var width = 100.0.obs;
  var height = 40.0.obs;
  final TextEditingController controller = TextEditingController();

  ReportElement(this.type) {
    controller.text = type == ElementType.text ? "Texto" : "Campo";
  }

  void toggleSelection() {
    isSelected.value = !isSelected.value;
  }

  void startEditing() {
    isEditing.value = true;
  }

  void stopEditing() {
    isEditing.value = false;
  }
}
