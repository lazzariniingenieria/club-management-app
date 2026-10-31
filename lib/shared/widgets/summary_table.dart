import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class SummaryRow {
  final String label;
  final String value;

  const SummaryRow(this.label, this.value);
}

class SummaryTable extends StatelessWidget {
  final List<SummaryRow> rows;
  final SummaryRow? total;

  const SummaryTable({super.key, required this.rows, this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rows.length; index++)
            _SummaryLine(
              row: rows[index],
              showsDivider: index < rows.length - 1 || total != null,
            ),
          if (total != null) _TotalLine(row: total!),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final SummaryRow row;
  final bool showsDivider;

  const _SummaryLine({required this.row, required this.showsDivider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: showsDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(row.label, style: AppTextStyles.bodyMedium)),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              flex: 2,
              child: Text(
                row.value,
                textAlign: TextAlign.end,
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final SummaryRow row;

  const _TotalLine({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.md - 1),
        ),
      ),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              row.value,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
