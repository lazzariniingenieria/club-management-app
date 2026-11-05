import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/billing_month.dart';
import '../formatting/payment_formats.dart';

class MonthGridYear {
  final int year;
  final bool canGoBack;
  final bool canGoForward;

  const MonthGridYear({
    required this.year,
    required this.canGoBack,
    this.canGoForward = true,
  });
}

class MonthCellLook {
  final bool isEnabled;
  final bool isSelected;
  final Color background;
  final Color foreground;
  final Color border;
  final String? caption;

  const MonthCellLook._({
    required this.isEnabled,
    required this.isSelected,
    required this.background,
    required this.foreground,
    required this.border,
    this.caption,
  });

  const MonthCellLook.available()
      : this._(
          isEnabled: true,
          isSelected: false,
          background: AppColors.surface,
          foreground: AppColors.textPrimary,
          border: AppColors.textSecondary,
        );

  const MonthCellLook.selected(String caption, {bool isEnabled = true})
      : this._(
          isEnabled: isEnabled,
          isSelected: true,
          background: AppColors.brandNavy,
          foreground: AppColors.textOnDark,
          border: AppColors.brandNavy,
          caption: caption,
        );

  const MonthCellLook.unavailable({String? caption})
      : this._(
          isEnabled: false,
          isSelected: false,
          background: AppColors.disabledSurface,
          foreground: AppColors.textSecondary,
          border: AppColors.disabledText,
          caption: caption,
        );
}

class MonthGrid extends StatelessWidget {
  final MonthGridYear view;
  final MonthCellLook Function(BillingMonth month) lookOf;
  final ValueChanged<BillingMonth>? onTap;
  final ValueChanged<int> onShowYear;

  const MonthGrid({
    super.key,
    required this.view,
    required this.lookOf,
    required this.onTap,
    required this.onShowYear,
  });

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _YearSwitcher(view: view, onShowYear: onShowYear),
        const SizedBox(height: AppSpacing.sm),
        for (var row = 0; row < DateTime.monthsPerYear ~/ _columns; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _monthRow(row),
          ),
      ],
    );
  }

  Widget _monthRow(int row) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var column = 0; column < _columns; column++) ...[
            if (column > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _cellFor(
                BillingMonth(view.year, row * _columns + column + 1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cellFor(BillingMonth month) {
    final look = lookOf(month);
    final tap = onTap;

    return _MonthCell(
      month: month,
      look: look,
      onTap: look.isEnabled && tap != null ? () => tap(month) : null,
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  final MonthGridYear view;
  final ValueChanged<int> onShowYear;

  const _YearSwitcher({required this.view, required this.onShowYear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed:
                view.canGoBack ? () => onShowYear(view.year - 1) : null,
            tooltip: AppStrings.registerPaymentPreviousYear,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                '${view.year}',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ),
          IconButton(
            onPressed:
                view.canGoForward ? () => onShowYear(view.year + 1) : null,
            tooltip: AppStrings.registerPaymentNextYear,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final BillingMonth month;
  final MonthCellLook look;
  final VoidCallback? onTap;

  const _MonthCell({
    required this.month,
    required this.look,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: look.isEnabled,
      enabled: look.isEnabled,
      selected: look.isSelected,
      label: PaymentFormats.monthWithYear(month),
      hint: look.caption,
      excludeSemantics: true,
      child: Material(
        color: look.background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: look.border, width: look.isSelected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: _CellContent(month: month, look: look),
        ),
      ),
    );
  }
}

class _CellContent extends StatelessWidget {
  final BillingMonth month;
  final MonthCellLook look;

  const _CellContent({required this.month, required this.look});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              PaymentFormats.monthAbbreviation(month.month),
              style: AppTextStyles.labelLarge.copyWith(color: look.foreground),
            ),
            if (look.caption != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: look.foreground),
                  const SizedBox(width: 2),
                  Text(
                    look.caption!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: look.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
