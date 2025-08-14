import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/superellipse_clipper.dart';
import 'package:scopa/utils.dart';

class BoardCard extends StatelessWidget {
  const BoardCard({super.key, required this.num});

  final String num;

  @override
  Widget build(BuildContext context) {
    Color color = num[0] == '1' || num[0] == '2' ? Colors.red : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipPath(
        clipper: SuperEllipseClipper(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 100,
          width: 73,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight),
            boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: 20)],
          ),
          child: Stack(
            children: [
              Container(
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 30,
                      spreadRadius: -100,
                    )
                  ]),
                  child: Align(alignment: Alignment.center, child: Image.asset(getSuitImage(num), height: 40))),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
                  child: Text(
                    getCardNum(num[1]),
                    style: GoogleFonts.varelaRound(color: color, fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
