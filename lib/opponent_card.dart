import 'package:flutter/material.dart';
import 'package:scopa/superellipse_clipper.dart';

class OpponentCard extends StatelessWidget {
  const OpponentCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: 20, spreadRadius: 1)]),
      child: ClipPath(
        clipper: SuperEllipseClipper(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(3.0),
          height: 100,
          width: 73,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight),
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
                  child: Align(alignment: Alignment.center, child: Image.asset('assets/back_card.png', height: 100))),
            ],
          ),
        ),
      ),
    );
  }
}
