import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'application_controller.dart';
import 'component_model.dart';
import 'modules/line_single/line_single.dart';
import 'modules/widgets/point_of_execution_default.dart';
import 'modules/widgets/point_of_execution_if.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  ApplicationController applicationController =
      Get.put(ApplicationController());

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = getList();
    return Scaffold(
        appBar: AppBar(
          actions: [
            InkWell(
              child: Icon(Icons.add_box),
              onTap: () {
                applicationController.add(
                      ComponentModel(left: 130, top: 230, type: ShapeType.box));
                
                setState(() {});
              },
            ),
            InkWell(
              child: Icon(Icons.plus_one),
              onTap: () {
                applicationController.add(
                      ComponentModel(left: 30, top: 30, type: ShapeType.decisionIf));
                 setState(() {});
              },
            ),
            InkWell(
              child: Icon(Icons.line_axis),
              onTap: () {
                setState(() {
                  applicationController.add(
                      ComponentModel(left: 30, top: 30, type: ShapeType.link));
                });
              },
            )
          ],
        ),
        body: Container(
            color: Colors.black87, child: Stack(children: widgetList)));
  }

  getList() {
    List<Widget> itens = [
      Positioned(
        child: PointOfExecution(),
        top: 100,
        left: 20,
      ),
      Positioned(
        child: PointOfExecution(),
        top: 300,
        left: 500,
      ),
      Positioned(
        child: PointOfExecutionIf(),
        top: 340,
        left: 400,
      ),
      BezierLineExample(),
    ];

    applicationController.componentsList.forEach((e) {
      if (e.type == ShapeType.box) {
        itens.add(
          Positioned(
            child: PointOfExecution(),
            top: (e.top ?? 0),
            left: e.left ?? 0,
          ),
        );
      }
      if (e.type == ShapeType.decisionIf) {
        itens.add(
          Positioned(
            child: PointOfExecutionIf(),
            top: (e.top ?? 0),
            left: e.left ?? 0,
          ),
        );
      }
      if (e.type == ShapeType.link) {
        itens.add(BezierLineExample());
      }
    });

    return itens;
  }
}

