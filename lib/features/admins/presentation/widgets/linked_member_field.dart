import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/display_formats.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../../members/domain/entities/homonyms.dart';
import '../../../members/domain/entities/member.dart';

class LinkedMemberField extends StatelessWidget {
  final List<Member> members;
  final Set<int> takenMemberIds;
  final int? selectedMemberId;
  final ValueChanged<int?> onSelected;

  const LinkedMemberField({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
    this.takenMemberIds = const {},
  });

  List<Member> get _choices {
    return members
        .where((member) => member.isActive || member.id == selectedMemberId)
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  String get _selectedLabel {
    final homonyms = Homonyms.among(_choices);
    for (final member in members) {
      if (member.id == selectedMemberId) return _labelOf(member, homonyms);
    }

    return AppStrings.adminFormNoMember;
  }

  Future<void> _pick(BuildContext context) async {
    final choice = await showAppSheet<_LinkedMemberChoice>(
      context,
      (_) => _LinkedMemberSheet(
        choices: _choices,
        takenMemberIds: takenMemberIds,
        selectedMemberId: selectedMemberId,
      ),
    );
    if (choice != null) onSelected(choice.memberId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          child: InkWell(
            onTap: () => _pick(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: AppStrings.adminFormMember,
                prefixIcon: Icon(Icons.person_search_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down_rounded),
              ),
              child: Text(_selectedLabel, style: AppTextStyles.bodyLarge),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(AppStrings.adminFormMemberHelp, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

String _labelOf(Member member, Homonyms homonyms) => homonyms.includes(member)
    ? '${member.fullName} · ${AppStrings.memberDni(DisplayFormats.dni(member.dni))}'
    : member.fullName;

class _LinkedMemberChoice {
  final int? memberId;

  const _LinkedMemberChoice(this.memberId);
}

class _LinkedMemberSheet extends StatefulWidget {
  final List<Member> choices;
  final Set<int> takenMemberIds;
  final int? selectedMemberId;

  const _LinkedMemberSheet({
    required this.choices,
    required this.takenMemberIds,
    required this.selectedMemberId,
  });

  @override
  State<_LinkedMemberSheet> createState() => _LinkedMemberSheetState();
}

class _LinkedMemberSheetState extends State<_LinkedMemberSheet> {
  String _query = '';
  late final Homonyms _homonyms = Homonyms.among(widget.choices);

  List<Member> get _visible =>
      widget.choices.where((member) => member.matches(_query)).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(onSearch: (query) => setState(() => _query = query)),
            Expanded(child: _results(visible)),
          ],
        ),
      ),
    );
  }

  Widget _results(List<Member> visible) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: visible.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _noMemberOrEmpty(visible.isEmpty);

        final member = visible[index - 1];

        return _MemberChoiceTile(
          member: member,
          detail: _detailOf(member),
          isSelected: member.id == widget.selectedMemberId,
        );
      },
    );
  }

  _ChoiceDetail _detailOf(Member member) {
    if (widget.takenMemberIds.contains(member.id)) return _ChoiceDetail.taken;

    return _homonyms.includes(member) ? _ChoiceDetail.dni : _ChoiceDetail.none;
  }

  Widget _noMemberOrEmpty(bool isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NoMemberTile(isSelected: widget.selectedMemberId == null),
        if (isEmpty && _query.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              AppStrings.adminFormMemberEmpty(_query.trim()),
              style: AppTextStyles.bodyLargeMuted,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const _SheetHeader({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              AppStrings.adminFormMemberPickerTitle,
              style: AppTextStyles.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            autofocus: true,
            onChanged: onSearch,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: AppStrings.paymentPickerSearchHint,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMemberTile extends StatelessWidget {
  final bool isSelected;

  const _NoMemberTile({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      title: const Text(AppStrings.adminFormNoMember),
      selected: isSelected,
      trailing: isSelected ? const Icon(Icons.check_rounded) : null,
      onTap: () => Navigator.of(context).pop(const _LinkedMemberChoice(null)),
    );
  }
}

enum _ChoiceDetail { none, dni, taken }

class _MemberChoiceTile extends StatelessWidget {
  final Member member;
  final _ChoiceDetail detail;
  final bool isSelected;

  const _MemberChoiceTile({
    required this.member,
    required this.detail,
    required this.isSelected,
  });

  String? get _subtitle => switch (detail) {
        _ChoiceDetail.none => null,
        _ChoiceDetail.dni =>
          AppStrings.memberDni(DisplayFormats.dni(member.dni)),
        _ChoiceDetail.taken => AppStrings.adminFormMemberTaken,
      };

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      enabled: detail != _ChoiceDetail.taken,
      selected: isSelected,
      title: Text(member.fullName),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check_rounded) : null,
      onTap: () =>
          Navigator.of(context).pop(_LinkedMemberChoice(member.id)),
    );
  }
}
