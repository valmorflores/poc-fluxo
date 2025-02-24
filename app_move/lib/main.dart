import 'package:app_move/anchor_on_off.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrupamento Relativo',
      home: const GroupedWidgetsPage(),
    );
  }
}

class GroupedWidgetsPage extends StatefulWidget {
  const GroupedWidgetsPage({super.key});

  @override
  State<GroupedWidgetsPage> createState() => _GroupedWidgetsPageState();
}

class _GroupedWidgetsPageState extends State<GroupedWidgetsPage> {
  // Posição do widget pai
  Offset parentPosition = const Offset(100, 100);
  // Offset relativo para o widget filho (fixo em relação ao pai)
  final Offset childRelativeOffset = const Offset(70, 70);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widgets Agrupados'), 
      actions: [InkWell(child:Icon(Icons.abc),onTap: (){
         Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AnchorOnOff()),
  );
      },)],),
      body: Stack(
        children: [
          // Widget pai (azul) que pode ser arrastado
          Positioned(
            left: parentPosition.dx,
            top: parentPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Atualiza a posição do pai conforme o gesto de arrastar
                  parentPosition += details.delta;
                });
              },
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: const Center(
                  child: Text(
                    'Pai',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          // Widget filho (vermelho) posicionado relativo ao pai
          Positioned(
            left: parentPosition.dx + childRelativeOffset.dx,
            top: parentPosition.dy + childRelativeOffset.dy,
            child: Container(
              width: 60,
              height: 60,
              color: Colors.red,
              child: const Center(
                child: Text(
                  'Filho',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
