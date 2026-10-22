import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../members/domain/entities/member.dart';
import '../../../payments/presentation/formatting/payment_formats.dart';

class LinkedMemberField extends StatelessWidget {
  final List<Member> members;
  final int? selectedMemberId;
  final ValueChanged<int?> onSelected;

  const LinkedMemberField({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
  });

  List<Member> get _choices {
    return members
        .where((member) => member.isActive || member.id == selectedMemberId)
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  static String _labelOf(Member member) =>
      '${member.fullName} · ${AppStrings.memberDni(PaymentFormats.dni(member.dni))}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => DropdownMenu<int?>(
            width: constraints.maxWidth,
            initialSelection: selectedMemberId,
            enableFilter: true,
            requestFocusOnTap: true,
            menuHeight: 320,
            label: const Text(AppStrings.adminFormMember),
            leadingIcon: const Icon(Icons.person_search_outlined),
            onSelected: onSelected,
            dropdownMenuEntries: [
              const DropdownMenuEntry<int?>(
                value: null,
                label: AppStrings.adminFormNoMember,
              ),
              for (final member in _choices)
                DropdownMenuEntry<int?>(
                  value: member.id,
                  label: _labelOf(member),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(AppStrings.adminFormMemberHelp, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
