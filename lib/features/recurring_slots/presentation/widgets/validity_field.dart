import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../courts/presentation/widgets/court_date_field.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../formatting/recurring_slot_formats.dart';

class ValidityField extends StatelessWidget {
  final RecurringSlotValidity value;
  final DateTime firstDay;
  final ValueChanged<RecurringSlotValidity> onChanged;

  const ValidityField({
    super.key,
    required this.value,
    required this.firstDay,
    required this.onChanged,
  });

  void _changeFrom(DateTime from) {
    final preset = value.preset ?? ValidityPreset.suggested;
    onChanged(RecurringSlotValidity.preset(from, preset));
  }

  Future<void> _pickUntil(BuildContext context) async {
    final firstUntil =
        DateTime(value.from.year, value.from.month, value.from.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: value.until,
      firstDate: firstUntil,
      lastDate: RecurringSlotValidity.latestUntil(value.from),
      helpText: AppStrings.courtBlockDayPickerHelp,
    );
    if (picked != null) {
      onChanged(RecurringSlotValidity(from: value.from, until: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourtDateField(
          label: AppStrings.recurringSlotFormFrom,
          value: value.from,
          firstDay: firstDay,
          lastDay: DateTime(firstDay.year + 1, firstDay.month, firstDay.day),
          onChanged: _changeFrom,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(AppStrings.recurringSlotFormUntil,
            style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        _UntilChoices(
          value: value,
          onPreset: (preset) =>
              onChanged(RecurringSlotValidity.preset(value.from, preset)),
          onOtherDate: () => _pickUntil(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          RecurringSlotFormats.range(value),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _UntilChoices extends StatelessWidget {
  final RecurringSlotValidity value;
  final ValueChanged<ValidityPreset> onPreset;
  final VoidCallback onOtherDate;

  const _UntilChoices({
    required this.value,
    required this.onPreset,
    required this.onOtherDate,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value.preset;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final preset in ValidityPreset.values)
          ChoiceChip(
            label: Text(AppStrings.validityPreset(preset.months)),
            selected: preset == selected,
            onSelected: (_) => onPreset(preset),
          ),
        ChoiceChip(
          label: const Text(AppStrings.recurringSlotFormOtherDate),
          selected: selected == null,
          onSelected: (_) => onOtherDate(),
        ),
      ],
    );
  }
}
