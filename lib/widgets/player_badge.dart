import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// Profile picture, falling back to the player's initial.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.name, required this.imageUrl, this.radius = 18});

  final String name;
  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cardDark,
      foregroundImage: imageUrl.trim().isEmpty
          ? null
          : CachedNetworkImageProvider(
              imageUrl,
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
              errorListener: (_) {},
            ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: displayStyle(radius * 0.9, color: AppColors.feltDark),
      ),
    );
  }
}

/// Avatar and name on a pill. While [active] a soft amber ring pulses around
/// the avatar to show whose turn it is.
class PlayerBadge extends StatefulWidget {
  const PlayerBadge({
    super.key,
    required this.name,
    required this.imageUrl,
    this.active = false,
    this.trailing,
  });

  final String name;
  final String imageUrl;
  final bool active;
  final Widget? trailing;

  @override
  State<PlayerBadge> createState() => _PlayerBadgeState();
}

class _PlayerBadgeState extends State<PlayerBadge> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PlayerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => AnimatedContainer(
              duration: Motion.medium,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.active ? AppColors.accent : Colors.transparent,
                boxShadow: [
                  if (widget.active)
                    BoxShadow(
                      color: AppColors.accent.withAlpha((90 + 110 * _pulse.value).round()),
                      blurRadius: 6 + 10 * _pulse.value,
                      spreadRadius: 1 + 2 * _pulse.value,
                    ),
                ],
              ),
              child: child,
            ),
            child: PlayerAvatar(name: widget.name, imageUrl: widget.imageUrl),
          ),
          const SizedBox(width: 10),
          AnimatedDefaultTextStyle(
            duration: Motion.medium,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: widget.active ? AppColors.accent : Colors.white,
            ),
            child: Text(widget.name),
          ),
          if (widget.trailing != null) ...[const SizedBox(width: 10), widget.trailing!],
        ],
      ),
    );
  }
}
