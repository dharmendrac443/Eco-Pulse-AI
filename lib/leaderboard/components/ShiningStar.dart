// ignore: file_names
import 'package:flutter/material.dart';

class ShiningStar extends StatelessWidget {
  final List<Color> gradientColors;

  // ignore: use_key_in_widget_constructors
  const ShiningStar({required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Icon(
        Icons.star,
        size: 30,
        color: Colors.white, // This is masked by the gradient
      ),
    );
  }
}
