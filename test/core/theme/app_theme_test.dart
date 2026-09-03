import 'package:club_management_app/core/theme/app_colors.dart';
import 'package:club_management_app/core/theme/app_radius.dart';
import 'package:club_management_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.lightTheme', () {
    testWidgets('opts into Material 3', (tester) async {
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    testWidgets('maps the brand ramp onto the color scheme', (tester) async {
      final colorScheme = AppTheme.lightTheme.colorScheme;

      expect(colorScheme.primary, AppColors.brandNavy);
      expect(colorScheme.secondary, AppColors.accentBlue);
      expect(colorScheme.tertiary, AppColors.brandGreen);
      expect(colorScheme.surface, AppColors.surface);
    });

    testWidgets('maps the semantic ramp separately from the brand ramp',
        (tester) async {
      final colorScheme = AppTheme.lightTheme.colorScheme;

      expect(colorScheme.error, AppColors.dangerText);
      expect(colorScheme.errorContainer, AppColors.dangerSurface);
      expect(colorScheme.error, isNot(AppColors.brandNavy));
    });

    testWidgets('uses the background token for the scaffold', (tester) async {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppColors.background);
    });

    testWidgets('builds input borders from AppRadius', (tester) async {
      final border = AppTheme.lightTheme.inputDecorationTheme.enabledBorder;

      expect(border, isA<OutlineInputBorder>());
      expect((border! as OutlineInputBorder).borderRadius, AppRadius.mdAll);
    });

    testWidgets('ships no dark theme', (tester) async {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(
        AppTheme.lightTheme.textTheme.bodyLarge?.color,
        AppColors.textPrimary,
      );
    });
  });
}
