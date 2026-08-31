abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  static const String adminHome = '/admin';
  static const String adminReservations = '/admin/reservations';
  static const String adminPayments = '/admin/payments';
  static const String adminProfile = '/admin/profile';
  static const String adminMembers = '/admin/members';
  static const String adminCourts = '/admin/courts';
  static const String adminAdmins = '/admin/admins';

  static const String memberSurfacePending = '/member';

  static const String devGallery = '/dev/gallery';

  static bool isAuthRoute(String location) => location == login;

  static bool isAdminSurface(String location) => location.startsWith(adminHome);

  static bool isDevRoute(String location) => location.startsWith('/dev');
}
