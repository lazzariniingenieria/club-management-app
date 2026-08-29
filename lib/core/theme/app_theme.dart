import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTextStyles.textTheme,
        appBarTheme: _appBarTheme,
        inputDecorationTheme: _inputDecorationTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        textButtonTheme: _textButtonTheme,
        cardTheme: _cardTheme,
        chipTheme: _chipTheme,
        snackBarTheme: _snackBarTheme,
        dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      );

  static const ColorScheme _colorScheme = ColorScheme.light(
    primary: AppColors.brandNavy,
    onPrimary: AppColors.textOnDark,
    primaryContainer: AppColors.infoSurface,
    onPrimaryContainer: AppColors.brandNavy,
    secondary: AppColors.accentBlue,
    onSecondary: AppColors.textOnDark,
    tertiary: AppColors.brandGreen,
    onTertiary: AppColors.textOnDark,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.background,
    surfaceContainerHighest: AppColors.infoSurface,
    onSurfaceVariant: AppColors.textSecondary,
    error: AppColors.dangerText,
    onError: AppColors.textOnDark,
    errorContainer: AppColors.dangerSurface,
    onErrorContainer: AppColors.dangerText,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  static final AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTextStyles.titleLarge,
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    errorMaxLines: 3,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.lg,
    ),
    border: _fieldBorder(AppColors.border),
    enabledBorder: _fieldBorder(AppColors.border),
    focusedBorder: _fieldBorder(AppColors.accentBlue, width: 2),
    errorBorder: _fieldBorder(AppColors.dangerText),
    focusedErrorBorder: _fieldBorder(AppColors.dangerText, width: 2),
    disabledBorder: _fieldBorder(AppColors.disabledSurface),
  );

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandNavy,
      foregroundColor: AppColors.textOnDark,
      disabledBackgroundColor: AppColors.disabledSurface,
      disabledForegroundColor: AppColors.disabledText,
      elevation: 0,
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      textStyle: AppTextStyles.labelLarge,
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.accentBlue,
      textStyle: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static const CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
  );

  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.brandNavy,
    side: const BorderSide(color: AppColors.border),
    labelStyle: AppTextStyles.bodyMedium,
    secondaryLabelStyle: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textOnDark,
    ),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
  );

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.brandNavy,
    contentTextStyle: AppTextStyles.bodyLarge.copyWith(
      color: AppColors.textOnDark,
    ),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
  );
}
