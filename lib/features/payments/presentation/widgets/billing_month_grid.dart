import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/billing_month.dart';
import '../cubit/payment_form.dart';
import '../formatting/payment_formats.dart';

class BillingMonthGrid extends StatelessWidget {
  final PaymentForm form;
  final ValueChanged<BillingMonth>? onToggle;
  final ValueChanged<int> onShowYear;

  const BillingMonthGrid({
    super.key,
    required this.form,
    required this.onToggle,
    required this.onShowYear,
  });

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final year = form.visibleYear;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _YearSwitcher(
          year: year,
          canGoBack: year > form.earliestYear,
          onShowYear: onShowYear,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var row = 0; row < DateTime.monthsPerYear ~/ _columns; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _monthRow(row, year),
          ),
      ],
    );
  }

  Widget _monthRow(int row, int year) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var column = 0; column < _columns; column++) ...[
            if (column > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MonthCell(
                month: BillingMonth(year, row * _columns + column + 1),
                form: form,
                onToggle: onToggle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  final int year;
  final bool canGoBack;
  final ValueChanged<int> onShowYear;

  const _YearSwitcher({
    required this.year,
    required this.canGoBack,
    required this.onShowYear,
  });

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
            onPressed: canGoBack ? () => onShowYear(year - 1) : null,
            tooltip: AppStrings.registerPaymentPreviousYear,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                '$year',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onShowYear(year + 1),
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
  final PaymentForm form;
  final ValueChanged<BillingMonth>? onToggle;

  const _MonthCell({
    required this.month,
    required this.form,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final look = _CellLook.of(form, month);
    final toggle = onToggle;
    final canToggle = toggle != null && !look.isPaid;

    return Semantics(
      button: !look.isPaid,
      enabled: canToggle,
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
          onTap: canToggle ? () => toggle(month) : null,
          borderRadius: AppRadius.mdAll,
          child: _CellContent(month: month, look: look),
        ),
      ),
    );
  }
}

class _CellContent extends StatelessWidget {
  final BillingMonth month;
  final _CellLook look;

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

class _CellLook {
  final bool isPaid;
  final bool isSelected;
  final Color background;
  final Color foreground;
  final Color border;
  final String? caption;

  const _CellLook({
    required this.isPaid,
    required this.isSelected,
    required this.background,
    required this.foreground,
    required this.border,
    this.caption,
  });

  factory _CellLook.of(PaymentForm form, BillingMonth month) {
    if (form.isPaid(month)) {
      return const _CellLook(
        isPaid: true,
        isSelected: false,
        background: AppColors.disabledSurface,
        foreground: AppColors.textSecondary,
        border: AppColors.disabledText,
        caption: AppStrings.registerPaymentMonthPaid,
      );
    }
    if (form.isSelected(month)) {
      return const _CellLook(
        isPaid: false,
        isSelected: true,
        background: AppColors.brandNavy,
        foreground: AppColors.textOnDark,
        border: AppColors.brandNavy,
        caption: AppStrings.registerPaymentMonthChosen,
      );
    }

    return const _CellLook(
      isPaid: false,
      isSelected: false,
      background: AppColors.surface,
      foreground: AppColors.textPrimary,
      border: AppColors.textSecondary,
    );
  }
}
