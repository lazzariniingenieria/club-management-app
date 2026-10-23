import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/peso_amount.dart';
import '../../../../shared/widgets/amount_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';

typedef MonthlyFeeSave = Future<Failure?> Function(int? monthlyFeeCents);

class MonthlyFeeSheet extends StatefulWidget {
  final int? initialCents;
  final MonthlyFeeSave onSave;

  const MonthlyFeeSheet({
    super.key,
    required this.initialCents,
    required this.onSave,
  });

  static Future<bool> show(BuildContext context, MonthlyFeeSheet sheet) {
    return showAppSheet<bool>(context, (_) => sheet)
        .then((saved) => saved ?? false);
  }

  @override
  State<MonthlyFeeSheet> createState() => _MonthlyFeeSheetState();
}

class _MonthlyFeeSheetState extends State<MonthlyFeeSheet> {
  late String _text = PesoAmount.textFor(widget.initialCents);
  bool _isSaving = false;
  Failure? _failure;

  int? get _cents => PesoAmount.centsFrom(_text);

  bool get _canSave => _text.trim().isEmpty || (_cents ?? 0) > 0;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final failure = await widget.onSave(_text.trim().isEmpty ? null : _cents);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: AppStrings.feeSheetTitle,
      children: [
        if (_failure != null) ...[
          AppNotice(
            tone: AppNoticeTone.danger,
            message: _failure is NetworkFailure
                ? AppStrings.saveFailedOffline
                : AppStrings.saveFailedServer,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AmountField(
          initialCents: widget.initialCents,
          label: AppStrings.feeSheetLabel,
          onChanged: (text) => setState(() => _text = text),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(AppStrings.feeSheetHelp, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          text: _failure == null ? AppStrings.saveAction : AppStrings.retryAction,
          isLoading: _isSaving,
          onPressed: _canSave ? _save : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: AppStrings.cancelAction,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
