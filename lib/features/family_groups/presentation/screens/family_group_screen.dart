import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../../members/domain/entities/member.dart';
import '../../../members/presentation/widgets/member_list_tile.dart';
import '../../../payments/domain/entities/payment_receipt.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';
import '../../domain/entities/family_group_detail.dart';
import '../cubit/family_group_cubit.dart';
import '../cubit/family_group_state.dart';
import '../formatting/family_group_formats.dart';
import '../widgets/family_group_name_sheet.dart';

class FamilyGroupScreen extends StatelessWidget {
  final int familyGroupId;

  const FamilyGroupScreen({super.key, required this.familyGroupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FamilyGroupCubit>(
      create: (_) => sl<FamilyGroupCubit>()..load(familyGroupId),
      child: AdminScaffold(
        title: AppStrings.familyGroupScreenTitle,
        body: _FamilyGroupView(familyGroupId: familyGroupId),
      ),
    );
  }
}

class _FamilyGroupView extends StatefulWidget {
  final int familyGroupId;

  const _FamilyGroupView({required this.familyGroupId});

  @override
  State<_FamilyGroupView> createState() => _FamilyGroupViewState();
}

class _FamilyGroupViewState extends State<_FamilyGroupView> {
  int? _newMemberId;

  Future<void> _addMember() async {
    final joined = await context.push<Member>(
      AppRoutes.adminFamilyGroupMemberPicker(widget.familyGroupId),
    );
    if (joined == null || !mounted) return;

    setState(() => _newMemberId = joined.id);
    showAppSnackBar(context, AppStrings.familyGroupMemberAdded(joined.fullName));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyGroupCubit, FamilyGroupState>(
      builder: (context, state) => switch (state) {
        FamilyGroupLoading() => const _GroupSkeleton(),
        FamilyGroupReady(:final detail) => _GroupContent(
            detail: detail,
            newMemberId: _newMemberId,
            onAdd: _addMember,
          ),
        FamilyGroupFailure(:final isOffline) => StatusMessageView(
            icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
            title: isOffline
                ? AppStrings.ledgerOfflineTitle
                : AppStrings.familyGroupLoadServerTitle,
            message: isOffline
                ? AppStrings.familyGroupLoadOfflineMessage
                : AppStrings.ledgerServerErrorMessage,
            actionLabel: AppStrings.retryAction,
            onAction: context.read<FamilyGroupCubit>().reload,
          ),
        FamilyGroupMissing() => StatusMessageView(
            icon: Icons.group_off_outlined,
            title: AppStrings.familyGroupMissingTitle,
            message: AppStrings.familyGroupMissingMessage,
            actionLabel: AppStrings.backAction,
            onAction: () => _leave(context),
            isError: false,
          ),
      },
    );
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.adminMembers);
  }
}

class _GroupContent extends StatelessWidget {
  final FamilyGroupDetail detail;
  final int? newMemberId;
  final VoidCallback onAdd;

  const _GroupContent({
    required this.detail,
    required this.newMemberId,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: context.read<FamilyGroupCubit>().reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _GroupHeader(detail: detail),
                const SizedBox(height: AppSpacing.xl),
                _MembersSection(detail: detail, newMemberId: newMemberId),
                const SizedBox(height: AppSpacing.md),
                _DeleteGroupAction(detail: detail),
              ],
            ),
          ),
        ),
        _GroupFooter(detail: detail, onAdd: onAdd),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final FamilyGroupDetail detail;

  const _GroupHeader({required this.detail});

  Future<void> _rename(BuildContext context) async {
    final cubit = context.read<FamilyGroupCubit>();
    final saved = await FamilyGroupNameSheet.show(
      context,
      FamilyGroupNameSheet(
        initialName: detail.group.name ?? '',
        onSave: cubit.rename,
      ),
    );
    if (saved && context.mounted) {
      showAppSnackBar(context, AppStrings.familyGroupNameSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FamilyGroupFormats.displayName(detail.group),
                    style: AppTextStyles.titleMedium,
                  ),
                  Text(
                    AppStrings.familyGroupMemberCount(detail.members.length),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _rename(context),
            tooltip: AppStrings.familyGroupEditNameAction,
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final FamilyGroupDetail detail;
  final int? newMemberId;

  const _MembersSection({required this.detail, required this.newMemberId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            AppStrings.familyGroupMembersSection(detail.members.length),
            style: AppTextStyles.sectionLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (detail.members.isEmpty) const _EmptyGroup(),
        for (final member in detail.members) ...[
          _GroupMemberTile(member: member, isNew: member.id == newMemberId),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _GroupMemberTile extends StatelessWidget {
  final Member member;
  final bool isNew;

  const _GroupMemberTile({required this.member, required this.isNew});

  Future<void> _remove(BuildContext context) async {
    final cubit = context.read<FamilyGroupCubit>();
    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.familyGroupRemoveTitle(member.fullName),
        message: AppStrings.familyGroupRemoveMessage,
        confirmLabel: AppStrings.familyGroupRemoveConfirm,
        isDestructive: true,
      ),
    );
    if (!confirmed) return;

    final failure = await cubit.remove(member);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      failure == null
          ? AppStrings.familyGroupMemberRemoved(member.fullName)
          : failure.userMessage,
      isError: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemberListTile(
      member: member,
      onOpen: () => context.push(AppRoutes.adminMemberLedger(member.id)),
      onRemove: () => _remove(context),
      tag: isNew
          ? const AppPill(
              label: AppStrings.ledgerNewTag,
              tone: AppPillTone.highlight,
            )
          : null,
    );
  }
}

class _EmptyGroup extends StatelessWidget {
  const _EmptyGroup();

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
          const Icon(Icons.groups_outlined, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.familyGroupEmptyTitle, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.familyGroupEmptyHint,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DeleteGroupAction extends StatefulWidget {
  final FamilyGroupDetail detail;

  const _DeleteGroupAction({required this.detail});

  @override
  State<_DeleteGroupAction> createState() => _DeleteGroupActionState();
}

enum _DeleteStep { idle, confirming, deleting }

class _DeleteGroupActionState extends State<_DeleteGroupAction> {
  _DeleteStep _step = _DeleteStep.idle;

  Future<void> _delete() async {
    final cubit = context.read<FamilyGroupCubit>();
    setState(() => _step = _DeleteStep.confirming);

    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: AppStrings.familyGroupDeleteTitle(
          FamilyGroupFormats.displayName(widget.detail.group),
        ),
        message: AppStrings.familyGroupDeleteMessage,
        confirmLabel: AppStrings.familyGroupDeleteConfirm,
        isDestructive: true,
      ),
    );
    if (!mounted) return;
    if (!confirmed) return setState(() => _step = _DeleteStep.idle);

    setState(() => _step = _DeleteStep.deleting);
    final failure = await cubit.delete();
    if (!mounted) return;

    if (failure != null) {
      setState(() => _step = _DeleteStep.idle);
      return showAppSnackBar(context, failure.userMessage, isError: true);
    }
    showAppSnackBar(context, AppStrings.familyGroupDeleted);
    _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _step == _DeleteStep.idle ? _delete : null,
        icon: _step == _DeleteStep.deleting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_outline_rounded),
        label: const Text(AppStrings.familyGroupDeleteAction),
        style: TextButton.styleFrom(foregroundColor: AppColors.dangerText),
      ),
    );
  }
}

class _GroupFooter extends StatelessWidget {
  final FamilyGroupDetail detail;
  final VoidCallback onAdd;

  const _GroupFooter({required this.detail, required this.onAdd});

  Future<void> _payForGroup(BuildContext context, Member anchor) async {
    final cubit = context.read<FamilyGroupCubit>();
    final receipt = await context.push<PaymentReceipt>(
      AppRoutes.adminFamilyPaymentRegistration(anchor.id),
    );
    if (receipt == null || !context.mounted) return;

    showAppSnackBar(context, PaymentFormats.receiptAnnouncement(receipt));
    await cubit.reload();
  }

  @override
  Widget build(BuildContext context) {
    final anchor = detail.paymentAnchor;

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
              if (anchor != null) ...[
                ElevatedButton.icon(
                  onPressed: () => _payForGroup(context, anchor),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text(AppStrings.familyGroupPayAction),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: AppStrings.familyGroupAddAction,
                  onPressed: onAdd,
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text(AppStrings.familyGroupAddAction),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 84, borderRadius: AppRadius.lgAll),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 64),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBox(height: 16, width: 140),
          const SizedBox(height: AppSpacing.md),
          for (var row = 0; row < 3; row++) ...[
            const SkeletonBox(height: 72),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
