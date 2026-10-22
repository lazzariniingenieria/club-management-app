import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/payment.dart';
import '../formatting/payment_formats.dart';
import 'payment_notice.dart';
import 'payment_secondary_button.dart';

class VoidPaymentSheet extends StatefulWidget {
  final Payment payment;
  final String memberName;

  const VoidPaymentSheet({
    super.key,
    required this.payment,
    required this.memberName,
  });

  static Future<String?> show(
    BuildContext context, {
    required Payment payment,
    required String memberName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => VoidPaymentSheet(
        payment: payment,
        memberName: memberName,
      ),
    );
  }

  @override
  State<VoidPaymentSheet> createState() => _VoidPaymentSheetState();
}

class _VoidPaymentSheetState extends State<VoidPaymentSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String get _summary => [
        widget.memberName,
        PaymentFormats.pesos(widget.payment.amountCents),
        PaymentFormats.method(widget.payment.method),
        PaymentFormats.day(widget.payment.paidAt),
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
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
                AppStrings.voidPaymentTitle(
                  PaymentFormats.monthWithYear(widget.payment.month),
                ),
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_summary, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              const PaymentNotice(
                message: AppStrings.voidPaymentEffect,
                tone: PaymentNoticeTone.danger,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReasonField(controller: _reason),
              const SizedBox(height: AppSpacing.lg),
              _ConfirmVoidButton(
                onPressed: () => Navigator.of(context).pop(_reason.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              PaymentSecondaryButton(
                label: AppStrings.cancelAction,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;

  const _ReasonField({required this.controller});

  static const int _maxReasonLength = 150;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: _maxReasonLength,
      minLines: 2,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: AppStrings.voidPaymentReasonLabel,
        hintText: AppStrings.voidPaymentReasonHint,
      ),
    );
  }
}

class _ConfirmVoidButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ConfirmVoidButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dangerText,
        foregroundColor: AppColors.textOnDark,
      ),
      child: const Text(AppStrings.voidPaymentConfirmAction),
    );
  }
}
