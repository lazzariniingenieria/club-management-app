import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/presentation/cubit/admin_payments_cubit.dart';
import '../../../members/presentation/cubit/admin_payments_state.dart';
import '../../domain/entities/payment_receipt.dart';
import '../formatting/payment_formats.dart';
import '../widgets/payment_pill.dart';

class PaymentMemberPickerScreen extends StatelessWidget {
  const PaymentMemberPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminPaymentsCubit>(
      create: (_) => sl<AdminPaymentsCubit>()..load(),
      child: const AdminScaffold(
        title: AppStrings.paymentPickerTitle,
        body: _PickerBody(),
      ),
    );
  }
}

class _PickerBody extends StatelessWidget {
  const _PickerBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminPaymentsCubit, AdminPaymentsState>(
      builder: (context, state) => switch (state) {
        AdminPaymentsLoading() => const _PickerSkeleton(),
        AdminPaymentsReady() => _PickerContent(roster: state),
        AdminPaymentsFailure(previous: final roster?) =>
          _PickerContent(roster: roster),
        AdminPaymentsFailure(:final message) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ErrorRetryView(
              title: AppStrings.adminPaymentsErrorTitle,
              message: message,
              onRetry: context.read<AdminPaymentsCubit>().load,
            ),
          ),
      },
    );
  }
}

class _PickerContent extends StatelessWidget {
  final AdminPaymentsReady roster;

  const _PickerContent({required this.roster});

  List<Member> get _candidates => roster.members
      .where((member) => member.isActive && member.matches(roster.searchQuery))
      .toList();

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    final overdue = candidates.where((member) => member.isOverdue).toList()
      ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
    final upToDate = candidates.where((member) => !member.isOverdue).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          AppStrings.paymentPickerQuestion,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerSearchField(query: roster.searchQuery),
        const SizedBox(height: AppSpacing.lg),
        if (candidates.isEmpty) _emptyMessage(),
        if (overdue.isNotEmpty)
          _PickerSection(
            title: AppStrings.paymentPickerOverdueSection(overdue.length),
            members: overdue,
          ),
        if (upToDate.isNotEmpty)
          _PickerSection(
            title: AppStrings.paymentPickerUpToDateSection(upToDate.length),
            members: upToDate,
          ),
      ],
    );
  }

  Widget _emptyMessage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        roster.hasSearchQuery
            ? AppStrings.adminPaymentsEmptySearch
            : AppStrings.paymentPickerNoMembers,
        style: AppTextStyles.bodyLargeMuted,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PickerSearchField extends StatefulWidget {
  final String query;

  const _PickerSearchField({required this.query});

  @override
  State<_PickerSearchField> createState() => _PickerSearchFieldState();
}

class _PickerSearchFieldState extends State<_PickerSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      onChanged: context.read<AdminPaymentsCubit>().search,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyLarge,
      decoration: const InputDecoration(
        hintText: AppStrings.paymentPickerSearchHint,
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
      ),
    );
  }
}

class _PickerSection extends StatelessWidget {
  final String title;
  final List<Member> members;

  const _PickerSection({required this.title, required this.members});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.sectionLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final member in members) ...[
            PaymentMemberPickerTile(member: member),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class PaymentMemberPickerTile extends StatelessWidget {
  final Member member;

  const PaymentMemberPickerTile({super.key, required this.member});

  Future<void> _pick(BuildContext context) async {
    final receipt = await context.push<PaymentReceipt>(
      AppRoutes.adminPaymentRegistration(member.id),
    );
    if (receipt == null || !context.mounted) return;

    context.pushReplacement(
      AppRoutes.adminMemberLedger(member.id),
      extra: receipt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: _PickerTileContent(member: member),
          ),
        ),
      ),
    );
  }
}

class _PickerTileContent extends StatelessWidget {
  final Member member;

  const _PickerTileContent({required this.member});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: AppTextStyles.labelLarge),
                Text(
                  AppStrings.memberDni(PaymentFormats.dni(member.dni)),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PaymentPill(
            label: member.isOverdue
                ? AppStrings.daysOverdueBadge(member.daysOverdue)
                : AppStrings.memberUpToDateBadge,
            tone: member.isOverdue
                ? PaymentPillTone.danger
                : PaymentPillTone.success,
          ),
        ],
      ),
    );
  }
}

class _PickerSkeleton extends StatelessWidget {
  const _PickerSkeleton();

  static const int _placeholderRows = 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 20, width: 260),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 56),
          const SizedBox(height: AppSpacing.lg),
          for (var row = 0; row < _placeholderRows; row++) ...[
            const SkeletonBox(height: 64),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
