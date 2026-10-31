import '../../features/members/domain/entities/member_collection_filter.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String loginForgotPassword = '/login/forgot';

  static const String adminHome = '/admin';
  static const String adminMembers = '/admin/members';
  static const String adminProfile = '/admin/profile';
  static const String adminCourts = '/admin/courts';
  static const String adminAdmins = '/admin/admins';
  static const String adminAdminCreation = '/admin/admins/new';
  static const String adminAdminEditionPattern = '/admin/admins/:adminId/edit';

  static const String adminMemberCreation = '/admin/members/new';
  static const String adminMemberEditionPattern =
      '/admin/members/:memberId/edit';
  static const String adminMemberLedgerPattern =
      '/admin/members/:memberId/payments';
  static const String adminPaymentRegistrationPattern =
      '/admin/members/:memberId/payments/new';
  static const String adminPaymentMemberPicker = '/admin/payments/new';
  static const String adminPaymentReport = '/admin/payments/report';
  static const String adminFamilyGroupCreationPattern =
      '/admin/members/:memberId/family-group/new';
  static const String adminFamilyGroupPattern =
      '/admin/family-groups/:familyGroupId';
  static const String adminFamilyGroupMemberPickerPattern =
      '/admin/family-groups/:familyGroupId/add';

  static const String memberIdPathParameter = 'memberId';
  static const String familyGroupIdPathParameter = 'familyGroupId';

  static const String memberSurfacePending = '/member';

  static const String devGallery = '/dev/gallery';

  static const String filterQueryParameter = 'filter';
  static const String viewQueryParameter = 'view';
  static const String familyGroupsView = 'groups';
  static const String forFamilyQueryParameter = 'family';

  static const String adminFamilyGroups =
      '$adminMembers?$viewQueryParameter=$familyGroupsView';

  static String adminMembersWithFilter(MemberCollectionFilter filter) =>
      '$adminMembers?$filterQueryParameter=${filter.queryValue}';

  static String adminMemberEdition(int memberId) =>
      '/admin/members/$memberId/edit';

  static String adminMemberLedger(int memberId) =>
      '/admin/members/$memberId/payments';

  static String adminPaymentRegistration(int memberId) =>
      '${adminMemberLedger(memberId)}/new';

  static String adminFamilyPaymentRegistration(int memberId) =>
      '${adminPaymentRegistration(memberId)}?$forFamilyQueryParameter=true';

  static String adminAdminEdition(int adminId) =>
      '/admin/admins/$adminId/edit';

  static String adminFamilyGroupCreation(int memberId) =>
      '/admin/members/$memberId/family-group/new';

  static String adminFamilyGroup(int familyGroupId) =>
      '/admin/family-groups/$familyGroupId';

  static String adminFamilyGroupMemberPicker(int familyGroupId) =>
      '${adminFamilyGroup(familyGroupId)}/add';

  static bool isAuthRoute(String location) =>
      location == login || location == loginForgotPassword;

  static bool isAdminSurface(String location) => location.startsWith(adminHome);

  static bool isDevRoute(String location) => location.startsWith('/dev');
}
