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
            Padding(
              padding: EdgeInsets.all(turn % 2 == 0 ? 50 : 10),
              child: Flex(
                mainAxisSize: MainAxisSize.min,
                direction: turn % 2 == 0 ? Axis.horizontal : Axis.vertical,
                children: [
                  RotatedBox(
                    quarterTurns: turn % 2 == 0 ? 2 : 0,
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
                    quarterTurns: turn % 2 == 0 ? 2 : 0,
                    child: CircleAvatar(
                      radius: 30,
                      foregroundImage:
                          url.trim() == '' ? null : CachedNetworkImageProvider(url, errorListener: (error) {}),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: fullWidth,
              height: 120,
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
