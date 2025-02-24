import 'package:app_flow/modules/plug_out/plug_out.dart';
import 'package:flutter/material.dart';

import '../plug_in/plug_in.dart';

class PointOfExecution extends StatefulWidget {
  const PointOfExecution({super.key});

  @override
  State<PointOfExecution> createState() => _PointOfExecutionState();
}

class _PointOfExecutionState extends State<PointOfExecution> {
  Offset container1Position = Offset(50, 300);
  Offset container2Position = Offset(250, 300);
  Offset? startDragPosition1;
  Offset? startDragPosition2;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: container2Position.dx - 15,
        top: container2Position.dy - 15,
        child: GestureDetector(
            onPanStart: (details) {
              startDragPosition2 = details.localPosition;
            },
            onPanUpdate: (details) {
              setState(() {
                container2Position += details.delta;
              });
            },
            onPanEnd: (details) {
              startDragPosition2 = null;
            },
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                  child: PlugIn(),
                ),
                Container(
                    child: Text('Exemplo'),
                    color: Colors.greenAccent,
                    height: 30,
                    width: 200),
                SizedBox(
                  width: 10,
                  child: Column(
                    children: [PlugOut()],
                  ),
                )
              ],
            )));
  }
}
