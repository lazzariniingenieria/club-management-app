import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/member_collection_filter.dart';

class MemberFilterChips extends StatelessWidget {
  final MemberCollectionFilter selected;
  final Map<MemberCollectionFilter, int> counts;
  final ValueChanged<MemberCollectionFilter> onSelected;

  const MemberFilterChips({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final filter in MemberCollectionFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterChip(
                filter: filter,
                count: counts[filter] ?? 0,
                isSelected: filter == selected,
                onSelected: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final MemberCollectionFilter filter;
  final int count;
  final bool isSelected;
  final ValueChanged<MemberCollectionFilter> onSelected;

  const _FilterChip({
    required this.filter,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(AppStrings.withCount(_labelFor(filter), count)),
      selected: isSelected,
      showCheckmark: false,
      side: BorderSide(
        color: isSelected ? AppColors.brandNavy : AppColors.border,
      ),
      onSelected: (_) => onSelected(filter),
    );
  }
}

String _labelFor(MemberCollectionFilter filter) {
  return switch (filter) {
    MemberCollectionFilter.all => AppStrings.adminPaymentsFilterAll,
    MemberCollectionFilter.overdue => AppStrings.adminPaymentsFilterOverdue,
    MemberCollectionFilter.toCollect => AppStrings.adminPaymentsFilterToCollect,
  };
}
