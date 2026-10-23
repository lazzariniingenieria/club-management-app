import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/summary_table.dart';
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
            Text(
              AppStrings.confirmPaymentTitle,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            SummaryTable(rows: _rows(), total: _totalRow()),
            const SizedBox(height: AppSpacing.lg),
            const AppNotice(
              title: AppStrings.confirmPaymentNoticeTitle,
              message: AppStrings.confirmPaymentNotice,
            ),
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

  List<SummaryRow> _rows() {
    final member = form.ledger.member;

    return [
      SummaryRow(
        AppStrings.confirmPaymentMember,
        '${member.fullName}\n'
        '${AppStrings.memberDni(DisplayFormats.dni(member.dni))}',
      ),
      SummaryRow(
        AppStrings.confirmPaymentMonths,
        PaymentFormats.monthsSummary(form.selectedMonths),
      ),
      SummaryRow(
        AppStrings.confirmPaymentAmount,
        DisplayFormats.pesos(form.amountCents ?? 0),
      ),
      SummaryRow(
        AppStrings.confirmPaymentMethod,
        PaymentFormats.method(form.method),
      ),
      SummaryRow(AppStrings.confirmPaymentPayer, _payerName()),
    ];
  }

  SummaryRow _totalRow() {
    return SummaryRow(
      AppStrings.confirmPaymentTotal(
        AppStrings.monthCount(form.selectedMonths.length),
      ),
      _total,
    );
  }

  String _payerName() {
    final payerId = form.payerId;
    final ledger = form.ledger;
    if (payerId == null) {
      return AppStrings.paymentPayerMember(ledger.member.fullName);
    }

    return AppStrings.paymentPayerRelative(
      ledger.nameOf(payerId) ?? AppStrings.paymentPaidByUnknownRelative,
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
