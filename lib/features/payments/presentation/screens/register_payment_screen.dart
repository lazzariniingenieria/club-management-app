import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../cubit/payment_form.dart';
import '../cubit/register_payment_cubit.dart';
import '../cubit/register_payment_state.dart';
import '../formatting/payment_formats.dart';
import '../widgets/billing_month_grid.dart';
import '../widgets/member_header_card.dart';
import '../widgets/payer_selector.dart';
import '../widgets/payment_amount_field.dart';
import '../widgets/payment_confirmation_sheet.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/payment_notice.dart';
import '../widgets/payment_pill.dart';
import '../widgets/payment_total_summary.dart';
import '../widgets/payment_unavailable_view.dart';

class RegisterPaymentScreen extends StatelessWidget {
  final int memberId;

  const RegisterPaymentScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterPaymentCubit>(
      create: (_) => sl<RegisterPaymentCubit>()..open(memberId),
      child: AdminScaffold(
        title: AppStrings.registerPaymentTitle,
        body: _RegisterPaymentBody(memberId: memberId),
      ),
    );
  }
}

class _RegisterPaymentBody extends StatelessWidget {
  final int memberId;

  const _RegisterPaymentBody({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterPaymentCubit, RegisterPaymentState>(
      listenWhen: (_, current) => current is RegisterPaymentRegistered,
      listener: (context, state) {
        if (state is RegisterPaymentRegistered) context.pop(state.receipt);
      },
      builder: (context, state) => switch (state) {
        RegisterPaymentEditing() => _RegisterPaymentForm(state: state),
        RegisterPaymentUnavailable() => PaymentUnavailableView(
            kind: _unavailableKindOf(state),
            onRetry: () => context.read<RegisterPaymentCubit>().open(memberId),
          ),
        RegisterPaymentLoading() ||
        RegisterPaymentRegistered() =>
          const _RegisterPaymentSkeleton(),
      },
    );
  }

  static PaymentUnavailableKind _unavailableKindOf(
    RegisterPaymentUnavailable state,
  ) {
    if (state.isMissing) return PaymentUnavailableKind.missing;

    return state.isOffline
        ? PaymentUnavailableKind.offline
        : PaymentUnavailableKind.server;
  }
}

class _RegisterPaymentForm extends StatelessWidget {
  final RegisterPaymentEditing state;

  const _RegisterPaymentForm({required this.state});

  @override
  Widget build(BuildContext context) {
    final form = state.form;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (state.notice != null) ...[
                _TopNotice(notice: state.notice!),
                const SizedBox(height: AppSpacing.lg),
              ],
              MemberHeaderCard(
                member: form.ledger.member,
                details: _StandingLine(form: form),
              ),
              const SizedBox(height: AppSpacing.xl),
              _MonthsSection(form: form, notice: state.notice),
              const SizedBox(height: AppSpacing.xl),
              _AmountSection(form: form),
              const SizedBox(height: AppSpacing.xl),
              _MethodSection(form: form),
              if (form.ledger.familyMembers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                _PayerSection(form: form, notice: state.notice),
              ],
            ],
          ),
        ),
        _ReviewBar(form: form, isSubmitting: state.isSubmitting),
      ],
    );
  }
}

class _StandingLine extends StatelessWidget {
  final PaymentForm form;

  const _StandingLine({required this.form});

  @override
  Widget build(BuildContext context) {
    final member = form.ledger.member;
    final lastPaid = form.ledger.lastPaidMonth;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PaymentPill(
          label: member.isOverdue
              ? AppStrings.daysOverdueBadge(member.daysOverdue)
              : AppStrings.memberUpToDateBadge,
          tone: member.isOverdue
              ? PaymentPillTone.danger
              : PaymentPillTone.success,
        ),
        Text(
          lastPaid == null
              ? AppStrings.ledgerNeverPaid
              : AppStrings.ledgerLastPaid(
                  PaymentFormats.monthWithYear(lastPaid),
                ),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _TopNotice extends StatelessWidget {
  final RegisterPaymentNotice notice;

  const _TopNotice({required this.notice});

  @override
  Widget build(BuildContext context) {
    return switch (notice) {
      OfflineNotice() => PaymentNotice(
          title: AppStrings.registerPaymentOfflineTitle,
          message: AppStrings.registerPaymentOfflineMessage,
          tone: PaymentNoticeTone.danger,
          action: OutlinedButton(
            onPressed: context.read<RegisterPaymentCubit>().submit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dangerText,
              side: const BorderSide(color: AppColors.dangerText),
              minimumSize: const Size(0, 48),
            ),
            child: const Text(AppStrings.retryAction),
          ),
        ),
      SubmitFailedNotice(:final message) => PaymentNotice(
          message: message,
          tone: PaymentNoticeTone.danger,
        ),
      MonthsAlreadyPaidNotice() ||
      PayerLeftGroupNotice() =>
        const SizedBox.shrink(),
    };
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTextStyles.labelLarge),
      ),
    );
  }
}

class _MonthsSection extends StatelessWidget {
  final PaymentForm form;
  final RegisterPaymentNotice? notice;

  const _MonthsSection({required this.form, required this.notice});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterPaymentCubit>();
    final repeated = notice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(AppStrings.registerPaymentMonthsTitle),
        BillingMonthGrid(
          form: form,
          onToggle: cubit.toggleMonth,
          onShowYear: cubit.showYear,
        ),
        if (repeated is MonthsAlreadyPaidNotice)
          PaymentNotice(
            message: AppStrings.registerPaymentMonthsAlreadyPaid(
              PaymentFormats.monthsSummary(repeated.months),
            ),
            tone: PaymentNoticeTone.danger,
          )
        else
          Text(_suggestionOf(form), style: AppTextStyles.bodyMedium),
      ],
    );
  }

  static String _suggestionOf(PaymentForm form) {
    final month = PaymentFormats.monthName(form.suggestedMonth);

    return form.startsFromLastPaid
        ? AppStrings.registerPaymentSuggestionAfterLastPaid(month)
        : AppStrings.registerPaymentSuggestionFromJoining(month);
  }
}

class _AmountSection extends StatelessWidget {
  final PaymentForm form;

  const _AmountSection({required this.form});

  @override
  Widget build(BuildContext context) {
    final fee = form.ledger.monthlyFeeCents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentAmountField(
          initialCents: form.amountCents,
          maxDigits: RegisterPaymentCubit.maxAmountDigits,
          onChanged: context.read<RegisterPaymentCubit>().changeAmount,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          fee == null
              ? AppStrings.registerPaymentAmountWithoutFee
              : AppStrings.registerPaymentAmountWithFee(
                  PaymentFormats.pesos(fee),
                ),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        PaymentTotalSummary(form: form),
      ],
    );
  }
}

class _MethodSection extends StatelessWidget {
  final PaymentForm form;

  const _MethodSection({required this.form});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(AppStrings.registerPaymentMethodTitle),
        PaymentMethodSelector(
          selected: form.method,
          onSelected: context.read<RegisterPaymentCubit>().pickMethod,
        ),
      ],
    );
  }
}

class _PayerSection extends StatelessWidget {
  final PaymentForm form;
  final RegisterPaymentNotice? notice;

  const _PayerSection({required this.form, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(AppStrings.registerPaymentPayerTitle),
        Text(
          AppStrings.registerPaymentPayerHelp,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (notice is PayerLeftGroupNotice) ...[
          const PaymentNotice(
            message: AppStrings.registerPaymentPayerLeftGroup,
            tone: PaymentNoticeTone.danger,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        PayerSelector(
          member: form.ledger.member,
          relatives: form.ledger.familyMembers,
          selectedPayerId: form.payerId,
          onSelected: context.read<RegisterPaymentCubit>().pickPayer,
        ),
      ],
    );
  }
}

class _ReviewBar extends StatelessWidget {
  final PaymentForm form;
  final bool isSubmitting;

  const _ReviewBar({required this.form, required this.isSubmitting});

  Future<void> _review(BuildContext context) async {
    final cubit = context.read<RegisterPaymentCubit>();
    final confirmed = await PaymentConfirmationSheet.show(context, form);

    if (confirmed) await cubit.submit();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  form.canReview
                      ? PaymentFormats.monthsSummary(form.selectedMonths)
                      : AppStrings.registerPaymentIncomplete,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: form.canReview && !isSubmitting
                    ? () => _review(context)
                    : null,
                child: isSubmitting
                    ? const _ButtonSpinner()
                    : Text(_label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label => form.canReview
      ? AppStrings.registerPaymentReviewWithTotal(
          PaymentFormats.pesos(form.totalCents),
        )
      : AppStrings.registerPaymentReviewAction;
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.textOnDark,
      ),
    );
  }
}

class _RegisterPaymentSkeleton extends StatelessWidget {
  const _RegisterPaymentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 96, borderRadius: AppRadius.lgAll),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 48),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 248),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 56),
        ],
      ),
    );
  }
}
