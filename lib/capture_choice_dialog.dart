import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/widgets/playing_card.dart';

/// Asks which cards [card] should capture when there is more than one legal
/// option. Returns null if the player cancels.
Future<List<String>?> showCaptureChoice(BuildContext context, String card, List<List<String>> options) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        spacing: 12,
        children: [
          PlayingCard(card, height: 56),
          const Expanded(child: Text('Choose what to capture')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            for (final option in options)
              Material(
                color: Colors.transparent,
                shape: roundedShape(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(option),
                  hoverColor: AppColors.feltLight.withAlpha(40),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [for (final c in option) PlayingCard(c, height: 84)],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    ),
  );
}
