class AppStrings {
  AppStrings._();

  static const String loginWelcomeTitle = 'Bienvenido de nuevo';
  static const String loginWelcomeSubtitle =
      'Accede a tus reservas y gestión de socios';

  static const String loginEmailHint = 'Correo electrónico';
  static const String loginPasswordHint = 'Contraseña';

  static const String loginEmailRequired = 'El correo es requerido';
  static const String loginEmailInvalidFormat = 'Formato de correo inválido';
  static const String loginPasswordRequired = 'La contraseña es requerida';
  static const String loginPasswordTooShort =
      'La contraseña debe tener al menos 6 caracteres';

  static const String loginSubmitButton = 'Ingresar';
  static const String loginForgotPassword = '¿Olvidaste tu contraseña?';
  static const String loginFirstTimeUser = 'Es mi primera vez aquí';
  static const String loginSessionExpiredTitle = 'Tu sesión venció';
  static const String loginSessionExpiredMessage =
      'Por seguridad cerramos la sesión. Ingresá de nuevo para continuar.';
  static const String loginSessionUnverifiedTitle =
      'No pudimos verificar tu sesión';
  static const String loginSessionUnverifiedMessage =
      'Revisá tu conexión e ingresá de nuevo.';

  static const String passwordShowAction = 'Mostrar contraseña';
  static const String passwordHideAction = 'Ocultar contraseña';

  static const String splashLoading = 'Preparando tu sesión…';

  static const String roleBadgeAdmin = 'ADMINISTRADOR';
  static const String roleBadgeSuperAdmin = 'SUPER ADMIN';

  static const String adminTabHome = 'Inicio';
  static const String adminTabPayments = 'Pagos';
  static const String adminTabProfile = 'Perfil';

  static const String comingSoonBadge = 'Próximamente';

  static const String adminHomeTitle = 'Inicio';
  static const String adminHomePending =
      'El resumen del club con socios activos, socios en mora y próximos turnos se habilita en la próxima entrega.';

  static const String adminPaymentsTitle = 'Pagos';
  static const String adminPaymentsPending =
      'El listado de cuotas, el filtro por estado y el registro de pagos se habilitan en una próxima entrega.';

  static const String adminMembersTitle = 'Socios';
  static const String adminMembersPending =
      'El listado de socios con búsqueda, filtros y alta se habilita en una próxima entrega.';

  static const String adminCourtsTitle = 'Canchas';
  static const String adminCourtsPending =
      'La gestión de canchas se habilita junto con la agenda de reservas.';

  static const String adminAdminsTitle = 'Administradores';
  static const String adminAdminsPending =
      'El alta, edición y baja de administradores se habilita en una próxima entrega.';

  static const String adminProfileTitle = 'Perfil';
  static const String adminProfilePending =
      'Los datos de la cuenta y el cambio de contraseña se habilitan en una próxima entrega.';
  static const String adminProfileManageAdmins = 'Gestionar administradores';

  static const String memberSurfacePendingTitle = 'En preparación';
  static const String memberSurfacePendingMessage =
      'La app para socios todavía está en preparación. Por ahora la usan los administradores del club.';

  static const String logoutAction = 'Cerrar sesión';
  static const String logoutConfirmTitle = '¿Cerrar sesión?';
  static const String logoutConfirmMessage =
      'Vas a volver a la pantalla de ingreso.';
  static const String cancelAction = 'Cancelar';
}
