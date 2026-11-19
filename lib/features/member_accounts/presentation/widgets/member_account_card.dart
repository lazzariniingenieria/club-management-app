import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../admins/presentation/widgets/new_password_sheet.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/member_account.dart';
import '../cubit/member_account_cubit.dart';
import '../cubit/member_account_state.dart';

class MemberAccountCard extends StatelessWidget {
  final Member member;

  const MemberAccountCard({super.key, required this.member});

  static String _createFailureMessage(Failure failure) {
    if (failure is ConflictFailure) return AppStrings.memberAccountConflict;

    return NewPasswordSheet.defaultFailureMessage(failure);
  }

  Future<void> _create(BuildContext context) {
    return _openSheet(
      context,
      sheetFor: (cubit) => NewPasswordSheet(
        title: AppStrings.memberAccountCreateTitle,
        notice: AppStrings.memberAccountCreateNotice,
        actionLabel: AppStrings.memberAccountCreateAction,
        onSave: cubit.createAccount,
        failureMessage: _createFailureMessage,
      ),
      doneMessage: AppStrings.memberAccountCreated,
    );
  }

  Future<void> _resetPassword(BuildContext context) {
    return _openSheet(
      context,
      sheetFor: (cubit) => NewPasswordSheet(
        title: AppStrings.memberAccountResetAction,
        notice: AppStrings.memberAccountResetNotice,
        actionLabel: AppStrings.memberAccountResetAction,
        onSave: cubit.resetPassword,
      ),
      doneMessage: AppStrings.memberAccountResetDone,
    );
  }

  Future<void> _openSheet(
    BuildContext context, {
    required NewPasswordSheet Function(MemberAccountCubit cubit) sheetFor,
    required String doneMessage,
  }) async {
    final cubit = context.read<MemberAccountCubit>();
    final saved = await NewPasswordSheet.show(context, sheetFor(cubit));
    if (!saved) return cubit.reloadIfStale();

    if (context.mounted) showAppSnackBar(context, doneMessage);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemberAccountCubit, MemberAccountState>(
      builder: (context, state) {
        final content = _contentFor(context, state);
        if (content == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _AccountCardFrame(child: content),
        );
      },
    );
  }

  Widget? _contentFor(BuildContext context, MemberAccountState state) {
    return switch (state) {
      MemberAccountLoading() => const _LoadingContent(),
      MemberAccountDisabled() => null,
      MemberAccountFailure(:final isOffline) => _AccountCardBody(
          title: AppStrings.memberAccountLoadFailed,
          subtitle: isOffline
              ? AppStrings.memberAccountLoadOffline
              : AppStrings.memberAccountLoadServer,
          actionLabel: AppStrings.retryAction,
          onAction: context.read<MemberAccountCubit>().reload,
        ),
      MemberAccountReady(account: final account?) =>
        _existingAccountContent(context, account),
      MemberAccountReady() => _missingAccountContent(context),
    };
  }

  Widget _existingAccountContent(BuildContext context, MemberAccount account) {
    if (!account.canResetPassword) {
      return const _AccountCardBody(title: AppStrings.memberAccountAdmin);
    }

    return _AccountCardBody(
      title:
          AppStrings.memberAccountSignsInWith(DisplayFormats.dni(account.dni)),
      actionLabel: AppStrings.memberAccountResetAction,
      onAction: () => _resetPassword(context),
    );
  }

  Widget? _missingAccountContent(BuildContext context) {
    if (!member.isActive) return null;
    if (member.dni == null) {
      return const _AccountCardBody(
        title: AppStrings.memberAccountNone,
        subtitle: AppStrings.memberAccountNeedsDni,
      );
    }

    return _AccountCardBody(
      title: AppStrings.memberAccountNone,
      actionLabel: AppStrings.memberAccountCreateAction,
      onAction: () => _create(context),
    );
  }
}

class _AccountCardFrame extends StatelessWidget {
  final Widget child;

  const _AccountCardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}

class _AccountCardBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AccountCardBody({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: _AccountHeading(title: title, subtitle: subtitle),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(label: label, onPressed: onAction),
        ],
      ],
    );
  }
}

class _AccountHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _AccountHeading({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final detail = subtitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AccountIcon(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  AppStrings.memberAccountSectionLabel.toUpperCase(),
                  style: AppTextStyles.sectionLabel,
                ),
              ),
              Text(title, style: AppTextStyles.labelLarge),
              if (detail != null) Text(detail, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.infoSurface,
      child: Icon(Icons.smartphone_outlined, color: AppColors.textPrimary),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.memberAccountLoading,
      child: const Row(
        children: [
          _AccountIcon(),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 120),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(height: 16, width: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
