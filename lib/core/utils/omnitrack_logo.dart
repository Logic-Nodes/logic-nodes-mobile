import 'package:flutter/material.dart';

import 'design_tokens.dart';

class OmnitrackLogo extends StatelessWidget {
  const OmnitrackLogo({
    this.foregroundColor = Colors.white,
    this.iconSize = 22,
    this.textSize = 24,
    super.key,
  });

  final Color foregroundColor;
  final double iconSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: iconSize + 10,
          width: iconSize + 10,
          decoration: BoxDecoration(
            color: foregroundColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: foregroundColor.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.route_rounded,
            size: iconSize,
            color: foregroundColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'OmniTrack',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w700,
            color: foregroundColor,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
