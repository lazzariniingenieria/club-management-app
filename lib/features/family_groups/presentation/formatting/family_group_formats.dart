import '../../../../core/constants/app_strings.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/family_group.dart';

abstract final class FamilyGroupFormats {
  static String displayName(FamilyGroup? group) {
    if (group == null || !group.hasName) {
      return AppStrings.familyGroupFallbackName;
    }

    return group.name!.trim();
  }

  static String relatives(List<Member> others) {
    final names = others.map((member) => member.fullName).toList();

    return switch (names.length) {
      0 => AppStrings.familyGroupMemberCount(1),
      1 => AppStrings.familyGroupWithOne(names[0]),
      2 => AppStrings.familyGroupWithTwo(names[0], names[1]),
      _ => AppStrings.familyGroupWithMore(names[0], names[1], names.length - 2),
    };
  }

  static String defaultName(Member member) =>
      AppStrings.familyGroupDefaultName(member.lastName);

  static String namesList(List<Member> members) {
    final names = members.map((member) => member.fullName).toList();
    if (names.length <= 1) return names.join();

    final head = names.sublist(0, names.length - 1).join(', ');

    return AppStrings.listed(head, names.last);
  }

  static String namesInLines(List<Member> members) =>
      members.map((member) => member.fullName).join('\n');
}
