import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDestructive = false,
  });

  static Future<bool> show(BuildContext context, ConfirmationDialog dialog) {
    return showDialog<bool>(context: context, builder: (_) => dialog)
        .then((confirmed) => confirmed ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: AppColors.dangerText)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
