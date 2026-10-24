import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/family_group_candidates.dart';
import '../cubit/family_group_builder_cubit.dart';
import '../cubit/family_group_builder_state.dart';
import '../cubit/family_group_picker_cubit.dart';
import '../cubit/family_group_picker_state.dart';
import '../formatting/family_group_formats.dart';
import '../widgets/family_group_confirmation_sheet.dart';
import '../widgets/family_group_membership_chip.dart';

sealed class FamilyGroupPickerMode {
  const FamilyGroupPickerMode();
}

class BuildGroupForMember extends FamilyGroupPickerMode {
  final int memberId;

  const BuildGroupForMember(this.memberId);
}

class AddToFamilyGroup extends FamilyGroupPickerMode {
  final int familyGroupId;

  const AddToFamilyGroup(this.familyGroupId);
}

class FamilyGroupPickerScreen extends StatelessWidget {
  final FamilyGroupPickerMode mode;

  const FamilyGroupPickerScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FamilyGroupPickerCubit>(
          create: (_) => sl<FamilyGroupPickerCubit>()..load(),
        ),
        BlocProvider<FamilyGroupBuilderCubit>(
          create: (_) => sl<FamilyGroupBuilderCubit>(),
        ),
      ],
      child: AdminScaffold(
        title: mode is BuildGroupForMember
            ? AppStrings.familyGroupPickerBuildTitle
            : AppStrings.familyGroupPickerAddTitle,
        body: _PickerBody(mode: mode),
      ),
    );
  }
}

class _PickerBody extends StatelessWidget {
  final FamilyGroupPickerMode mode;

  const _PickerBody({required this.mode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyGroupPickerCubit, FamilyGroupPickerState>(
      builder: (context, state) => switch (state) {
        FamilyGroupPickerLoading() => const _PickerSkeleton(),
        FamilyGroupPickerFailure(:final isOffline) => StatusMessageView(
            icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
            title: AppStrings.familyGroupPickerErrorTitle,
            message: isOffline
                ? AppStrings.networkErrorMessage
                : AppStrings.familyGroupServerMessage,
            actionLabel: AppStrings.retryAction,
            onAction: context.read<FamilyGroupPickerCubit>().load,
          ),
        FamilyGroupPickerReady() => _PickerAnchor(mode: mode, state: state),
      },
    );
  }
}

class _PickerAnchor extends StatelessWidget {
  final FamilyGroupPickerMode mode;
  final FamilyGroupPickerReady state;

  const _PickerAnchor({required this.mode, required this.state});

  @override
  Widget build(BuildContext context) {
    final selection = _PickerSelection.from(mode, state);
    if (selection == null) {
      return StatusMessageView(
        icon: Icons.person_search_outlined,
        title: AppStrings.ledgerMissingTitle,
        message: AppStrings.familyGroupMemberMissingMessage,
        actionLabel: AppStrings.backAction,
        onAction: () => context.pop(),
        isError: false,
      );
    }

    return BlocBuilder<FamilyGroupBuilderCubit, FamilyGroupBuilderState>(
      builder: (context, saving) => AbsorbPointer(
        absorbing: saving.isSaving,
        child: _PickerContent(selection: selection, isSaving: saving.isSaving),
      ),
    );
  }
}

class _PickerSelection {
  final FamilyGroupPickerMode mode;
  final FamilyGroupCandidates candidates;
  final String query;
  final Member? anchorMember;
  final List<Member> groupMembers;

  const _PickerSelection({
    required this.mode,
    required this.candidates,
    required this.query,
    required this.anchorMember,
    required this.groupMembers,
  });

  static _PickerSelection? from(
    FamilyGroupPickerMode mode,
    FamilyGroupPickerReady state,
  ) {
    final candidates = state.candidates;

    return switch (mode) {
      BuildGroupForMember(:final memberId) =>
        candidates.memberById(memberId) == null
            ? null
            : _PickerSelection(
                mode: mode,
                candidates: candidates,
                query: state.searchQuery,
                anchorMember: candidates.memberById(memberId),
                groupMembers: const [],
              ),
      AddToFamilyGroup(:final familyGroupId) => _PickerSelection(
          mode: mode,
          candidates: candidates,
          query: state.searchQuery,
          anchorMember: null,
          groupMembers: candidates.membersOf(familyGroupId),
        ),
    };
  }

  Set<int> get _excludedIds => {
        if (anchorMember != null) anchorMember!.id,
        for (final member in groupMembers) member.id,
      };

  Set<String> get _surnames => {
        if (anchorMember != null) anchorMember!.lastName.toLowerCase(),
        for (final member in groupMembers) member.lastName.toLowerCase(),
      };

  List<Member> get visible {
    final excluded = _excludedIds;

    return candidates.roster
        .where((member) => member.isActive && !excluded.contains(member.id))
        .where((member) => member.matches(query))
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  bool sharesSurname(Member member) =>
      _surnames.contains(member.lastName.toLowerCase());

  String get prompt => switch (mode) {
        BuildGroupForMember() =>
          AppStrings.familyGroupPickerBuildPrompt(anchorMember!.fullName),
        AddToFamilyGroup(:final familyGroupId) =>
          AppStrings.familyGroupPickerAddPrompt(
            FamilyGroupFormats.displayName(candidates.groupById(familyGroupId)),
          ),
      };
}

class _PickerContent extends StatelessWidget {
  final _PickerSelection selection;
  final bool isSaving;

  const _PickerContent({required this.selection, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    final visible = selection.visible;
    final same = visible.where(selection.sharesSurname).toList();
    final others = visible.where((m) => !selection.sharesSurname(m)).toList();

    return CustomScrollView(
      slivers: [
        if (isSaving)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _PickerIntro(selection: selection)),
              if (visible.isEmpty)
                SliverToBoxAdapter(child: _EmptyCandidates(selection.query)),
              if (same.isNotEmpty)
                _CandidateSection(
                  title: AppStrings.familyGroupPickerSameSurname(same.length),
                  members: same,
                  selection: selection,
                ),
              if (others.isNotEmpty)
                _CandidateSection(
                  title: AppStrings.familyGroupPickerOthers,
                  members: others,
                  selection: selection,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerIntro extends StatelessWidget {
  final _PickerSelection selection;

  const _PickerIntro({required this.selection});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(selection.prompt, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.md),
        _SearchField(query: selection.query),
        const SizedBox(height: AppSpacing.sm),
        Text(AppStrings.familyGroupPickerHint, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  final String query;

  const _SearchField({required this.query});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query.isEmpty && _controller.text.isNotEmpty) _controller.clear();
  }

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
      onChanged: context.read<FamilyGroupPickerCubit>().search,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyLarge,
      decoration: const InputDecoration(
        hintText: AppStrings.paymentPickerSearchHint,
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
      ),
    );
  }
}

class _EmptyCandidates extends StatelessWidget {
  final String query;

  const _EmptyCandidates(this.query);

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            hasQuery
                ? AppStrings.familyGroupPickerEmpty(query.trim())
                : AppStrings.familyGroupPickerNoCandidates,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (hasQuery) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.familyGroupPickerEmptyHint,
              style: AppTextStyles.bodyLargeMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: context.read<FamilyGroupPickerCubit>().clearSearch,
              child: const Text(AppStrings.adminPaymentsClearSearch),
            ),
          ],
        ],
      ),
    );
  }
}

class _CandidateSection extends StatelessWidget {
  final String title;
  final List<Member> members;
  final _PickerSelection selection;

  const _CandidateSection({
    required this.title,
    required this.members,
    required this.selection,
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
            itemBuilder: (_, index) =>
                _CandidateTile(member: members[index], selection: selection),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          ),
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final Member member;
  final _PickerSelection selection;

  const _CandidateTile({required this.member, required this.selection});

  @override
  Widget build(BuildContext context) {
    final group = selection.candidates.groupOf(member);

    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _CandidateChoice(context, selection, member).resolve(),
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: _CandidateTileContent(
              member: member,
              groupName: group == null
                  ? null
                  : FamilyGroupFormats.displayName(group),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateTileContent extends StatelessWidget {
  final Member member;
  final String? groupName;

  const _CandidateTileContent({required this.member, required this.groupName});

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
                  AppStrings.memberDni(DisplayFormats.dni(member.dni)),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          if (groupName != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: FamilyGroupMembershipChip(groupName: groupName!)),
          ],
        ],
      ),
    );
  }
}

class _CandidateChoice {
  final BuildContext context;
  final _PickerSelection selection;
  final Member candidate;

  _CandidateChoice(this.context, this.selection, this.candidate);

  FamilyGroupCandidates get _candidates => selection.candidates;

  Future<void> resolve() => switch (selection.mode) {
        BuildGroupForMember() => _confirmBuildOrJoin(),
        AddToFamilyGroup(:final familyGroupId) => _addTo(familyGroupId),
      };

  Future<void> _confirmBuildOrJoin() async {
    final group = _candidates.groupOf(candidate);
    final message = await FamilyGroupConfirmationSheet.show(
      context,
      FamilyGroupConfirmationSheet(
        member: selection.anchorMember!,
        relative: candidate,
        joinTarget: group == null
            ? null
            : FamilyGroupJoinTarget(
                group: group,
                members: _candidates.membersOf(group.id),
              ),
      ),
    );
    if (message != null && context.mounted) context.pop(message);
  }

  Future<void> _addTo(int familyGroupId) async {
    if (!await _confirmMoveIfNeeded(familyGroupId)) return;
    if (!context.mounted) return;

    final cubit = context.read<FamilyGroupBuilderCubit>();
    final joined = await cubit.join(candidate.id, familyGroupId);
    if (!context.mounted) return;
    if (joined) {
      context.pop(candidate);
    } else {
      showAppSnackBar(context, cubit.state.failure!.userMessage, isError: true);
    }
  }

  Future<bool> _confirmMoveIfNeeded(int familyGroupId) async {
    final current = _candidates.groupOf(candidate);
    if (current == null || current.id == familyGroupId) return true;

    return ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.familyGroupMoveTitle(
          candidate.fullName,
          FamilyGroupFormats.displayName(_candidates.groupById(familyGroupId)),
        ),
        message: AppStrings.familyGroupMoveMessage(
          FamilyGroupFormats.displayName(current),
        ),
        confirmLabel: AppStrings.familyGroupMoveConfirm,
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
