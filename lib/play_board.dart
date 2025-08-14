import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:scopa/superellipse_clipper.dart';

class PlayBoard extends StatefulWidget {
  const PlayBoard({
    super.key,
  });

  @override
  State<PlayBoard> createState() => _PlayBoardState();
}

class _PlayBoardState extends State<PlayBoard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(200),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
            ),
          ],
        ),
        child: Stack(
          children: [
            SizedBox.expand(
              child: AnimatedContainer(
                duration: Durations.long1,
                child: Opacity(
                  opacity: 0.5,
                  child: ClipPath(
                      clipper: SuperEllipseClipper(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: AnimatedContainer(
                        duration: Durations.long1,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color.fromARGB(255, 0, 163, 38), Color.fromARGB(255, 0, 79, 0)])),
                      )),
                ),
              ),
            ),
            SizedBox.expand(
              child: AnimatedContainer(
                duration: Durations.long1,
                child: Opacity(
                  opacity: 0.5,
                  child: ClipPath(
                      clipper: SuperEllipseClipper(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: AnimatedContainer(
                        duration: Durations.long1,
                        decoration: BoxDecoration(color: Color.fromARGB(89, 0, 0, 0)),
                      ).asGlass(frosted: false)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
