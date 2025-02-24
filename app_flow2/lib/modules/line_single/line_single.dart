import 'package:flutter/material.dart';

class BezierLineExample extends StatefulWidget {
  @override
  _BezierLineExampleState createState() => _BezierLineExampleState();
}

class _BezierLineExampleState extends State<BezierLineExample> {
  Offset container1Position = Offset(50, 300);
  Offset container2Position = Offset(250, 300);
  Offset? startDragPosition1;
  Offset? startDragPosition2;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BezierLinePainter(
              container1Position,
              container2Position,
            ),
          ),
        ),
        Positioned(
          left: container1Position.dx - 15,
          top: container1Position.dy - 15,
          child: GestureDetector(
            onPanStart: (details) {
              startDragPosition1 = details.localPosition;
            },
            onPanUpdate: (details) {
              setState(() {
              container1Position += details.delta;  
              });
              
            },
            onPanEnd: (details) {
              startDragPosition1 = null;
              setState(() {});
            },
            child: Container(
              width: 30,
              height: 30,
              color: Colors.blue,
            ),
          ),
        ),
        Positioned(
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
            child: Container(
              width: 30,
              height: 30,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

class BezierLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  BezierLinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      start.dx + 100,
      start.dy,
      end.dx - 100,
      end.dy,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
