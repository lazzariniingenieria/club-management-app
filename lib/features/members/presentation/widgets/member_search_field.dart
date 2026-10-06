import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class MemberSearchField extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const MemberSearchField({
    super.key,
    required this.query,
    required this.onChanged,
  });

  @override
  State<MemberSearchField> createState() => _MemberSearchFieldState();
}

class _MemberSearchFieldState extends State<MemberSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(MemberSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) _controller.text = widget.query;
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
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: const InputDecoration(
        hintText: AppStrings.adminPaymentsSearchHint,
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
      ),
    );
  }
}
