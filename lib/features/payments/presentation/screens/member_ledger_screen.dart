import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/presentation/widgets/member_status_badge.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/member_ledger.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_receipt.dart';
import '../cubit/member_ledger_cubit.dart';
import '../cubit/member_ledger_state.dart';
import '../formatting/payment_formats.dart';
import '../widgets/fee_standing_card.dart';
import '../widgets/member_header_card.dart';
import '../widgets/payment_detail_sheet.dart';
import '../widgets/payment_history_tile.dart';
import '../widgets/payment_notice.dart';
import '../widgets/payment_secondary_button.dart';
import '../widgets/payment_unavailable_view.dart';
import '../widgets/void_payment_sheet.dart';

class MemberLedgerScreen extends StatelessWidget {
  final int memberId;
  final PaymentReceipt? receipt;

  const MemberLedgerScreen({super.key, required this.memberId, this.receipt});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemberLedgerCubit>(
      create: (_) => sl<MemberLedgerCubit>()..load(memberId),
      child: AdminScaffold(
        title: AppStrings.ledgerTitle,
        body: _MemberLedgerView(memberId: memberId, receipt: receipt),
      ),
    );
  }
}

class _MemberLedgerView extends StatefulWidget {
  final int memberId;
  final PaymentReceipt? receipt;

  const _MemberLedgerView({required this.memberId, this.receipt});

  @override
  State<_MemberLedgerView> createState() => _MemberLedgerViewState();
}

class _MemberLedgerViewState extends State<_MemberLedgerView> {
  PaymentReceipt? _receipt;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
    final receipt = _receipt;
    if (receipt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _announce(receipt);
      });
    }
  }

  void _announce(PaymentReceipt receipt) {
    showAppSnackBar(
      context,
      AppStrings.paymentRegistered(
        PaymentFormats.monthsSummary(receipt.months).toLowerCase(),
        PaymentFormats.pesos(receipt.totalCents),
      ),
    );
  }

  Future<void> _registerPayment() async {
    final cubit = context.read<MemberLedgerCubit>();
    final receipt = await context.push<PaymentReceipt>(
      AppRoutes.adminPaymentRegistration(widget.memberId),
    );
    if (receipt == null || !mounted) return;

    setState(() => _receipt = receipt);
    _announce(receipt);
    await cubit.reload();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemberLedgerCubit, MemberLedgerState>(
      builder: (context, state) => switch (state) {
        MemberLedgerLoading() => const _LedgerSkeleton(),
        MemberLedgerReady(:final ledger) => _LedgerContent(
            ledger: ledger,
            newMonths: _receipt?.months.toSet() ?? const {},
            onRegister: _registerPayment,
          ),
        MemberLedgerFailure(:final isOffline) => PaymentUnavailableView(
            kind: isOffline
                ? PaymentUnavailableKind.offline
                : PaymentUnavailableKind.server,
            onRetry: context.read<MemberLedgerCubit>().reload,
          ),
        MemberLedgerMissing() => const PaymentUnavailableView(
            kind: PaymentUnavailableKind.missing,
          ),
      },
    );
  }
}

class _LedgerContent extends StatelessWidget {
  final MemberLedger ledger;
  final Set<BillingMonth> newMonths;
  final VoidCallback onRegister;

  const _LedgerContent({
    required this.ledger,
    required this.newMonths,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: context.read<MemberLedgerCubit>().reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _LedgerHeader(ledger: ledger),
                const SizedBox(height: AppSpacing.md),
                FeeStandingCard(ledger: ledger),
                if (_newMemberNote(ledger) != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  PaymentNotice(message: _newMemberNote(ledger)!),
                ],
                const SizedBox(height: AppSpacing.xl),
                _HistorySection(ledger: ledger, newMonths: newMonths),
              ],
            ),
          ),
        ),
        _LedgerFooter(ledger: ledger, onRegister: onRegister),
      ],
    );
  }

  static String? _newMemberNote(MemberLedger ledger) {
    final joinedAt = ledger.member.joinedAt;
    if (!ledger.hasNeverPaid || joinedAt == null) return null;
    if (BillingMonth.of(joinedAt) != BillingMonth.of(DateTime.now())) {
      return null;
    }

    return AppStrings.ledgerNewMemberNote(
      PaymentFormats.day(joinedAt),
      PaymentFormats.monthName(BillingMonth.of(joinedAt)),
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  final MemberLedger ledger;

  const _LedgerHeader({required this.ledger});

  void _edit(BuildContext context) {
    context.push(
      AppRoutes.adminMemberEdition(ledger.member.id),
      extra: ledger.member,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemberHeaderCard(
      member: ledger.member,
      details: MemberStatusBadge(status: ledger.member.status),
      trailing: IconButton(
        onPressed: () => _edit(context),
        tooltip: AppStrings.memberEditAction,
        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final MemberLedger ledger;
  final Set<BillingMonth> newMonths;

  const _HistorySection({required this.ledger, required this.newMonths});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.ledgerHistoryTitle.toUpperCase(),
          style: AppTextStyles.sectionLabel,
        ),
        if (ledger.livePayments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(AppStrings.ledgerHistoryHint, style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: AppSpacing.md),
        if (ledger.payments.isEmpty) const _EmptyHistory(),
        for (final payment in ledger.payments) ...[
          _historyTile(context, payment),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _historyTile(BuildContext context, Payment payment) {
    return PaymentHistoryTile(
      payment: payment,
      ledger: ledger,
      isNew: newMonths.contains(payment.month),
      onOpen: () => _openPayment(context, payment),
    );
  }

  Future<void> _openPayment(BuildContext context, Payment payment) async {
    final wantsToVoid = await PaymentDetailSheet.show(
      context,
      payment: payment,
      ledger: ledger,
    );
    if (!wantsToVoid || !context.mounted) return;

    final reason = await VoidPaymentSheet.show(
      context,
      payment: payment,
      memberName: ledger.member.fullName,
    );
    if (reason == null || !context.mounted) return;

    await _void(context, payment, reason);
  }

  Future<void> _void(
    BuildContext context,
    Payment payment,
    String reason,
  ) async {
    final failure = await context
        .read<MemberLedgerCubit>()
        .voidPayment(payment, reason: reason);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      _voidMessage(payment, failure),
      isError: failure != null && failure is! ConflictFailure,
    );
  }

  static String _voidMessage(Payment payment, Failure? failure) {
    return switch (failure) {
      null => AppStrings.voidPaymentDone(
          PaymentFormats.monthWithYear(payment.month),
        ),
      ConflictFailure() => AppStrings.voidPaymentAlreadyVoided,
      final Failure other => other.userMessage,
    };
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.disabledText),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 32,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.ledgerEmptyTitle, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.ledgerEmptyMessage,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LedgerFooter extends StatelessWidget {
  final MemberLedger ledger;
  final VoidCallback onRegister;

  const _LedgerFooter({required this.ledger, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ledger.canRecordPayments
              ? _RegisterButton(
                  label: _labelFor(ledger),
                  onPressed: onRegister,
                )
              : _InactiveFooter(ledger: ledger),
        ),
      ),
    );
  }

  static String _labelFor(MemberLedger ledger) {
    if (!ledger.hasNeverPaid) return AppStrings.ledgerRegisterAction;

    final joinedAt = ledger.member.joinedAt;
    if (joinedAt == null ||
        BillingMonth.of(joinedAt) != BillingMonth.of(DateTime.now())) {
      return AppStrings.ledgerRegisterFirstAction;
    }

    return AppStrings.ledgerRegisterMonthAction(
      PaymentFormats.monthName(BillingMonth.of(joinedAt)),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RegisterButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.payments_outlined),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandGreen,
        foregroundColor: AppColors.textOnDark,
      ),
    );
  }
}

class _InactiveFooter extends StatelessWidget {
  final MemberLedger ledger;

  const _InactiveFooter({required this.ledger});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.ledgerInactiveHint, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        PaymentSecondaryButton(
          label: AppStrings.memberEditAction,
          onPressed: () => context.push(
            AppRoutes.adminMemberEdition(ledger.member.id),
            extra: ledger.member,
          ),
        ),
      ],
    );
  }
}

class _LedgerSkeleton extends StatelessWidget {
  const _LedgerSkeleton();

  static const int _placeholderRows = 4;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 92, borderRadius: AppRadius.lgAll),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 96, borderRadius: AppRadius.lgAll),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBox(height: 16, width: 180),
          const SizedBox(height: AppSpacing.md),
          for (var row = 0; row < _placeholderRows; row++) ...[
            const SkeletonBox(height: 84),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
