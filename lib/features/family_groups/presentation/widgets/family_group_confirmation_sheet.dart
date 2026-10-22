import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../../../shared/widgets/summary_table.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/family_group.dart';
import '../../domain/entities/family_group_build.dart';
import '../cubit/family_group_builder_cubit.dart';
import '../cubit/family_group_builder_state.dart';
import '../formatting/family_group_formats.dart';

class FamilyGroupJoinTarget {
  final FamilyGroup group;
  final List<Member> members;

  const FamilyGroupJoinTarget({required this.group, required this.members});
}

class FamilyGroupConfirmationSheet extends StatefulWidget {
  final Member member;
  final Member relative;
  final FamilyGroupJoinTarget? joinTarget;

  const FamilyGroupConfirmationSheet({
    super.key,
    required this.member,
    required this.relative,
    this.joinTarget,
  });

  static Future<String?> show(
    BuildContext context,
    FamilyGroupConfirmationSheet sheet,
  ) {
    return showAppSheet<String>(
      context,
      (_) => BlocProvider<FamilyGroupBuilderCubit>(
        create: (_) => sl<FamilyGroupBuilderCubit>(),
        child: sheet,
      ),
    );
  }

  @override
  State<FamilyGroupConfirmationSheet> createState() =>
      _FamilyGroupConfirmationSheetState();
}

class _FamilyGroupConfirmationSheetState
    extends State<FamilyGroupConfirmationSheet> {
  late final TextEditingController _name = TextEditingController(
    text: FamilyGroupFormats.defaultName(widget.member),
  );

  FamilyGroupJoinTarget? get _joinTarget => widget.joinTarget;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final cubit = context.read<FamilyGroupBuilderCubit>();
    final target = _joinTarget;
    final succeeded = target == null
        ? await cubit.build(_buildRequest())
        : await cubit.join(widget.member.id, target.group.id);
    if (succeeded && mounted) Navigator.of(context).pop(_successMessage());
  }

  FamilyGroupBuildRequest _buildRequest() => FamilyGroupBuildRequest(
        memberIds: [widget.member.id, widget.relative.id],
        name: _name.text,
      );

  String _successMessage() {
    final target = _joinTarget;
    if (target == null) {
      return AppStrings.familyGroupBuilt(widget.relative.fullName);
    }

    return AppStrings.familyGroupJoined(
      widget.member.fullName,
      FamilyGroupFormats.displayName(target.group),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyGroupBuilderCubit, FamilyGroupBuilderState>(
      builder: (context, state) => AppSheetFrame(
        title: _title(),
        children: [
          if (state.failure != null) ...[
            _FailureNotice(state: state, pending: _pendingMembers(state)),
            const SizedBox(height: AppSpacing.lg),
          ],
          SummaryTable(rows: _rows(state)),
          if (_joinTarget == null && !state.isPartial) ...[
            const SizedBox(height: AppSpacing.lg),
            _GroupNameField(controller: _name, enabled: !state.isSaving),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppNotice(message: _note()),
          const SizedBox(height: AppSpacing.lg),
          ..._actions(state),
        ],
      ),
    );
  }

  String _title() {
    final target = _joinTarget;
    if (target == null) return AppStrings.familyGroupConfirmBuildTitle;

    return AppStrings.familyGroupConfirmJoinTitle(
      widget.member.fullName,
      FamilyGroupFormats.displayName(target.group),
    );
  }

  String _note() => _joinTarget == null
      ? AppStrings.familyGroupIndividualFeePair
      : AppStrings.familyGroupIndividualFeeGroup;

  List<Member> _pendingMembers(FamilyGroupBuilderState state) => [
        widget.member,
        widget.relative,
      ].where((m) => !state.progress.assignedMemberIds.contains(m.id)).toList();

  List<SummaryRow> _rows(FamilyGroupBuilderState state) {
    final target = _joinTarget;
    if (target != null) return _joinRows(target);
    if (state.isPartial) return _partialRows(state);

    return [
      SummaryRow(
        AppStrings.familyGroupRowMembers,
        FamilyGroupFormats.namesInLines([widget.member, widget.relative]),
      ),
    ];
  }

  List<SummaryRow> _joinRows(FamilyGroupJoinTarget target) => [
        SummaryRow(
          AppStrings.familyGroupRowGroup,
          FamilyGroupFormats.displayName(target.group),
        ),
        SummaryRow(
          AppStrings.familyGroupRowCurrentMembers,
          FamilyGroupFormats.namesInLines(target.members),
        ),
        SummaryRow(AppStrings.familyGroupRowJoining, widget.member.fullName),
      ];

  List<SummaryRow> _partialRows(FamilyGroupBuilderState state) {
    final pending = _pendingMembers(state);
    final assigned = [widget.member, widget.relative]
        .where((member) => !pending.contains(member))
        .toList();

    return [
      if (assigned.isNotEmpty)
        SummaryRow(
          AppStrings.familyGroupRowAlreadyIn,
          FamilyGroupFormats.namesInLines(assigned),
        ),
      SummaryRow(
        AppStrings.familyGroupRowMissing,
        FamilyGroupFormats.namesInLines(pending),
      ),
    ];
  }

  List<Widget> _actions(FamilyGroupBuilderState state) => [
        AppButton(
          text: _primaryLabel(state),
          isLoading: state.isSaving,
          onPressed: _confirm,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: AppStrings.cancelAction,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];

  String _primaryLabel(FamilyGroupBuilderState state) {
    if (state.failure != null) return AppStrings.retryAction;

    return _joinTarget == null
        ? AppStrings.familyGroupBuildConfirm
        : AppStrings.familyGroupJoinConfirm;
  }
}

class _GroupNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _GroupNameField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: FamilyGroup.nameMaxLength,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: AppStrings.familyGroupNameLabel,
        helperText: AppStrings.familyGroupNameHelp,
      ),
    );
  }
}

class _FailureNotice extends StatelessWidget {
  final FamilyGroupBuilderState state;
  final List<Member> pending;

  const _FailureNotice({required this.state, required this.pending});

  @override
  Widget build(BuildContext context) {
    final (title, message) = _copy();

    return AppNotice(
      title: title,
      message: message,
      tone: AppNoticeTone.danger,
    );
  }

  (String, String) _copy() {
    if (state.isPartial) {
      return (
        AppStrings.familyGroupPartialTitle,
        AppStrings.familyGroupBuildPartial(FamilyGroupFormats.namesList(pending)),
      );
    }
    if (state.isOffline) {
      return (AppStrings.familyGroupOfflineTitle, AppStrings.familyGroupBuildOffline);
    }

    return (AppStrings.familyGroupServerTitle, AppStrings.familyGroupServerMessage);
  }
}
