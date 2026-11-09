import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../formatting/court_block_formats.dart';

class CourtDateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateTime firstDay;
  final DateTime lastDay;
  final ValueChanged<DateTime> onChanged;

  const CourtDateField({
    super.key,
    required this.label,
    required this.value,
    required this.firstDay,
    required this.lastDay,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDay,
      lastDate: lastDay,
      helpText: AppStrings.courtBlockDayPickerHelp,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final formatted = CourtBlockFormats.day(value);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$label: $formatted',
      onTap: () => _pick(context),
      child: InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(formatted),
        ),
      ),
    );
  }
}
