import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/superellipse_clipper.dart';
import 'package:scopa/utils.dart';

class HandCard extends StatefulWidget {
  final String num;
  final void Function(String) playCard;
  final double cardSize;
  final bool canHover;
  const HandCard(this.num, this.playCard, this.cardSize, {super.key, this.canHover = true});

  @override
  State<HandCard> createState() => _HandCardState();
}

class _HandCardState extends State<HandCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    Color color = widget.num[0] == '1' || widget.num[0] == '2' ? Colors.red : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => hover = true && widget.canHover),
        onExit: (_) => setState(() => hover = false),
        child: GestureDetector(
          onTap: () => widget.playCard(widget.num),
          child: AnimatedContainer(
            duration: Durations.long1,
            curve: Curves.easeOutCirc,
            height: hover ? 125 : 100,
            width: hover ? 100 : 73,
            transform: Matrix4.identity()..translate(0, hover ? -widget.cardSize : 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.white, const Color.fromARGB(255, 231, 231, 231)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color.fromARGB(90, 0, 0, 0), blurRadius: hover ? 60 : 20)],
            ),
            child: ClipPath(
              clipper: SuperEllipseClipper(borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  Container(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(hover ? 40 : 30),
                          blurRadius: 30,
                        )
                      ]),
                      child:
                          Align(alignment: Alignment.center, child: Image.asset(getSuitImage(widget.num), height: 40))),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
                      child: Text(
                        getCardNum(widget.num[1]),
                        style: GoogleFonts.varelaRound(color: color, fontSize: 25, fontWeight: FontWeight.w900),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
