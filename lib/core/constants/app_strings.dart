class AppStrings {
  AppStrings._();

  static const String loginWelcomeTitle = 'Bienvenido de nuevo';
  static const String loginWelcomeSubtitle =
      'Accede a tus reservas y gestión de socios';

  static const String loginDniHint = 'DNI';
  static const String loginPasswordHint = 'Contraseña';

  static const String loginDniRequired = 'Ingresá tu DNI';
  static const String loginPasswordRequired = 'La contraseña es requerida';

  static const String loginInvalidCredentials =
      'DNI o contraseña incorrectos. Verificá los datos e intentá de nuevo.';
  static const String loginInvalidData = 'Revisá los datos ingresados.';
  static const String loginNetworkError =
      'No pudimos conectarnos. Revisá tu conexión e intentá de nuevo.';
  static const String loginServerError =
      'Tuvimos un problema. Intentá de nuevo en unos minutos.';

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
  static const String adminHomeSummaryTitle = 'Resumen general';
  static const String adminHomeActiveMembers = 'Socios activos';
  static const String adminHomeOverdueMembers = 'Socios en mora';
  static const String adminHomeSummaryErrorTitle =
      'No pudimos cargar el resumen del club';
  static const String adminHomeQuickAccessTitle = 'Accesos rápidos';
  static const String adminHomeMembersAccess = 'Gestión de socios';
  static const String adminHomeCourtsAccess = 'Gestión de canchas';

  static const String adminPaymentsTitle = 'Pagos';
  static const String adminPaymentsSearchHint =
      'Buscar socio por nombre o DNI...';
  static const String adminPaymentsFilterAll = 'Todos';
  static const String adminPaymentsFilterOverdue = 'En mora';
  static const String adminPaymentsFilterToCollect = 'A cobrar';
  static const String adminPaymentsErrorTitle =
      'No pudimos cargar el listado de socios';
  static const String adminPaymentsEmptyRoster =
      'Todavía no hay socios cargados en el club.';
  static const String adminPaymentsEmptyOverdue =
      'Ningún socio está en mora. Todas las cuotas están al día.';
  static const String adminPaymentsEmptyToCollect =
      'Todavía no marcaste socios para el reporte. Usá el ícono de documento '
      'de cada fila para sumarlos.';
  static const String adminPaymentsEmptySearch =
      'Ningún socio coincide con la búsqueda.';
  static const String adminPaymentsClearSearch = 'Limpiar búsqueda';
  static const String adminPaymentsGenerateReport = 'Generar reporte';
  static const String adminPaymentsCreateMember = 'Crear socio';

  static const String memberStatusActive = 'Activo';
  static const String memberStatusInactive = 'Inactivo';
  static const String memberEditAction = 'Editar socio';
  static const String memberAddToReportAction = 'Agregar al reporte';
  static const String memberRemoveFromReportAction = 'Quitar del reporte';

  static const String comingSoonCreateMember =
      'El alta de socios se habilita en una próxima entrega.';
  static const String comingSoonEditMember =
      'La edición de socios se habilita en una próxima entrega.';
  static const String comingSoonGenerateReport =
      'La generación del reporte se habilita en una próxima entrega.';

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
  static const String retryAction = 'Reintentar';

  static String withCount(String label, int count) => '$label ($count)';
}
