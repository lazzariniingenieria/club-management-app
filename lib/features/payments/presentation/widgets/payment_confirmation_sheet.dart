import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/billing_month.dart';
import '../cubit/payment_form.dart';
import '../formatting/payment_formats.dart';

class PaymentConfirmationSheet extends StatelessWidget {
  final PaymentForm form;

  const PaymentConfirmationSheet({super.key, required this.form});

  static Future<bool> show(BuildContext context, PaymentForm form) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaymentConfirmationSheet(form: form),
    );

    return confirmed ?? false;
  }

  String get _total => DisplayFormats.pesos(form.totalCents);

  List<Member> get _charged =>
      form.paysForFamily ? form.chargedMembers : [form.ledger.member];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _TotalHeader(form: form, total: _total),
            const SizedBox(height: AppSpacing.xl),
            _ChargeList(form: form, members: _charged),
            const SizedBox(height: AppSpacing.lg),
            _PaymentDetails(form: form),
            const SizedBox(height: AppSpacing.lg),
            const AppNotice(message: AppStrings.confirmPaymentNotice),
            const SizedBox(height: AppSpacing.lg),
            _ConfirmButton(
              label: AppStrings.confirmPaymentAction(_total),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: AppStrings.confirmPaymentBackAction,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalHeader extends StatelessWidget {
  final PaymentForm form;
  final String total;

  const _TotalHeader({required this.form, required this.total});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.confirmPaymentTitle,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            total,
            style: AppTextStyles.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.confirmPaymentSummary(
              AppStrings.feeCount(form.feeCount),
              PaymentFormats.method(form.method),
            ),
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChargeList extends StatelessWidget {
  final PaymentForm form;
  final List<Member> members;

  const _ChargeList({required this.form, required this.members});

  String? _amountOf(List<BillingMonth> months) {
    if (months.isEmpty) return AppStrings.confirmPaymentSkipped;
    if (members.length == 1) return null;

    return DisplayFormats.pesos((form.amountCents ?? 0) * months.length);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < members.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _chargeRowOf(members[index]),
          ],
        ],
      ),
    );
  }

  Widget _chargeRowOf(Member member) {
    final months = form.monthsFor(member);

    return _ChargeRow(member: member, months: months, amount: _amountOf(months));
  }
}

class _ChargeRow extends StatelessWidget {
  final Member member;
  final List<BillingMonth> months;
  final String? amount;

  const _ChargeRow({
    required this.member,
    required this.months,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChargeDescription(member: member, months: months),
            ),
            if (amount != null) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                amount!,
                style: months.isEmpty
                    ? AppTextStyles.bodyMedium
                    : AppTextStyles.labelLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChargeDescription extends StatelessWidget {
  final Member member;
  final List<BillingMonth> months;

  const _ChargeDescription({required this.member, required this.months});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(member.fullName, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          months.isEmpty
              ? AppStrings.confirmPaymentSkippedReason
              : PaymentFormats.monthsSummary(months),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final PaymentForm form;

  const _PaymentDetails({required this.form});

  String get _payerName {
    final payerId = form.payerId;
    final ledger = form.ledger;
    if (payerId == null) {
      return AppStrings.paymentPayerMember(ledger.member.fullName);
    }

    return AppStrings.paymentPayerRelative(
      ledger.nameOf(payerId) ?? AppStrings.paymentPaidByUnknownRelative,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _DetailLine(
            label: AppStrings.confirmPaymentAmount,
            value: DisplayFormats.pesos(form.amountCents ?? 0),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailLine(label: AppStrings.confirmPaymentPayer, value: _payerName),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ConfirmButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.check_rounded),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandGreen,
        foregroundColor: AppColors.textOnDark,
      ),
    );
  }
}
