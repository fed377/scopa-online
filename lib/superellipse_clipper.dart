import 'package:flutter/material.dart';

class SuperEllipseClipper extends CustomClipper<Path> {
  final BorderRadius borderRadius;
  const SuperEllipseClipper({this.borderRadius = BorderRadius.zero});

  @override
  Path getClip(Size size) {
    final shape = RoundedSuperellipseBorder(borderRadius: borderRadius);
    return shape.getOuterPath(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
