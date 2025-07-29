import 'package:flutter/material.dart';

class OpponentCard extends StatelessWidget {
  const OpponentCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      height: 100,
      width: 73,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          Container(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 30,
                  spreadRadius: -100,
                )
              ]),
              child: Align(
                  alignment: Alignment.center, child: Image(height: 100, image: AssetImage('assets/back_card.png')))),
        ],
      ),
    );
  }
}
