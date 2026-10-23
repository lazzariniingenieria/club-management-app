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
  static const String forgotPasswordTitle = '¿Olvidaste tu contraseña?';
  static const String forgotPasswordNoEmail =
      'La app no puede enviarte una contraseña nueva por email.';
  static const String forgotPasswordAskAdmin =
      'Pedile al administrador principal del club que te asigne una contraseña nueva. Después podés cambiarla desde tu Perfil.';
  static const String forgotPasswordMainAccount =
      'Si sos el administrador principal, comunicate con quien mantiene el sistema del club.';
  static const String forgotPasswordBack = 'Volver al ingreso';
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

  static String listed(String head, String last) => '$head y $last';

  static String monthsListed(String head, String last) => listed(head, last);

  static String monthsRange(int count, String from, String to) =>
      '$count meses, de $from a $to';

  static String monthsSpread(int count, String from, String to) =>
      '$count meses, entre $from y $to';

  static const String familyGroupSectionLabel = 'Grupo familiar';
  static const String familyGroupNone = 'Sin grupo familiar';
  static const String familyGroupNoneHint =
      'Armalo si un familiar le paga la cuota.';
  static const String familyGroupBuildAction = 'Armar grupo familiar';
  static const String familyGroupFallbackName = 'Grupo familiar';
  static const String familyGroupOpenHint = 'Ver grupo';

  static String familyGroupWithOne(String name) => 'Con $name';

  static String familyGroupWithTwo(String first, String second) =>
      'Con $first y $second';

  static String familyGroupWithThree(
    String first,
    String second,
    String third,
  ) =>
      'Con $first, $second y $third';

  static String familyGroupWithMore(String first, String second, int more) =>
      'Con $first, $second y $more más';

  static String familyGroupMemberCount(int count) =>
      count == 1 ? '1 integrante' : '$count integrantes';

  static String familyGroupDefaultName(String lastName) => 'Familia $lastName';

  static const String familyGroupPickerBuildTitle = 'Armar grupo familiar';
  static const String familyGroupPickerAddTitle = 'Sumar al grupo';
  static const String familyGroupPickerHint =
      'Solo socios activos. Si alguno ya está en otro grupo, lo vas a ver indicado.';
  static const String familyGroupPickerOthers = 'OTROS SOCIOS';
  static const String familyGroupPickerEmptyHint =
      'Revisá cómo se escribe o buscá por DNI. Un socio dado de baja hay que reactivarlo antes de sumarlo.';
  static const String familyGroupPickerNoCandidates =
      'No hay otros socios activos para sumar.';
  static const String familyGroupPickerErrorTitle =
      'No pudimos cargar los socios';

  static String familyGroupPickerBuildPrompt(String memberName) =>
      '¿Con quién arma el grupo $memberName?';

  static String familyGroupPickerAddPrompt(String groupName) =>
      '¿A quién sumás a $groupName?';

  static String familyGroupPickerSameSurname(int count) =>
      'MISMO APELLIDO · $count';

  static String familyGroupMembershipChip(String groupName) => 'En $groupName';

  static String familyGroupPickerEmpty(String query) =>
      'No encontramos socios activos con «$query»';

  static const String familyGroupConfirmBuildTitle = 'Armar el grupo familiar';
  static const String familyGroupRowMembers = 'Integrantes';
  static const String familyGroupRowGroup = 'Grupo';
  static const String familyGroupRowCurrentMembers = 'Integrantes hoy';
  static const String familyGroupRowJoining = 'Se suma';
  static const String familyGroupRowAlreadyIn = 'Ya está';
  static const String familyGroupRowMissing = 'Falta sumar';
  static const String familyGroupNameLabel = 'Nombre del grupo (opcional)';
  static const String familyGroupNameHelp = 'Podés dejarlo vacío.';
  static const String familyGroupIndividualFeePair =
      'Cada uno sigue pagando su propia cuota. Lo que cambia: cualquiera de los dos puede pagar la del otro.';
  static const String familyGroupIndividualFeeGroup =
      'Cada uno sigue pagando su propia cuota. Lo que cambia: cualquiera del grupo puede pagar la de otro.';
  static const String familyGroupBuildConfirm = 'Armar grupo';
  static const String familyGroupJoinConfirm = 'Sumar al grupo';
  static const String familyGroupOfflineTitle = 'Sin conexión.';
  static const String familyGroupBuildOffline =
      'No se armó el grupo. Revisá la conexión y probá de nuevo: lo que cargaste queda igual.';
  static const String familyGroupServerTitle = 'No pudimos guardar el cambio.';
  static const String familyGroupServerMessage =
      'El sistema del club tuvo un problema. Probá de nuevo en unos minutos.';
  static const String familyGroupPartialTitle = 'Falta un paso.';
  static const String familyGroupUnconfirmedTitle =
      'No sabemos si el grupo se creó.';
  static const String familyGroupUnconfirmedMessage =
      'El sistema del club no respondió a tiempo. Si reintentás, puede quedar un grupo vacío sin usar, que no afecta a nadie.';

  static String familyGroupConfirmJoinTitle(String member, String group) =>
      '¿Sumar a $member a $group?';

  static String familyGroupBuilt(String relative) =>
      'Grupo familiar armado con $relative';

  static String familyGroupJoined(String member, String group) =>
      '$member se sumó a $group';

  static String familyGroupBuildPartial(String names) =>
      'El grupo se creó, pero no pudimos sumar a $names. Reintentá para terminar: no se crea otro grupo.';

  static const String familyGroupScreenTitle = 'Grupo familiar';
  static const String familyGroupEditNameAction = 'Editar nombre del grupo';
  static const String familyGroupNote =
      'Cada integrante paga su propia cuota. Al registrar un pago, cualquiera del grupo puede figurar como quien pagó.';
  static const String familyGroupSingleMemberNote =
      'Este grupo tiene un solo integrante. Sumá a un familiar para que puedan pagarse la cuota entre ellos.';
  static const String familyGroupEmptyTitle = 'Este grupo no tiene integrantes';
  static const String familyGroupEmptyHint = 'Sumá a los socios de la familia.';
  static const String familyGroupAddAction = 'Sumar integrante';
  static const String familyGroupRemoveTooltip = 'Quitar del grupo';
  static const String familyGroupDeleteAction = 'Eliminar grupo';
  static const String familyGroupDeleteUnavailable =
      'Eliminar un grupo todavía no está disponible. Mientras tanto, podés quitar a cada integrante.';
  static const String familyGroupLoadOfflineMessage =
      'No pudimos cargar el grupo familiar. Revisá la conexión y probá de nuevo.';
  static const String familyGroupLoadServerTitle = 'No pudimos cargar el grupo';
  static const String familyGroupMissingTitle = 'No encontramos este grupo';
  static const String familyGroupMissingMessage =
      'Puede que lo hayan eliminado. Volvé para ver los datos actualizados.';
  static const String familyGroupOfflineAction =
      'Sin conexión. No se guardó el cambio: revisá la conexión y probá de nuevo.';

  static String familyGroupMembersSection(int count) => 'INTEGRANTES · $count';

  static String familyGroupRemoveSemantics(String member) =>
      'Quitar a $member del grupo';

  static String familyGroupMemberAdded(String member) =>
      '$member se sumó al grupo';

  static String familyGroupMemberRemoved(String member) =>
      '$member ya no está en el grupo';

  static const String familyGroupNameSheetTitle = 'Nombre del grupo';
  static const String familyGroupNameSheetLabel = 'Nombre (opcional)';
  static const String familyGroupNameSheetHelp =
      'Si lo dejás vacío, se muestra como «Grupo familiar».';
  static const String familyGroupNameSave = 'Guardar';
  static const String familyGroupNameSaved = 'Nombre del grupo actualizado';

  static const String familyGroupMoveConfirm = 'Pasar de grupo';
  static const String familyGroupRemoveMessage =
      'Sigue siendo socio y sus pagos no cambian. Vas a poder volver a sumarlo cuando quieras.';
  static const String familyGroupRemoveConfirm = 'Quitar';

  static String familyGroupMoveTitle(String member, String group) =>
      '¿Pasar a $member a $group?';

  static String familyGroupMoveMessage(String currentGroup) =>
      'Hoy está en $currentGroup y va a dejar ese grupo. Sus pagos no cambian.';

  static String familyGroupRemoveTitle(String member) =>
      '¿Quitar a $member del grupo?';

  static const String reportTitle = 'Reporte de cuotas cobradas';
  static const String reportPeriodQuestion = '¿De qué período?';
  static const String reportModeSingle = 'Un mes';
  static const String reportModeRange = 'Varios meses';
  static const String reportMonthLabel = 'Mes';
  static const String reportFromLabel = 'Desde';
  static const String reportToLabel = 'Hasta';
  static const String reportScopeNote =
      'Arma las tabletas para imprimir y recortar: una por grupo familiar y mes cubierto (o por socio, si no tiene grupo), con lo cobrado en el período por fecha de cobro. No incluye pagos anulados.';
  static const String reportInvalidRange =
      'El mes «Desde» tiene que ser anterior o igual a «Hasta».';
  static const String reportGenerate = 'Generar PDF';
  static const String reportGenerating = 'Generando el PDF…';
  static const String reportReadyTitle = 'Tabletas listas';
  static const String reportReadyHint =
      'Cada tableta sale dos veces, lado a lado, con líneas de corte.';
  static const String reportShare = 'Compartir PDF';
  static const String reportPreview = 'Ver o imprimir';
  static const String reportEmpty =
      'No hubo cobros en ese período, así que no hay tabletas para imprimir.';
  static const String reportOfflineTitle = 'Sin conexión.';
  static const String reportOffline =
      'No pudimos generar el PDF. Revisá la conexión y probá de nuevo.';
  static const String reportServerTitle = 'No pudimos generar el PDF.';
  static const String reportServer =
      'El sistema del club tuvo un problema. Probá de nuevo en unos minutos.';
  static const String reportExportFailed =
      'No pudimos abrir el PDF en este dispositivo. Probá de nuevo.';

  static String reportPeriodRange(String from, String to) => 'De $from a $to';

  static const String adminCourtsTitle = 'Canchas';
  static const String adminCourtsPending =
      'La gestión de canchas se habilita junto con la agenda de reservas.';

  static const String adminAdminsTitle = 'Administradores';
  static const String adminsNew = 'Nuevo administrador';
  static const String adminsEmptyTitle = 'Todavía no hay administradores';
  static const String adminsEmptyHint =
      'Sumá a quienes cobran las cuotas: cada uno entra con su DNI y la contraseña que le asignes.';
  static const String adminsErrorTitle =
      'No pudimos cargar los administradores';
  static const String adminRowNoEmail = 'Sin email';
  static const String adminReactivateShort = 'Reactivar';
  static const String adminFormCreateTitle = 'Nuevo administrador';
  static const String adminFormEditTitle = 'Editar administrador';
  static const String adminFormDni = 'DNI';
  static const String adminFormEmail = 'Email (opcional)';
  static const String adminFormPassword = 'Contraseña inicial';
  static const String adminFormPasswordHelp =
      'Entre 8 y 100 caracteres. Pasásela a la persona por un canal seguro.';
  static const String adminFormMember = 'Socio vinculado (opcional)';
  static const String adminFormNoMember = 'Sin vincular';
  static const String adminFormMemberHelp =
      'Si además es socio del club, vinculalo para que figure con su nombre.';
  static const String adminFormCreate = 'Crear administrador';
  static const String adminFormSave = 'Guardar cambios';
  static const String adminFormCreated = 'Administrador creado';
  static const String adminFormUpdated = 'Cambios guardados';
  static const String adminFormConflict =
      'Ese DNI o ese socio ya los usa otra cuenta del club. Revisá los datos.';
  static const String adminResetPassword = 'Restablecer contraseña';
  static const String adminResetPasswordNotice =
      'Sus sesiones abiertas se cierran. Pasale la contraseña nueva por un canal seguro.';
  static const String adminResetPasswordDone = 'Contraseña restablecida';
  static const String adminDeactivate = 'Dar de baja';
  static const String adminReactivate = 'Reactivar administrador';
  static const String adminDeactivateMessage =
      'No va a poder ingresar a la app. Vas a poder reactivarlo cuando quieras.';
  static const String adminReactivateMessage =
      'Va a poder volver a ingresar con su DNI y su contraseña.';
  static const String adminDeactivated = 'Administrador dado de baja';
  static const String adminReactivated = 'Administrador reactivado';

  static String adminDeactivateTitle(String name) => '¿Dar de baja a $name?';

  static String adminReactivateTitle(String name) => '¿Reactivar a $name?';

  static const String adminProfileTitle = 'Perfil';
  static const String adminProfilePending =
      'Los datos de la cuenta y el cambio de contraseña se habilitan en una próxima entrega.';
  static const String adminProfileManageAdmins = 'Administradores';
  static const String profileAccountSection = 'Tu cuenta';
  static const String profileRoleAdmin = 'Administrador';
  static const String profileRoleSuperAdmin = 'Administrador principal';
  static const String profileNotLinked =
      'Esta cuenta no está vinculada a un socio.';
  static const String profileClubSection = 'Club';
  static const String profileMonthlyFeeLabel = 'Cuota mensual de referencia';
  static const String profileMonthlyFeeUnset = 'Sin cargar';
  static const String profileMonthlyFeeHelp =
      'Es el importe que aparece precargado al registrar un pago. Cambiarla no modifica pagos ya registrados.';
  static const String profileMonthlyFeeReadOnly =
      'Solo el administrador principal puede cambiarla.';
  static const String profileEditMonthlyFee = 'Editar cuota mensual';
  static const String profileClubOffline =
      'Sin conexión: no pudimos cargar los datos del club.';
  static const String profileClubFailed =
      'No pudimos cargar los datos del club.';
  static const String profileSecuritySection = 'Sesión y seguridad';
  static const String profileChangePassword = 'Cambiar contraseña';
  static const String profileChangePasswordUnavailable =
      'La contraseña de la cuenta principal todavía no se puede cambiar desde la app.';

  static String profileLinkedMember(String name) => 'Socio: $name';

  static const String passwordSheetTitle = 'Cambiar contraseña';
  static const String passwordNewLabel = 'Contraseña nueva';
  static const String passwordHelp = 'Entre 8 y 100 caracteres.';
  static const String passwordTooShort =
      'Tiene que tener al menos 8 caracteres';
  static const String passwordTooLong = 'Puede tener hasta 100 caracteres';
  static const String passwordChangeNotice =
      'Al cambiarla se cierran tus sesiones abiertas y vas a ingresar de nuevo con la nueva.';
  static const String passwordChangeAction = 'Cambiar contraseña';
  static const String passwordChangedTitle = 'Contraseña cambiada';
  static const String passwordChangedMessage =
      'Ingresá de nuevo con la contraseña nueva.';
  static const String passwordChangedAction = 'Ir al ingreso';

  static const String feeSheetTitle = 'Cuota mensual de referencia';
  static const String feeSheetLabel = 'Cuota mensual';
  static const String feeSheetHelp =
      'Dejalo vacío si el club no tiene una cuota fija: el importe va a arrancar vacío al registrar un pago.';
  static const String feeSaved = 'Cuota de referencia actualizada';
  static const String saveAction = 'Guardar';
  static const String saveFailedOffline =
      'Sin conexión. No se guardó el cambio: revisá la conexión y probá de nuevo.';
  static const String saveFailedServer =
      'No pudimos guardar el cambio. El sistema del club tuvo un problema: probá de nuevo en unos minutos.';

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
