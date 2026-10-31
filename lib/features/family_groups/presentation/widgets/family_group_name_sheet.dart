import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../domain/entities/family_group.dart';

typedef FamilyGroupRename = Future<Failure?> Function(String name);

class FamilyGroupNameSheet extends StatefulWidget {
  final String initialName;
  final FamilyGroupRename onSave;

  const FamilyGroupNameSheet({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  static Future<bool> show(BuildContext context, FamilyGroupNameSheet sheet) {
    return showAppSheet<bool>(context, (_) => sheet)
        .then((saved) => saved ?? false);
  }

  @override
  State<FamilyGroupNameSheet> createState() => _FamilyGroupNameSheetState();
}

class _FamilyGroupNameSheetState extends State<FamilyGroupNameSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  bool _isSaving = false;
  Failure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final failure = await widget.onSave(_name.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: AppStrings.familyGroupNameSheetTitle,
      children: [
        if (_failure != null) ...[
          _SaveFailureNotice(failure: _failure!),
          const SizedBox(height: AppSpacing.lg),
        ],
        TextField(
          controller: _name,
          autofocus: true,
          enabled: !_isSaving,
          maxLength: FamilyGroup.nameMaxLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: AppStrings.familyGroupNameSheetLabel,
            helperText: AppStrings.familyGroupNameSheetHelp,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          text: _failure == null
              ? AppStrings.familyGroupNameSave
              : AppStrings.retryAction,
          isLoading: _isSaving,
          onPressed: _save,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: AppStrings.cancelAction,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _SaveFailureNotice extends StatelessWidget {
  final Failure failure;

  const _SaveFailureNotice({required this.failure});

  @override
  Widget build(BuildContext context) {
    final isOffline = failure is NetworkFailure;

    return AppNotice(
      tone: AppNoticeTone.danger,
      title: isOffline ? null : AppStrings.familyGroupServerTitle,
      message: isOffline
          ? AppStrings.familyGroupOfflineAction
          : AppStrings.familyGroupServerMessage,
    );
  }
}
