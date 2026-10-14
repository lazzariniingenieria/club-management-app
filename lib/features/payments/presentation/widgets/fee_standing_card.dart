import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/member_ledger.dart';
import '../formatting/payment_formats.dart';

class FeeStandingCard extends StatelessWidget {
  final MemberLedger ledger;

  const FeeStandingCard({super.key, required this.ledger});

  @override
  Widget build(BuildContext context) {
    final standing = _Standing.of(ledger);

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: standing.background,
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(standing.icon, color: standing.accent, size: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _StandingText(standing: standing)),
          ],
        ),
      ),
    );
  }
}

class _StandingText extends StatelessWidget {
  final _Standing standing;

  const _StandingText({required this.standing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          standing.title,
          style: AppTextStyles.titleLarge.copyWith(
            color: standing.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(standing.lastPaid, style: AppTextStyles.labelLarge),
        if (standing.note != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            standing.note!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Standing {
  final String title;
  final String lastPaid;
  final String? note;
  final Color background;
  final Color accent;
  final IconData icon;

  const _Standing({
    required this.title,
    required this.lastPaid,
    required this.background,
    required this.accent,
    required this.icon,
    this.note,
  });

  factory _Standing.of(MemberLedger ledger) {
    final member = ledger.member;
    final lastPaid = _lastPaidOf(ledger);

    if (!member.isActive) {
      return _Standing(
        title: AppStrings.ledgerInactive,
        lastPaid: lastPaid,
        note: AppStrings.ledgerInactiveNote,
        background: AppColors.disabledSurface,
        accent: AppColors.textPrimary,
        icon: Icons.block_rounded,
      );
    }
    if (!member.isOverdue) {
      return _Standing(
        title: AppStrings.ledgerUpToDate,
        lastPaid: lastPaid,
        background: AppColors.successSurface,
        accent: AppColors.successText,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return _Standing(
      title: AppStrings.ledgerDaysOverdue(member.daysOverdue),
      lastPaid: lastPaid,
      note: _overdueNoteOf(ledger),
      background: AppColors.dangerSurface,
      accent: AppColors.dangerText,
      icon: Icons.error_outline_rounded,
    );
  }

  static String _lastPaidOf(MemberLedger ledger) {
    final month = ledger.lastPaidMonth;
    if (month == null) return AppStrings.ledgerNeverPaid;

    return AppStrings.ledgerLastPaid(PaymentFormats.monthWithYear(month));
  }

  static String? _overdueNoteOf(MemberLedger ledger) {
    final lastPaid = ledger.lastPaidMonth;
    if (lastPaid != null) {
      return AppStrings.ledgerOverdueSinceLastPaid(
        PaymentFormats.monthWithYear(lastPaid.next),
      );
    }

    final joinedAt = ledger.member.joinedAt;
    if (joinedAt == null) return null;

    return AppStrings.ledgerOverdueSinceJoining(
      PaymentFormats.monthWithYear(BillingMonth.of(joinedAt)),
    );
  }
}
