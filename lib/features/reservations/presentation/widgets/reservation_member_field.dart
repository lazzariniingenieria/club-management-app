import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_sheet_frame.dart';
import '../../../members/domain/entities/member.dart';
import '../formatting/reservation_formats.dart';

class ReservationMemberField extends StatelessWidget {
  final List<Member> members;
  final Member? selected;
  final ValueChanged<Member> onSelected;

  const ReservationMemberField({
    super.key,
    required this.members,
    required this.selected,
    required this.onSelected,
  });

  List<Member> get _activeMembers =>
      members.where((member) => member.isActive).toList()
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  Future<void> _pick(BuildContext context) async {
    final choice = await showAppSheet<Member>(
      context,
      (_) => _MemberSheet(choices: _activeMembers),
    );
    if (choice != null) onSelected(choice);
  }

  @override
  Widget build(BuildContext context) {
    final member = selected;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: AppStrings.reservationFormMember,
            prefixIcon: Icon(Icons.person_search_outlined),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
          ),
          child: Text(
            member == null
                ? AppStrings.reservationFormMemberUnset
                : member.fullName,
            style: AppTextStyles.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _MemberSheet extends StatefulWidget {
  final List<Member> choices;

  const _MemberSheet({required this.choices});

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  String _query = '';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: TextField(
                autofocus: true,
                onChanged: (query) => setState(() => _query = query),
                decoration: const InputDecoration(
                  hintText: AppStrings.reservationFormMemberSearch,
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(child: _results(visible)),
          ],
        ),
      ),
    );
  }

  Widget _results(List<Member> visible) {
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          AppStrings.reservationFormMemberEmpty(_query.trim()),
          style: AppTextStyles.bodyLargeMuted,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(ReservationFormats.memberWithDni(visible[index])),
        onTap: () => Navigator.of(context).pop(visible[index]),
      ),
    );
  }
}
