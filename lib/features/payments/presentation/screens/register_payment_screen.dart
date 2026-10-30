import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/amount_field.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../cubit/payment_form.dart';
import '../cubit/register_payment_cubit.dart';
import '../cubit/register_payment_state.dart';
import '../formatting/payment_formats.dart';
import '../widgets/billing_month_grid.dart';
import '../widgets/family_payment_section.dart';
import '../widgets/member_header_card.dart';
import '../widgets/payer_selector.dart';
import '../widgets/payment_confirmation_sheet.dart';
import '../widgets/payment_method_selector.dart';
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
    if (state.isInactive) return PaymentUnavailableKind.inactive;

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
                _TopNotice(notice: state.notice!, form: form),
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
              if (form.activeRelatives.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                _FamilySection(form: form),
              ],
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
        AppPill(
          label: member.isOverdue
              ? AppStrings.daysOverdueBadge(member.daysOverdue)
              : AppStrings.memberUpToDateBadge,
          tone: member.isOverdue
              ? AppPillTone.danger
              : AppPillTone.success,
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
  final PaymentForm form;

  const _TopNotice({required this.notice, required this.form});

  @override
  Widget build(BuildContext context) {
    return switch (notice) {
      OfflineNotice() => _RetryNotice(
          title: AppStrings.registerPaymentOfflineTitle,
          message: AppStrings.registerPaymentOfflineMessage,
          form: form,
        ),
      PaymentUnconfirmedNotice() => _RetryNotice(
          title: AppStrings.registerPaymentUnconfirmedTitle,
          message: AppStrings.registerPaymentUnconfirmedMessage,
          form: form,
        ),
      SubmitFailedNotice(:final message) => AppNotice(
          message: message,
          tone: AppNoticeTone.danger,
        ),
      final FamilyPaymentIncompleteNotice incomplete =>
        _FamilyIncompleteNotice(notice: incomplete, form: form),
      FamilyAlreadyPaidNotice() => const AppNotice(
          message: AppStrings.familyPaymentAlreadyPaid,
          tone: AppNoticeTone.danger,
        ),
      MonthsAlreadyPaidNotice() ||
      PayerLeftGroupNotice() =>
        const SizedBox.shrink(),
    };
  }
}

class _FamilyIncompleteNotice extends StatelessWidget {
  final FamilyPaymentIncompleteNotice notice;
  final PaymentForm form;

  const _FamilyIncompleteNotice({required this.notice, required this.form});

  @override
  Widget build(BuildContext context) {
    final title = _titleOf(notice);
    final message = _messageOf(notice, form);
    if (notice.pendingIds.isNotEmpty) {
      return _RetryNotice(title: title, message: message, form: form);
    }

    return AppNotice(
      title: title,
      message: message,
      tone: AppNoticeTone.danger,
    );
  }

  static String _titleOf(FamilyPaymentIncompleteNotice notice) {
    if (notice.pendingIds.isEmpty) return AppStrings.familyPaymentLeftOutTitle;
    if (notice.registeredIds.isNotEmpty) {
      return AppStrings.familyPaymentPartialTitle;
    }

    return notice.mayHaveLanded
        ? AppStrings.familyPaymentUnconfirmedTitle
        : AppStrings.familyPaymentNotRegisteredTitle;
  }

  static String _messageOf(
    FamilyPaymentIncompleteNotice notice,
    PaymentForm form,
  ) {
    String names(List<int> ids) => DisplayFormats.listed(
          [for (final id in ids) form.ledger.nameOf(id) ?? ''],
        );

    return [
      if (notice.registeredIds.isNotEmpty)
        AppStrings.familyPaymentRegisteredFor(names(notice.registeredIds)),
      if (notice.pendingIds.isNotEmpty)
        AppStrings.familyPaymentPendingFor(names(notice.pendingIds)),
      if (notice.leftNames.isNotEmpty)
        AppStrings.familyPaymentRelativesLeft(
          DisplayFormats.listed(notice.leftNames),
          notice.leftNames.length,
        ),
      if (notice.payerLeft) AppStrings.familyPaymentPayerLeft,
      ..._retryOf(notice, form),
    ].join(' ');
  }

  static List<String> _retryOf(
    FamilyPaymentIncompleteNotice notice,
    PaymentForm form,
  ) {
    if (notice.pendingIds.isEmpty) return const [];
    if (form.canFinishFamily) return const [AppStrings.familyPaymentFinishHint];

    return [
      notice.mayHaveLanded
          ? AppStrings.familyPaymentRetryUnconfirmed
          : AppStrings.familyPaymentRetryPending,
      if (form.isChargeLocked) AppStrings.familyPaymentLocked,
    ];
  }
}

class _RetryNotice extends StatelessWidget {
  final String title;
  final String message;
  final PaymentForm form;

  const _RetryNotice({
    required this.title,
    required this.message,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final finishes = form.canFinishFamily;

    return AppNotice(
      title: title,
      message: message,
      tone: AppNoticeTone.danger,
      action: OutlinedButton(
        onPressed:
            finishes || form.canReview ? () => _proceed(context, form) : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dangerText,
          side: const BorderSide(color: AppColors.dangerText),
          minimumSize: const Size(0, 48),
        ),
        child: Text(
          finishes
              ? AppStrings.familyPaymentFinishAction
              : AppStrings.retryAction,
        ),
      ),
    );
  }
}

class _LockedWhenPaying extends StatelessWidget {
  final PaymentForm form;
  final Widget child;

  const _LockedWhenPaying({required this.form, required this.child});

  static const double _lockedOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    final locked = form.isChargeLocked;

    return ExcludeFocus(
      excluding: locked,
      child: IgnorePointer(
        ignoring: locked,
        child: Opacity(opacity: locked ? _lockedOpacity : 1, child: child),
      ),
    );
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
        _LockedWhenPaying(
          form: form,
          child: BillingMonthGrid(
            form: form,
            onToggle: cubit.toggleMonth,
            onShowYear: cubit.showYear,
          ),
        ),
        if (repeated is MonthsAlreadyPaidNotice)
          AppNotice(
            message: AppStrings.registerPaymentMonthsAlreadyPaid(
              PaymentFormats.monthsSummary(repeated.months),
            ),
            tone: AppNoticeTone.danger,
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
        _LockedWhenPaying(
          form: form,
          child: AmountField(
            label: AppStrings.registerPaymentAmountLabel,
            initialCents: form.amountCents,
            onChanged: context.read<RegisterPaymentCubit>().changeAmount,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          fee == null
              ? AppStrings.registerPaymentAmountWithoutFee
              : AppStrings.registerPaymentAmountWithFee(
                  DisplayFormats.pesos(fee),
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
        _LockedWhenPaying(
          form: form,
          child: PaymentMethodSelector(
            selected: form.method,
            onSelected: context.read<RegisterPaymentCubit>().pickMethod,
          ),
        ),
      ],
    );
  }
}

class _FamilySection extends StatelessWidget {
  final PaymentForm form;

  const _FamilySection({required this.form});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterPaymentCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(AppStrings.registerPaymentFamilyTitle),
        FamilyPaymentSection(
          form: form,
          onToggle: form.isChargeLocked
              ? null
              : (enabled) => cubit.payForFamily(enabled: enabled),
          onToggleRelative: cubit.toggleRelative,
          onRetry: cubit.reloadFamilyStatus,
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
          const AppNotice(
            message: AppStrings.registerPaymentPayerLeftGroup,
            tone: AppNoticeTone.danger,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _LockedWhenPaying(
          form: form,
          child: PayerSelector(
            member: form.ledger.member,
            relatives: form.ledger.familyMembers,
            selectedPayerId: form.payerId,
            onSelected: context.read<RegisterPaymentCubit>().pickPayer,
          ),
        ),
      ],
    );
  }
}

class _ReviewBar extends StatelessWidget {
  final PaymentForm form;
  final bool isSubmitting;

  const _ReviewBar({required this.form, required this.isSubmitting});

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
                  _summaryOf(form),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: _canProceed && !isSubmitting
                    ? () => _proceed(context, form)
                    : null,
                child: isSubmitting ? const _ButtonSpinner() : Text(_label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _summaryOf(PaymentForm form) {
    final months = PaymentFormats.monthsSummary(form.selectedMonths);
    if (form.canReview) {
      return form.paysForFamily
          ? AppStrings.registerPaymentFamilySummary(
              months,
              AppStrings.memberCount(form.payingMembers.length),
            )
          : months;
    }
    final nothingLeft = (form.family?.isReady ?? false) && form.feeCount == 0;

    return nothingLeft
        ? AppStrings.registerPaymentFamilyNothingLeft
        : AppStrings.registerPaymentIncomplete;
  }

  bool get _canProceed => form.canReview || form.canFinishFamily;

  String get _label {
    if (form.canFinishFamily) return AppStrings.familyPaymentFinishAction;

    return form.canReview
        ? AppStrings.registerPaymentReviewWithTotal(
            DisplayFormats.pesos(form.totalCents),
          )
        : AppStrings.registerPaymentReviewAction;
  }
}

Future<void> _proceed(BuildContext context, PaymentForm form) async {
  final cubit = context.read<RegisterPaymentCubit>();
  if (form.canFinishFamily) return cubit.finishFamily();

  final confirmed = await PaymentConfirmationSheet.show(context, form);
  if (confirmed) await cubit.submit();
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
