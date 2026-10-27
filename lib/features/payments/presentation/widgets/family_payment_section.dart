import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../members/domain/entities/member.dart';
import '../cubit/family_payment.dart';
import '../cubit/payment_form.dart';
import '../formatting/payment_formats.dart';

class FamilyPaymentSection extends StatelessWidget {
  final PaymentForm form;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<int> onToggleRelative;
  final VoidCallback onRetry;

  const FamilyPaymentSection({
    super.key,
    required this.form,
    required this.onToggle,
    required this.onToggleRelative,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final family = form.family;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: family != null,
            onChanged: onToggle,
            title: Text(
              AppStrings.registerPaymentFamilyToggle,
              style: AppTextStyles.bodyLarge,
            ),
            subtitle: Text(
              AppStrings.registerPaymentFamilyToggleHelp,
              style: AppTextStyles.bodySmall,
            ),
          ),
          if (family != null) ...[
            const Divider(height: 1, color: AppColors.border),
            _FamilyBody(
              form: form,
              onToggleRelative: onToggleRelative,
              onRetry: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _FamilyBody extends StatelessWidget {
  final PaymentForm form;
  final ValueChanged<int> onToggleRelative;
  final VoidCallback onRetry;

  const _FamilyBody({
    required this.form,
    required this.onToggleRelative,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final family = form.family ?? const FamilyPayment();
    if (family.isLoading) return const _FamilySkeleton();
    if (family.failedToLoad) return _FamilyLoadFailed(onRetry: onRetry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FamilyMemberTile(form: form, member: form.ledger.member),
        for (final relative in form.activeRelatives)
          _FamilyMemberTile(
            form: form,
            member: relative,
            onToggle: form.family?.hasSettled(relative.id) ?? false
                ? null
                : () => onToggleRelative(relative.id),
          ),
        if (form.inactiveRelatives.isNotEmpty)
          _InactiveRelativesNote(relatives: form.inactiveRelatives),
      ],
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  final PaymentForm form;
  final Member member;
  final VoidCallback? onToggle;

  const _FamilyMemberTile({
    required this.form,
    required this.member,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isIncluded = form.family?.includes(member.id) ?? false;

    return CheckboxListTile(
      value: onToggle == null || isIncluded,
      onChanged: onToggle == null ? null : (_) => onToggle!(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(member.fullName, style: AppTextStyles.bodyLarge),
      subtitle: isIncluded || onToggle == null
          ? Text(_chargeNote(), style: AppTextStyles.bodySmall)
          : null,
    );
  }

  String _chargeNote() {
    final months = form.monthsFor(member);
    if (months.isEmpty) return AppStrings.registerPaymentFamilyNothingToCharge;

    return AppStrings.registerPaymentFamilyCharges(
      PaymentFormats.monthsSummary(months).toLowerCase(),
    );
  }
}

class _InactiveRelativesNote extends StatelessWidget {
  final List<Member> relatives;

  const _InactiveRelativesNote({required this.relatives});

  @override
  Widget build(BuildContext context) {
    final names = [for (final relative in relatives) relative.fullName];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        AppStrings.registerPaymentFamilyInactiveLeftOut(
          DisplayFormats.listed(names),
        ),
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _FamilyLoadFailed extends StatelessWidget {
  final VoidCallback onRetry;

  const _FamilyLoadFailed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppNotice(
        message: AppStrings.registerPaymentFamilyLoadFailed,
        tone: AppNoticeTone.danger,
        action: OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.dangerText,
            side: const BorderSide(color: AppColors.dangerText),
            minimumSize: const Size(0, 48),
          ),
          child: const Text(AppStrings.retryAction),
        ),
      ),
    );
  }
}

class _FamilySkeleton extends StatelessWidget {
  const _FamilySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          SkeletonBox(height: 48),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 48),
        ],
      ),
    );
  }
}
