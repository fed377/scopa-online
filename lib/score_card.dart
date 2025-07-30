import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreCard extends StatefulWidget {
  const ScoreCard({super.key, required this.num, required this.icon, required this.color, required this.text});

  final String num;
  final Widget icon;
  final Color color;
  final String text;

  @override
  State<ScoreCard> createState() => _ScoreCardState();
}

class _ScoreCardState extends State<ScoreCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    Duration duration = Durations.short4;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => hovering = true),
        onExit: (_) => setState(() => hovering = false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedOpacity(opacity: hovering ? 1 : 0, duration: duration, child: Text(widget.text)),
            ),
            AnimatedContainer(
              duration: duration,
              transform: Matrix4.identity()..translate(0, hovering ? -20 : 0),
              height: hovering ? 150 : 100,
              width: hovering ? 110 : 73,
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
                          color: widget.color.withAlpha(20),
                          blurRadius: 30,
                          spreadRadius: -100,
                        )
                      ]),
                      child: Align(alignment: Alignment.center, child: SizedBox(height: 40, child: widget.icon))),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
                      child: Text(
                        widget.num,
                        style: GoogleFonts.varelaRound(color: widget.color, fontSize: 25, fontWeight: FontWeight.w900),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
