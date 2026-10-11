import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = AppRadius.mdAll,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.disabledSurface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
