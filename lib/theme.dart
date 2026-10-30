import 'package:flutter/material.dart';

/// Colors of the felt table look shared by every screen.
abstract final class AppColors {
  static const feltLight = Color(0xFF34C759);
  static const feltDark = Color(0xFF19612B);
  static const tableLight = Color(0xFF00A326);
  static const tableDark = Color(0xFF004F00);

  /// Dark green used for buttons and pills on the felt.
  static const glass = Color(0xFF004F00);

  static const cardLight = Colors.white;
  static const cardDark = Color(0xFFE7E7E7);
  static const suitRed = Color(0xFFE53935);
  static const suitBlack = Color(0xFF1B1B1B);

  /// Highlights whoever is to play and this player's scopa.
  static const accent = Color(0xFFFFD54F);
  static const shadow = Color(0x59000000);
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 600);

  static const enter = Curves.easeOutCubic;
  static const move = Curves.easeInOutCubic;
}

const fontFamily = 'Nunito';

/// Black-weight text for card indices, titles and scores.
TextStyle displayStyle(double size, {Color color = Colors.white}) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

ShapeBorder roundedShape(double radius) => RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.feltDark,
    primary: AppColors.glass,
    secondary: AppColors.accent,
  );
  final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
    RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
  );
  const buttonPadding = WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14));
  const buttonSize = WidgetStatePropertyAll(Size(64, 46));
  const buttonText =
      WidgetStatePropertyAll(TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w800));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: fontFamily,
    textTheme: Typography.whiteMountainView.apply(fontFamily: fontFamily),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: buttonShape,
        padding: buttonPadding,
        textStyle: buttonText,
        minimumSize: buttonSize,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? AppColors.glass.withAlpha(110) : AppColors.glass,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? Colors.white54 : Colors.white,
        ),
        overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
        elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? 4 : 0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: buttonShape,
        padding: buttonPadding,
        textStyle: buttonText,
        minimumSize: buttonSize,
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        side: const WidgetStatePropertyAll(BorderSide(color: Colors.white54)),
        overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(shape: buttonShape, textStyle: buttonText),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: buttonShape,
        backgroundColor: const WidgetStatePropertyAll(AppColors.glass),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: roundedShape(28),
      backgroundColor: const Color(0xFFF4F7F4),
      titleTextStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.suitBlack,
      ),
      contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, color: AppColors.suitBlack),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.suitBlack,
      iconColor: AppColors.suitBlack,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      width: 420,
      shape: roundedShape(16),
      backgroundColor: const Color(0xF0102A16),
      contentTextStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontWeight: FontWeight.w600),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(shape: roundedShape(10), color: const Color(0xF0102A16)),
      textStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontSize: 13),
      waitDuration: const Duration(milliseconds: 400),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Colors.white),
  );
}

/// The felt background: the original green gradient plus a soft vignette.
class FeltBackground extends StatelessWidget {
  const FeltBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.feltLight, AppColors.feltDark],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Color(0x00000000), Color(0x33000000)],
              stops: [0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// A translucent dark pill used for labels on the felt.
class GlassPill extends StatelessWidget {
  const GlassPill(
      {super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(side: BorderSide(color: Color(0x1FFFFFFF))),
        color: Colors.black.withAlpha(56),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
