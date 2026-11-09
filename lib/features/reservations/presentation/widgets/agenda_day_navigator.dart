import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../courts/presentation/formatting/court_block_formats.dart';

class AgendaDayNavigator extends StatelessWidget {
  final DateTime day;
  final ValueChanged<DateTime> onDayChanged;

  const AgendaDayNavigator({
    super.key,
    required this.day,
    required this.onDayChanged,
  });

  static const int _selectableYears = 2;

  DateTime _plusDays(int days) => DateTime(day.year, day.month, day.day + days);

  Future<void> _pick(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(today.year - _selectableYears),
      lastDate: DateTime(today.year + _selectableYears, 12, 31),
      helpText: AppStrings.agendaPickDay,
    );
    if (picked != null) onDayChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onDayChanged(_plusDays(-1)),
            tooltip: AppStrings.agendaPreviousDay,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(child: _DayButton(day: day, onTap: () => _pick(context))),
          IconButton(
            onPressed: () => onDayChanged(_plusDays(1)),
            tooltip: AppStrings.agendaNextDay,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final DateTime day;
  final VoidCallback onTap;

  const _DayButton({required this.day, required this.onTap});

  bool get _isToday {
    final now = DateTime.now();

    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final formatted = CourtBlockFormats.day(day);

    return TextButton(
      onPressed: onTap,
      child: Text(
        _isToday ? '${AppStrings.agendaToday} · $formatted' : formatted,
        style: AppTextStyles.labelLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
