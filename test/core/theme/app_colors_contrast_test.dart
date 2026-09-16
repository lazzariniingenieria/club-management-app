import 'dart:math' as math;

import 'package:club_management_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _wcagAaNormalText = 4.5;

double _channelLuminance(double channel) {
  if (channel <= 0.03928) return channel / 12.92;
  return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  return 0.2126 * _channelLuminance(color.r) +
      0.7152 * _channelLuminance(color.g) +
      0.0722 * _channelLuminance(color.b);
}

double contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = _relativeLuminance(foreground);
  final backgroundLuminance = _relativeLuminance(background);
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('palette contrast', () {
    const pairs = <String, List<Color>>{
      'dangerText on dangerSurface': [
        AppColors.dangerText,
        AppColors.dangerSurface,
      ],
      'successText on successSurface': [
        AppColors.successText,
        AppColors.successSurface,
      ],
      'textSecondary on background': [
        AppColors.textSecondary,
        AppColors.background,
      ],
      'textSecondary on surface': [
        AppColors.textSecondary,
        AppColors.surface,
      ],
      'textPrimary on background': [
        AppColors.textPrimary,
        AppColors.background,
      ],
      'brandNavy on infoSurface': [
        AppColors.brandNavy,
        AppColors.infoSurface,
      ],
      'accentBlue on surface': [
        AppColors.accentBlue,
        AppColors.surface,
      ],
      'textOnDark on brandNavy': [
        AppColors.textOnDark,
        AppColors.brandNavy,
      ],
      'textOnDark on brandGreen': [
        AppColors.textOnDark,
        AppColors.brandGreen,
      ],
    };

    pairs.forEach((description, colors) {
      test('$description meets WCAG AA for normal text', () {
        final ratio = contrastRatio(colors.first, colors.last);

        expect(
          ratio,
          greaterThanOrEqualTo(_wcagAaNormalText),
          reason: '$description is ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });
  });
}
