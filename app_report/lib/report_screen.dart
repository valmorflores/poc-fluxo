import 'package:app_report/controller/report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'controller/report_print_controller.dart';

class ReportScreen extends StatelessWidget {
  final String jsonString;
  ReportScreen({required this.jsonString});
  final ReportPrintController reportPrintController =
      Get.put(ReportPrintController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relatório em PDF')),
      body: Obx(() {
        if (reportPrintController.pdfPath.value.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        return PdfPreview(
          build: (format) async {
            final pdfBytes =
                await reportPrintController.generateReport(jsonString);
            return pdfBytes;
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await reportPrintController.printReport(jsonString);
        },
        child: Icon(Icons.print),
      ),
    );
  }
}
