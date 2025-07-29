import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreBoard extends StatefulWidget {
  final int cardsGained;
  final int scope;

  const ScoreBoard({super.key, required this.cardsGained, required this.scope});

  @override
  State<ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<ScoreBoard> {
  bool scoreHover = false;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = GoogleFonts.varelaRound(color: Colors.black, fontSize: 18);
    TextStyle numberStyle = GoogleFonts.varelaRound(color: Colors.black, fontSize: 40);
    
    return Padding(
      padding: const EdgeInsets.all(26.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => scoreHover = true),
        onExit: (_) => setState(() => scoreHover = false),
        child: AnimatedContainer(
          curve: Curves.easeOutQuad,
          height: scoreHover ? 120 : 100,
          width: scoreHover ? 240 : 200,
          duration: Durations.short4,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color.fromARGB(scoreHover ? 120 : 47, 255, 255, 255), blurRadius: scoreHover ? 20 : 10)
            ],
            borderRadius: BorderRadius.circular(scoreHover ? 30 : 20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Cards', style: textStyle), Text(widget.cardsGained.toString(), style: numberStyle)],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Scope', style: textStyle), Text(widget.scope.toString(), style: numberStyle)],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
