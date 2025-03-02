import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'controller/report_data_controller.dart';
import 'controller/report_print_controller.dart';
import 'models/band_model.dart';
import 'models/report_element.dart';
import 'report_screen.dart';
import 'widgets/band_widget.dart';
import 'controller/report_controller.dart'; // Para carregar arquivos externos

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
  final TextEditingController urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    urlController.text =
        'http://localhost/dev/reportclipper/v1/public/report_exemplo4.json';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: "Digite a URL/caminho do JSON",
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.black),
            onPressed: () => controller.loadJSON(urlController.text),
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.black),
            onPressed: () {
              final reportPrintController = Get.put(ReportPrintController());
              ReportController reportController = Get.put(ReportController());
              String jsonString = reportController.getJsonReport();
              reportPrintController.printReport(jsonString);
              Get.to(() => ReportScreen(jsonString: jsonString));
            }, //controller.printPDF(),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: controller.saveReport,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: controller.deleteSelected,
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[800],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opções',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SidebarButton(
                    label: "Header",
                    onPressed: () => controller.addBand(BandType.header)),
                SidebarButton(
                    label: "MasterData",
                    onPressed: () => controller.addBand(BandType.masterData)),
                SidebarButton(
                    label: "DetailData",
                    onPressed: () => controller.addBand(BandType.detailData)),
                SidebarButton(
                    label: "Footer",
                    onPressed: () => controller.addBand(BandType.footer)),
                IconButton(
                    icon: const Icon(
                      Icons.text_fields,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      controller.bands.forEach((e) {
                        if (e.isSelected.value) {
                          e.addElement(ElementType.text);
                        }
                      });
                    }),
                IconButton(
                  icon: const Icon(
                    Icons.input,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      controller.bands[0].addElement(ElementType.field),
                ),
              ],
            ),
          ),
          Expanded(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 1024, // Área de desenho fixa em 1024 pixels
                child: Obx(
                  () => ListView.builder(
                    itemCount: controller.bands.length,
                    itemBuilder: (context, index) {
                      return BandWidget(bandIndex: index);
                    },
                  ),
                ),
              ),
            ),
          ),
          // Rodapé com Ícones dos Datasets
          Obx(
            () => controller.datasets.isNotEmpty
                ? Container(
                    color: Colors.blueGrey[800],
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: controller.datasets.map((dataset) {
                        return GestureDetector(
                          onTap: () {
                            Get.to(() => DatasetDetailsPage(dataset: dataset));
                          },
                          child: Column(
                            children: [
                              Icon(Icons.dataset, color: Colors.white, size: 40),
                              Text(
                                dataset.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox(),
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

// 🔹 Página de Detalhes do Dataset
class DatasetDetailsPage extends StatelessWidget {
  final ReportDataset dataset;
  final ReportController controller = Get.find();
  final RxString selectedField = "".obs;

  DatasetDetailsPage({required this.dataset});

  @override
  Widget build(BuildContext context) {
    List<String> fields =
        dataset.data.isNotEmpty ? dataset.data.first.keys.toList() : [];

    return Scaffold(
      appBar: AppBar(title: Text("Campos - ${dataset.name}")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: fields.length,
              itemBuilder: (context, index) {
                return Obx(() => ListTile(
                      title: Text(fields[index]),
                      trailing: selectedField.value == fields[index]
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        selectedField.value = fields[index];
                      },
                    ));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                /*if (selectedField.value.isNotEmpty && controller.selectedBand != null) {
                  controller.addElementToBand("[${dataset.name}.${selectedField.value}]");                 
                }*/
                Get.back();
              },
              child: const Text("OK"),
            ),
          )
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


