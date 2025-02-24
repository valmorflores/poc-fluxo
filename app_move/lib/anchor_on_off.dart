import 'package:flutter/material.dart';

class AnchorOnOff extends StatefulWidget {
  const AnchorOnOff({super.key});

  @override
  State<AnchorOnOff> createState() => _AnchorOnOffState();
}

class _AnchorOnOffState extends State<AnchorOnOff> {
 
  // Posição absoluta do widget pai.
  Offset parentPosition = const Offset(100, 100);
  // Posição absoluta do widget filho.
  Offset childPosition = const Offset(180, 180);
  // Flag que indica se o filho está ancorado ao pai.
  bool isAnchored = true;
  // Offset relativo do filho em relação ao pai quando ancorado.
  Offset relativeOffset = const Offset(80, 80);

  @override
  Widget build(BuildContext context) {
    // Se estiver ancorado, atualiza a posição do filho com base na posição do pai.
    if (isAnchored) {
      childPosition = parentPosition + relativeOffset;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vínculo Dinâmico'),
        actions: [
          IconButton(
            icon: Icon(isAnchored ? Icons.link : Icons.link_off),
            tooltip: isAnchored ? 'Desancorar' : 'Ancorar',
            onPressed: () {
              setState(() {
                if (isAnchored) {
                  // Ao desancorar, mantemos a posição atual do filho.
                  isAnchored = false;
                } else {
                  // Ao ancorar, recalculamos o offset relativo
                  relativeOffset = childPosition - parentPosition;
                  isAnchored = true;
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Widget Pai (azul) - pode ser movido com o gesto de arrastar.
          Positioned(
            left: parentPosition.dx,
            top: parentPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  parentPosition += details.delta;
                  if (isAnchored) {
                    // Quando ancorado, o filho é reposicionado automaticamente.
                    childPosition = parentPosition + relativeOffset;
                  }
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
          // Widget Filho (vermelho) - pode ser movido independentemente se desvinculado.
          Positioned(
            left: childPosition.dx,
            top: childPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Se estiver desvinculado, movimenta o filho diretamente.
                  if (!isAnchored) {
                    childPosition += details.delta;
                  } else {
                    // Se estiver ancorado, atualiza o offset relativo.
                    relativeOffset += details.delta;
                    childPosition = parentPosition + relativeOffset;
                  }
                });
              },
              child: Container(
                width: 80,
                height: 80,
                color: Colors.red,
                child: const Center(
                  child: Text(
                    'Filho',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

