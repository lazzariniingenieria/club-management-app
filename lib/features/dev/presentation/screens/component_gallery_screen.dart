import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_form_field.dart';
import '../widgets/gallery_section.dart';

class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _ColorTokensSection(),
          _TypographySection(),
          _SpacingSection(),
          _RadiusSection(),
          _ButtonsSection(),
          _TextFieldsSection(),
        ],
      ),
    );
  }
}

class _ColorTokensSection extends StatelessWidget {
  const _ColorTokensSection();

  static const Map<String, Color> _tokens = {
    'brandNavy': AppColors.brandNavy,
    'brandGreen': AppColors.brandGreen,
    'accentBlue': AppColors.accentBlue,
    'infoSurface': AppColors.infoSurface,
    'successSurface': AppColors.successSurface,
    'successText': AppColors.successText,
    'dangerSurface': AppColors.dangerSurface,
    'dangerText': AppColors.dangerText,
    'background': AppColors.background,
    'surface': AppColors.surface,
    'textPrimary': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'border': AppColors.border,
    'disabledSurface': AppColors.disabledSurface,
    'disabledText': AppColors.disabledText,
  };

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Color tokens',
      children: [
        for (final token in _tokens.entries)
          ColorTokenTile(name: token.key, color: token.value),
      ],
    );
  }
}

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Typography',
      children: [
        Text('displayLarge · 32', style: AppTextStyles.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('titleLarge · 24', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('titleMedium · 18', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('bodyLarge · 16', style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('bodyLargeMuted · 16', style: AppTextStyles.bodyLargeMuted),
        const SizedBox(height: AppSpacing.sm),
        Text('bodyMedium · 14', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('bodySmall · 13', style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Text('labelLarge · 16', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('SECTIONLABEL · 13', style: AppTextStyles.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        Text('BADGELABEL · 12', style: AppTextStyles.badgeLabel),
      ],
    );
  }
}

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  static const Map<String, double> _steps = {
    'xs': AppSpacing.xs,
    'sm': AppSpacing.sm,
    'md': AppSpacing.md,
    'lg': AppSpacing.lg,
    'xl': AppSpacing.xl,
    'xxl': AppSpacing.xxl,
    'xxxl': AppSpacing.xxxl,
  };

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Spacing',
      children: [
        for (final step in _steps.entries)
          _SpacingRow(name: step.key, value: step.value),
      ],
    );
  }
}

class _SpacingRow extends StatelessWidget {
  final String name;
  final double value;

  const _SpacingRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(name, style: AppTextStyles.bodySmall),
          ),
          Container(height: 12, width: value, color: AppColors.accentBlue),
          const SizedBox(width: AppSpacing.sm),
          Text(value.toStringAsFixed(0), style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _RadiusSection extends StatelessWidget {
  const _RadiusSection();

  static const Map<String, BorderRadius> _steps = {
    'sm': AppRadius.smAll,
    'md': AppRadius.mdAll,
    'lg': AppRadius.lgAll,
    'pill': AppRadius.pillAll,
  };

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Radius',
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final step in _steps.entries)
              Container(
                height: 64,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: step.value,
                ),
                child: Text(step.key, style: AppTextStyles.bodySmall),
              ),
          ],
        ),
      ],
    );
  }
}

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'AppButton',
      children: [
        GalleryItem(
          label: 'Enabled',
          child:
              AppButton(text: AppStrings.loginSubmitButton, onPressed: () {}),
        ),
        const GalleryItem(
          label: 'Loading',
          child: AppButton(text: AppStrings.loginSubmitButton, isLoading: true),
        ),
        const GalleryItem(
          label: 'Disabled',
          child: AppButton(text: AppStrings.loginSubmitButton),
        ),
        GalleryItem(
          label: 'Link',
          child: TextButton(onPressed: () {}, child: const Text('Link')),
        ),
      ],
    );
  }
}

class _TextFieldsSection extends StatefulWidget {
  const _TextFieldsSection();

  @override
  State<_TextFieldsSection> createState() => _TextFieldsSectionState();
}

class _TextFieldsSectionState extends State<_TextFieldsSection> {
  final _emptyController = TextEditingController();
  final _filledController = TextEditingController(text: 'member@club.com');
  final _errorController = TextEditingController(text: 'not-an-email');
  final _passwordController = TextEditingController(text: 'super-secret');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emptyController.dispose();
    _filledController.dispose();
    _errorController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'AppTextFormField',
      children: [
        GalleryItem(
          label: 'Empty',
          child: AppTextFormField(
            controller: _emptyController,
            hintText: AppStrings.loginEmailHint,
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        GalleryItem(
          label: 'Filled',
          child: AppTextFormField(
            controller: _filledController,
            hintText: AppStrings.loginEmailHint,
            prefixIcon: Icons.mail_outline_rounded,
          ),
        ),
        GalleryItem(
          label: 'Invalid',
          child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: AppTextFormField(
              controller: _errorController,
              hintText: AppStrings.loginEmailHint,
              prefixIcon: Icons.mail_outline_rounded,
              validator: (_) => AppStrings.loginEmailInvalidFormat,
            ),
          ),
        ),
        GalleryItem(
          label: _obscurePassword ? 'Password obscured' : 'Password visible',
          child: AppTextFormField(
            controller: _passwordController,
            hintText: AppStrings.loginPasswordHint,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: _togglePasswordVisibility,
          ),
        ),
      ],
    );
  }
}
