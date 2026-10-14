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
  static const String adminHomeNewMemberAccess = 'Nuevo socio';
  static const String adminHomeRegisterPaymentAccess = 'Registrar pago';

  static const String adminPaymentsTitle = 'Pagos';
  static const String adminPaymentsSearchHint =
      'Buscar socio por nombre o DNI...';
  static const String adminPaymentsFilterAll = 'Todos';
  static const String adminPaymentsFilterOverdue = 'En mora';
  static const String adminPaymentsErrorTitle =
      'No pudimos cargar el listado de socios';
  static const String adminPaymentsEmptyRoster =
      'Todavía no hay socios cargados en el club.';
  static const String adminPaymentsEmptyOverdue =
      'Ningún socio está en mora. Todas las cuotas están al día.';
  static const String adminPaymentsEmptySearch =
      'Ningún socio coincide con la búsqueda.';
  static const String adminPaymentsClearSearch = 'Limpiar búsqueda';
  static const String adminPaymentsCreateMember = 'Crear socio';

  static const String memberStatusActive = 'Activo';
  static const String memberStatusInactive = 'Inactivo';
  static const String memberEditAction = 'Editar socio';

  static const String memberFormCreateTitle = 'Nuevo socio';
  static const String memberFormEditTitle = 'Editar socio';
  static const String memberFormFirstName = 'Nombre';
  static const String memberFormLastName = 'Apellido';
  static const String memberFormDni = 'DNI';
  static const String memberFormPhone = 'Teléfono (opcional)';
  static const String memberFormEmail = 'Email (opcional)';
  static const String memberFormRequiredField = 'Este dato es obligatorio';
  static const String memberFormTooLong = 'Es demasiado largo';
  static const String memberFormDniOnlyDigits = 'El DNI solo lleva números';
  static const String memberFormMalformedEmail =
      'Revisá el email: le falta el @ o el dominio';
  static const String memberFormDniTaken =
      'Ya hay un socio con este DNI en el club';
  static const String memberFormSaveCreation = 'Crear socio';
  static const String memberFormSaveEdition = 'Guardar cambios';
  static const String memberFormCreated = 'Socio creado';
  static const String memberFormUpdated = 'Cambios guardados';
  static const String memberFormDiscardTitle = '¿Descartar los cambios?';
  static const String memberFormDiscardMessage =
      'Lo que cargaste en el formulario no se va a guardar.';
  static const String memberFormDiscardAction = 'Descartar';
  static const String memberFormKeepEditingAction = 'Seguir editando';

  static const String memberDeactivateAction = 'Dar de baja';
  static const String memberReactivateAction = 'Reactivar socio';
  static const String memberDeactivated = 'Socio dado de baja';
  static const String memberReactivated = 'Socio reactivado';
  static const String memberDeactivateConfirmMessage =
      'Deja de contar como socio activo y su cuota deja de figurar. Podés reactivarlo cuando quieras.';
  static const String memberReactivateConfirmMessage =
      'Vuelve a contar como socio activo y su cuota vuelve a figurar.';

  static String memberDeactivateConfirmTitle(String fullName) =>
      '¿Dar de baja a $fullName?';

  static String memberReactivateConfirmTitle(String fullName) =>
      '¿Reactivar a $fullName?';

  static const String comingSoonRegisterPayment =
      'El registro de pagos se habilita en una próxima entrega.';

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
