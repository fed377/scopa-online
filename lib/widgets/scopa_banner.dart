import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// Pops a "Scopa!" banner over the table whenever [ourScope] or [theirScope]
/// goes up.
class ScopaBanner extends StatefulWidget {
  const ScopaBanner({super.key, required this.ourScope, required this.theirScope});

  final int ourScope;
  final int theirScope;

  @override
  State<ScopaBanner> createState() => _ScopaBannerState();
}

class _ScopaBannerState extends State<ScopaBanner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _ours = true;

  @override
  void didUpdateWidget(ScopaBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ours = widget.ourScope > oldWidget.ourScope;
    if (ours || widget.theirScope > oldWidget.theirScope) {
      setState(() => _ours = ours);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            if (t == 0 || t == 1) return const SizedBox.shrink();
            // Pop in with a little overshoot, hold, then fade out.
            final scale = Curves.elasticOut.transform((t / 0.35).clamp(0.0, 1.0)) * 0.6 + 0.4;
            final opacity = t < 0.75 ? (t / 0.1).clamp(0.0, 1.0) : (1 - (t - 0.75) / 0.25);
            return Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: child));
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scopa!',
                style: displayStyle(84, color: _ours ? AppColors.accent : Colors.white).copyWith(
                  shadows: const [Shadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 6))],
                ),
              ),
              const SizedBox(height: 6),
              GlassPill(
                child: Text(
                  _ours ? 'Your team swept the table' : 'Opponents swept the table',
                  style: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
