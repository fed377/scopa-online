import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scopa/opponent_card.dart';

class OpponentHand extends StatelessWidget {
  const OpponentHand(
    this.fullWidth,
    this.cardSize,
    this.turn,
    this.ali,
    this.name,
    this.url,
    this.length, {
    super.key,
  });

  final double fullWidth;
  final double cardSize;
  final int turn;
  final AlignmentGeometry ali;
  final String name;
  final String url;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: ali,
      child: RotatedBox(
        quarterTurns: turn,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flex(
              mainAxisSize: MainAxisSize.min,
              direction: turn % 2 == 0 ? Axis.horizontal : Axis.vertical,
              children: [
                RotatedBox(
                  quarterTurns: -turn,
                  child: Text(
                    name,
                    style: GoogleFonts.varelaRound(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                RotatedBox(
                  quarterTurns: -turn,
                  child: CircleAvatar(
                    radius: 30,
                    foregroundImage: url.trim() == '' ? null : CachedNetworkImageProvider(url),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
            Container(
              width: fullWidth,
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(8.0),
              child: Stack(
                children: List.generate(
                  length,
                  (x) => AnimatedPositioned(
                    duration: Durations.short4,
                    bottom: 10,
                    left: x * cardSize,
                    child: OpponentCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
