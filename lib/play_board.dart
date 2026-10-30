import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// The felt table in the middle of the screen.
class PlayBoard extends StatelessWidget {
  const PlayBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(56),
      side: const BorderSide(color: Color(0x2EFFFFFF), width: 1.5),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(size.width * 0.14, size.height * 0.17, size.width * 0.14, size.height * 0.25),
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.tableLight.withAlpha(128), AppColors.tableDark.withAlpha(128)],
            ),
            shadows: const [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))],
          ),
        ),
      ),
    );
  }
}
