import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../domain/entities/recurring_slot_clash.dart';
import '../formatting/recurring_slot_formats.dart';

class ClashNotice extends StatelessWidget {
  final List<RecurringSlotClash> clashes;

  const ClashNotice({super.key, required this.clashes});

  @override
  Widget build(BuildContext context) {
    if (clashes.isEmpty) {
      return const AppNotice(
        tone: AppNoticeTone.danger,
        message: AppStrings.recurringSlotClashUnknownDates,
      );
    }

    final lines = [
      for (final clash in clashes) RecurringSlotFormats.clash(clash),
      AppStrings.recurringSlotClashHint,
    ];

    return AppNotice(
      tone: AppNoticeTone.danger,
      title: AppStrings.recurringSlotClashTitle,
      message: lines.join('\n'),
    );
  }
}
