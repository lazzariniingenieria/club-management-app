import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class AppSheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AppSheetFrame({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.titleLarge),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    showDragHandle: dismissible,
    builder: builder,
  );
}
