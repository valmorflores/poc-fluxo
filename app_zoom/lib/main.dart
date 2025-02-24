import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POC Zoom & Drag',
      home: const ZoomableCanvasPage(),
    );
  }
}

class ZoomableCanvasPage extends StatefulWidget {
  const ZoomableCanvasPage({super.key});
  
  @override
  State<ZoomableCanvasPage> createState() => _ZoomableCanvasPageState();
}

class _ZoomableCanvasPageState extends State<ZoomableCanvasPage> {
  final int containerCount = 20;
  late List<Offset> positions;
  
  @override
  void initState() {
    super.initState();
    // Inicializa as posições dos contêineres em uma grade simples
    positions = List.generate(containerCount, (i) {
      double x = 50.0 + (i % 5) * 100.0; // 5 colunas
      double y = 50.0 + (i ~/ 5) * 100.0;  // 4 linhas
      return Offset(x, y);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POC Zoom & Drag')),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 30.0,
          boundaryMargin: const EdgeInsets.all(80),
          child: Container(
            width: 600,
            height: 600,
            color: Colors.grey[300],
            child: Stack(
              children: List.generate(containerCount, (index) {
                return Positioned(
                  left: positions[index].dx,
                  top: positions[index].dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        positions[index] = positions[index] + details.delta;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.primaries[index % Colors.primaries.length],
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
