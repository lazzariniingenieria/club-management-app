import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../payments/domain/entities/billing_month.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../../domain/entities/club_metrics.dart';

class CollectionChart extends StatelessWidget {
  final List<MonthlyCollection> collections;
  final BillingMonth selected;
  final ValueChanged<BillingMonth> onSelect;

  const CollectionChart({
    super.key,
    required this.collections,
    required this.selected,
    required this.onSelect,
  });

  static const double _plotHeight = 140;

  int get _highest =>
      collections.map((collection) => collection.totalCents).fold(0, max);

  @override
  Widget build(BuildContext context) {
    final highest = _highest;

    return SizedBox(
      height: _plotHeight + 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final collection in collections)
            Expanded(
              child: _Bar(
                collection: collection,
                share: highest == 0 ? 0 : collection.totalCents / highest,
                isSelected: collection.month == selected,
                onTap: () => onSelect(collection.month),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final MonthlyCollection collection;
  final double share;
  final bool isSelected;
  final VoidCallback onTap;

  const _Bar({
    required this.collection,
    required this.share,
    required this.isSelected,
    required this.onTap,
  });

  static const double _minimumVisibleHeight = 4;

  String get _amount => DisplayFormats.pesos(collection.totalCents);

  @override
  Widget build(BuildContext context) {
    final month = PaymentFormats.monthAbbreviation(collection.month.month);

    return Semantics(
      button: true,
      selected: isSelected,
      label: AppStrings.metricsBarSemantics(
        PaymentFormats.monthWithYear(collection.month),
        _amount,
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isSelected) _BarValue(amount: _amount),
              _BarFill(height: _heightOf(share), isSelected: isSelected),
              const SizedBox(height: AppSpacing.xs),
              Text(month, style: _labelStyle),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => isSelected
      ? AppTextStyles.badgeLabel.copyWith(color: AppColors.textPrimary)
      : AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary);

  static double _heightOf(double share) => share == 0
      ? 0
      : max(_minimumVisibleHeight, share * CollectionChart._plotHeight);
}

class _BarValue extends StatelessWidget {
  final String amount;

  const _BarValue({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(amount, style: AppTextStyles.badgeLabel),
      ),
    );
  }
}

class _BarFill extends StatelessWidget {
  final double height;
  final bool isSelected;

  const _BarFill({required this.height, required this.isSelected});

  static const Radius _dataEnd = Radius.circular(4);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandNavy : AppColors.accentBlue,
        borderRadius: const BorderRadius.vertical(top: _dataEnd),
      ),
    );
  }
}
