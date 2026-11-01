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
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/inline_error_card.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/homonyms.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/payment_receipt.dart';
import '../cubit/member_roster_cubit.dart';
import '../cubit/member_roster_state.dart';
import '../formatting/payment_formats.dart';

class PaymentMemberPickerScreen extends StatelessWidget {
  const PaymentMemberPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemberRosterCubit>(
      create: (_) => sl<MemberRosterCubit>()..load(),
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
    return BlocBuilder<MemberRosterCubit, MemberRosterState>(
      builder: (context, state) => switch (state) {
        MemberRosterLoading() => const _PickerSkeleton(),
        MemberRosterReady() => _PickerContent(roster: state),
        MemberRosterFailure(previous: final roster?) =>
          _PickerContent(roster: roster),
        MemberRosterFailure(:final message) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: InlineErrorCard(
              title: AppStrings.adminMembersErrorTitle,
              message: message,
              onRetry: context.read<MemberRosterCubit>().load,
            ),
          ),
      },
    );
  }
}

class _PickerContent extends StatelessWidget {
  final MemberRosterReady roster;

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
    final homonyms =
        Homonyms.among(roster.members.where((member) => member.isActive));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _PickerIntro(query: roster.searchQuery),
              ),
              if (candidates.isEmpty)
                SliverToBoxAdapter(child: _emptyMessage()),
              if (overdue.isNotEmpty)
                _PickerSection(
                  title: AppStrings.paymentPickerOverdueSection(overdue.length),
                  members: overdue,
                  homonyms: homonyms,
                ),
              if (upToDate.isNotEmpty)
                _PickerSection(
                  title:
                      AppStrings.paymentPickerUpToDateSection(upToDate.length),
                  members: upToDate,
                  homonyms: homonyms,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyMessage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        roster.hasSearchQuery
            ? AppStrings.adminMembersEmptySearch
            : AppStrings.paymentPickerNoMembers,
        style: AppTextStyles.bodyLargeMuted,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PickerIntro extends StatelessWidget {
  final String query;

  const _PickerIntro({required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.paymentPickerQuestion,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerSearchField(query: query),
        const SizedBox(height: AppSpacing.lg),
      ],
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
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(_PickerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == _controller.text) return;

    _controller.text = widget.query;
    if (widget.query.isEmpty) _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: true,
      onChanged: context.read<MemberRosterCubit>().search,
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
  final Homonyms homonyms;

  const _PickerSection({
    required this.title,
    required this.members,
    required this.homonyms,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.sectionLabel),
              ),
            ),
          ),
          SliverList.separated(
            itemCount: members.length,
            itemBuilder: (_, index) => PaymentMemberPickerTile(
              member: members[index],
              showsDni: homonyms.includes(members[index]),
            ),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          ),
        ],
      ),
    );
  }
}

class PaymentMemberPickerTile extends StatelessWidget {
  final Member member;
  final bool showsDni;

  const PaymentMemberPickerTile({
    super.key,
    required this.member,
    this.showsDni = false,
  });

  Future<void> _pick(BuildContext context) async {
    final roster = context.read<MemberRosterCubit>();
    final router = GoRouter.of(context);
    final receipt = await context.push<PaymentReceipt>(
      AppRoutes.adminPaymentRegistration(member.id),
    );
    if (receipt == null || !context.mounted) return;

    showAppActionSnackBar(
      context,
      AppStrings.paymentRegisteredFor(
        PaymentFormats.receiptAnnouncement(receipt),
        member.fullName,
      ),
      SnackBarAction(
        label: AppStrings.paymentViewMember,
        onPressed: () => router.push(
          AppRoutes.adminMemberLedger(member.id),
          extra: receipt,
        ),
      ),
    );
    roster.clearSearch();
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
            child: _PickerTileContent(member: member, showsDni: showsDni),
          ),
        ),
      ),
    );
  }
}

class _PickerTileContent extends StatelessWidget {
  final Member member;
  final bool showsDni;

  const _PickerTileContent({required this.member, required this.showsDni});

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
                if (showsDni)
                  Text(
                    AppStrings.memberDni(DisplayFormats.dni(member.dni)),
                    style: AppTextStyles.bodyMedium,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppPill(
            label: member.isOverdue
                ? AppStrings.daysOverdueBadge(member.daysOverdue)
                : AppStrings.memberUpToDateBadge,
            tone: member.isOverdue
                ? AppPillTone.danger
                : AppPillTone.success,
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
