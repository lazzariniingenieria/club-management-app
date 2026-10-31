import '../../../../core/constants/app_strings.dart';
import '../../../../shared/formatters/display_formats.dart';
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
      3 => AppStrings.familyGroupWithThree(names[0], names[1], names[2]),
      _ => AppStrings.familyGroupWithMore(names[0], names[1], names.length - 2),
    };
  }

  static String defaultName(Member member) =>
      AppStrings.familyGroupDefaultName(member.lastName);

  static String namesList(List<Member> members) =>
      DisplayFormats.listed([for (final member in members) member.fullName]);

  static String namesInLines(List<Member> members) =>
      members.map((member) => member.fullName).join('\n');
}
