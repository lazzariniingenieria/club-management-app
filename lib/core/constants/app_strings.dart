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
  static const String memberOpenLedgerHint = 'Ver cuotas';

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

  static const List<String> monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const List<String> monthAbbreviations = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static const String paymentMethodCash = 'Efectivo';
  static const String paymentMethodTransfer = 'Transferencia';
  static const String paymentMethodOther = 'Otro';

  static const String memberUpToDateBadge = 'Al día';

  static String memberDni(String dni) => 'DNI $dni';

  static String daysOverdueBadge(int days) =>
      days == 1 ? '1 día de mora' : '$days días de mora';

  static const String paymentPickerTitle = 'Registrar pago';
  static const String paymentPickerQuestion =
      '¿A qué socio le registrás el pago?';
  static const String paymentPickerSearchHint = 'Buscar por nombre o DNI';
  static const String paymentPickerNoMembers =
      'Todavía no hay socios activos en el club.';

  static String paymentPickerOverdueSection(int count) =>
      'DEBEN CUOTA · $count';

  static String paymentPickerUpToDateSection(int count) => 'AL DÍA · $count';

  static const String ledgerTitle = 'Cuotas';
  static const String ledgerUpToDate = 'Cuota al día';
  static const String ledgerInactive = 'Socio inactivo';
  static const String ledgerNeverPaid = 'Todavía no tiene pagos';
  static const String ledgerInactiveNote =
      'Mientras esté dado de baja, su cuota no cuenta para la mora ni para los contadores del Inicio.';
  static const String ledgerHistoryTitle = 'Historial de pagos';
  static const String ledgerHistoryHint =
      'Tocá un pago para ver el detalle o anularlo.';
  static const String ledgerEmptyTitle = 'Sin pagos registrados';
  static const String ledgerEmptyMessage =
      'Cuando registres su primer pago va a aparecer acá, del mes más reciente al más viejo.';
  static const String ledgerRegisterAction = 'Registrar pago';
  static const String ledgerRegisterFirstAction = 'Registrar primer pago';
  static const String ledgerInactiveHint =
      'Para registrarle pagos, primero reactivalo desde «Editar socio».';
  static const String ledgerOfflineTitle = 'Sin conexión';
  static const String ledgerOfflineMessage =
      'No pudimos cargar las cuotas de este socio. Revisá la conexión y probá de nuevo.';
  static const String ledgerServerErrorTitle = 'No pudimos cargar las cuotas';
  static const String ledgerServerErrorMessage =
      'El sistema del club tuvo un problema. No es tu conexión: probá de nuevo en unos minutos.';
  static const String ledgerMissingTitle = 'No encontramos a este socio';
  static const String ledgerMissingMessage =
      'Ya no figura en el padrón del club. No se registró ningún pago. Volvé al listado para ver los datos actualizados.';
  static const String ledgerMissingAction = 'Volver a Pagos';
  static const String ledgerNewTag = 'NUEVO';

  static String ledgerLastPaid(String month) => 'Último mes pago: $month';

  static String ledgerOverdueSinceLastPaid(String month) =>
      'Cuenta desde el 1° de $month, el mes que sigue al último pago.';

  static String ledgerOverdueSinceJoining(String month) =>
      'Cuenta desde el 1° de $month, el mes en que se dio de alta.';

  static String ledgerNewMemberNote(String joinedOn, String month) =>
      'Es normal en un socio nuevo: la cuota corre desde el 1° del mes en que se dio de alta ($joinedOn). Registrá la cuota de $month para dejarlo al día.';

  static String ledgerRegisterMonthAction(String month) =>
      'Registrar cuota de $month';

  static const String paymentPaidByUnknownRelative =
      'otro integrante del grupo familiar';
  static const String paymentVoidedTag = 'ANULADO';
  static const String paymentVoidNoReason = 'Sin motivo';

  static String paymentMethodAndDay(String method, String day) =>
      '$method · cargado el $day';

  static String paymentPaidBy(String payer) => 'Pagó $payer';

  static String paymentPayerMember(String name) => '$name (socio)';

  static String paymentPayerRelative(String name) => '$name (familiar)';

  static String paymentVoidedOn(String day) => 'Anulado el $day';

  static String paymentVoidReason(String reason) => 'Motivo: $reason';

  static String paymentRowSemantics(String month, String amount) =>
      'Pago de $month, $amount. Ver detalle';

  static const String paymentDetailAmount = 'Importe';
  static const String paymentDetailMethod = 'Medio';
  static const String paymentDetailPayer = 'Pagó';
  static const String paymentDetailRecordedOn = 'Cargado el';
  static const String paymentDetailVoidAction = 'Anular este pago';
  static const String closeAction = 'Cerrar';

  static String paymentDetailTitle(String month) => 'Pago de $month';

  static const String voidPaymentEffect =
      'Ese mes vuelve a figurar impago y la mora se recalcula. La anulación queda registrada y no se puede revertir: si fue un error, vas a tener que cargar el pago de nuevo.';
  static const String voidPaymentReasonLabel = 'Motivo (opcional)';
  static const String voidPaymentReasonHint =
      'Ej.: se cargó en el socio equivocado';
  static const String voidPaymentConfirmAction = 'Anular pago';
  static const String voidPaymentAlreadyVoided =
      'Otro administrador ya había anulado este pago. Actualizamos el historial.';

  static String voidPaymentTitle(String month) => '¿Anular el pago de $month?';

  static String voidPaymentDone(String month) =>
      'Pago de $month anulado. La mora se recalculó.';

  static const String registerPaymentTitle = 'Registrar pago';
  static const String registerPaymentMonthsTitle = '¿Qué meses paga?';
  static const String registerPaymentPreviousYear = 'Año anterior';
  static const String registerPaymentNextYear = 'Año siguiente';
  static const String registerPaymentMonthPaid = 'Pagado';
  static const String registerPaymentMonthChosen = 'Elegido';
  static const String registerPaymentAmountLabel = 'Importe por mes';
  static const String registerPaymentAmountWithoutFee =
      'El club todavía no tiene una cuota cargada: escribí el importe. Se registra por cada mes elegido.';
  static const String registerPaymentTotalLabel = 'Total';
  static const String registerPaymentMethodTitle = 'Medio de pago';
  static const String registerPaymentPayerTitle = '¿Quién pagó?';
  static const String registerPaymentPayerHelp =
      'Puede ser el socio o alguien de su grupo familiar.';
  static const String registerPaymentPayerSelf = 'El socio';
  static const String registerPaymentPayerRelative = 'Grupo familiar';
  static const String registerPaymentNoMonths = 'Ningún mes elegido';
  static const String registerPaymentIncomplete =
      'Falta elegir al menos un mes y el importe.';
  static const String registerPaymentReviewAction = 'Revisar y confirmar';
  static const String registerPaymentOfflineTitle = 'Sin conexión.';
  static const String registerPaymentOfflineMessage =
      'El pago no se registró. Tus datos siguen cargados: cuando vuelva la señal, tocá «Reintentar».';
  static const String registerPaymentUnconfirmedTitle =
      'No sabemos si el pago se registró.';
  static const String registerPaymentUnconfirmedMessage =
      'El servidor no respondió a tiempo y el pago puede estar registrándose todavía. Tus datos siguen cargados: al reintentar revisamos el historial antes de enviar, así el pago no se carga dos veces.';
  static const String registerPaymentInactiveTitle =
      'Este socio está dado de baja';
  static const String registerPaymentPayerLeftGroup =
      'La persona elegida ya no está en el grupo familiar del socio, así que no puede figurar como quien pagó. Actualizamos la lista: elegí de nuevo.';
  static const String confirmPaymentTitle = 'Confirmá el pago';
  static const String confirmPaymentMember = 'Socio';
  static const String confirmPaymentMonths = 'Meses';
  static const String confirmPaymentAmount = 'Importe por mes';
  static const String confirmPaymentMethod = 'Medio';
  static const String confirmPaymentPayer = 'Pagó';
  static const String confirmPaymentNoticeTitle = 'Revisá antes de confirmar.';
  static const String confirmPaymentNotice =
      'Un pago registrado no se edita: si hay un error, hay que anularlo desde el historial del socio y cargarlo de nuevo.';
  static const String confirmPaymentBackAction = 'Volver a editar';

  static String monthCount(int count) => count == 1 ? '1 mes' : '$count meses';

  static String registerPaymentSuggestionAfterLastPaid(String month) =>
      'Sugerimos $month, el mes que sigue al último pago. Tocá otros meses para sumarlos o quitarlos.';

  static String registerPaymentSuggestionFromJoining(String month) =>
      'Sugerimos $month, el mes en que se dio de alta. Tocá otros meses para sumarlos o quitarlos.';

  static String registerPaymentAmountWithFee(String fee) =>
      'Viene con la cuota del club ($fee). Cambialo si este pago es distinto. Se registra por cada mes elegido.';

  static String registerPaymentAmountTimesMonths(
    String months,
    String amount,
  ) =>
      '$months × $amount';

  static String registerPaymentReviewWithTotal(String total) =>
      'Revisar y confirmar · $total';

  static String registerPaymentMonthsAlreadyPaid(String months) =>
      '$months ya figura pago: otro administrador lo cargó mientras completabas el formulario. Lo quitamos de la selección y actualizamos el total. Revisá antes de confirmar.';

  static String confirmPaymentTotal(String months) => 'Total · $months';

  static String confirmPaymentAction(String total) =>
      'Confirmar pago de $total';

  static String paymentRegistered(String months, String total) =>
      'Pago registrado: $months · $total';

  static String monthsInYear(String months, int year) => '$months de $year';

  static String monthsListed(String head, String last) => '$head y $last';

  static String monthsRange(int count, String from, String to) =>
      '$count meses, de $from a $to';

  static String monthsSpread(int count, String from, String to) =>
      '$count meses, entre $from y $to';

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
  static const String backAction = 'Volver';

  static String withCount(String label, int count) => '$label ($count)';
}
