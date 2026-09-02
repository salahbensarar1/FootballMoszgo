// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Futballedzés';

  @override
  String get login => 'Bejelentkezés';

  @override
  String get welcomeBack => 'Üdvözöljük újra';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Jelszó';

  @override
  String get loginButton => 'Bejelentkezés';

  @override
  String get adminManagement => 'Admin kezelés';

  @override
  String get createNewOrganization => 'Új szervezet létrehozása';

  @override
  String get adminScreen => 'Admin felület';

  @override
  String get coachScreen => 'Edző felület';

  @override
  String get receptionistScreen => 'Recepciós felület';

  @override
  String get dashboardOverview => 'Irányítópult áttekintés';

  @override
  String get manageUsers => 'Felhasználók kezelése';

  @override
  String get settings => 'Beállítások';

  @override
  String get logout => 'Kijelentkezés';

  @override
  String get coaches => 'Edzők';

  @override
  String get players => 'Játékosok';

  @override
  String get teams => 'Csapatok';

  @override
  String get attendances => 'Jelenléti ívek';

  @override
  String searchHint(String entity) {
    return '$entity keresése...';
  }

  @override
  String addEntity(String entity) {
    return '$entity hozzáadása';
  }

  @override
  String get edit => 'Szerkesztés';

  @override
  String get delete => 'Törlés';

  @override
  String get save => 'Mentés';

  @override
  String get cancel => 'Mégsem';

  @override
  String get add => 'Hozzáadás';

  @override
  String get playerInfo => 'Játékos adatok';

  @override
  String get payments => 'Fizetések';

  @override
  String get paymentProgress => 'Fizetési folyamat';

  @override
  String get viewDetails => 'Részletek megtekintése';

  @override
  String get sendReminder => 'Emlékeztető küldése';

  @override
  String get fullyPaid => 'Teljesen fizetve';

  @override
  String get partial => 'Részben fizetve';

  @override
  String get unpaid => 'Nem fizetve';

  @override
  String get notActive => 'Nem aktív';

  @override
  String get monthlyCollectionTrend => 'Havi beszedési trend';

  @override
  String get totalCollected => 'Összesen beszedve';

  @override
  String get outstanding => 'Függőben';

  @override
  String get paidPlayers => 'Fizető játékosok';

  @override
  String get thisMonth => 'Ez a hónap';

  @override
  String noEntitiesFound(String entity) {
    return 'Nincs $entity találat';
  }

  @override
  String addSomeEntities(String entity) {
    return 'Adj hozzá néhány $entity-t a kezdéshez';
  }

  @override
  String noResultsFor(String query) {
    return 'Nincs találat erre: \"$query\"';
  }

  @override
  String get tryAdjustingSearch =>
      'Próbálja módosítani a keresési feltételeket';

  @override
  String get confirmLogout => 'Biztosan ki szeretne jelentkezni?';

  @override
  String get teamName => 'Csapat neve';

  @override
  String get name => 'Név';

  @override
  String get roleDescription => 'Szerepkör leírása';

  @override
  String get coachesManagement => 'Edzők kezelése';

  @override
  String get manageTeamCoaches => 'Csapat edzőinek kezelése';

  @override
  String get assignMultipleCoaches =>
      'Több edző hozzárendelése különböző szerepkörökkel';

  @override
  String get confirmDelete => 'Törlés megerősítése';

  @override
  String get confirmDeleteMessage =>
      'Biztosan törölni szeretné ezt az elemet? Ez a művelet nem vonható vissza.';

  @override
  String editEntity(String entity) {
    return '$entity szerkesztése';
  }

  @override
  String get successfullyUpdated => 'Sikeresen frissítve';

  @override
  String failedToUpdate(String error) {
    return 'Frissítés sikertelen: $error';
  }

  @override
  String get coachDeletedSuccessfully =>
      'Edző sikeresen törölve minden csapatból és hitelesítésből';

  @override
  String get deletedSuccessfully => 'Sikeresen törölve';

  @override
  String failedToDelete(String error) {
    return 'Törlés sikertelen: $error';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Már';

  @override
  String get monthApr => 'Ápr';

  @override
  String get monthMay => 'Máj';

  @override
  String get monthJun => 'Jún';

  @override
  String get monthJul => 'Júl';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Szep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get monthJanuary => 'Január';

  @override
  String get monthFebruary => 'Február';

  @override
  String get monthMarch => 'Március';

  @override
  String get monthApril => 'Április';

  @override
  String get monthMayFull => 'Május';

  @override
  String get monthJune => 'Június';

  @override
  String get monthJuly => 'Július';

  @override
  String get monthAugust => 'Augusztus';

  @override
  String get monthSeptember => 'Szeptember';

  @override
  String get monthOctober => 'Október';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get sendReminderButton => 'Emlékeztető küldése';

  @override
  String get playerNotFound => 'Játékos nem található';

  @override
  String get noEmailAvailable => 'Nincs elérhető e-mail ehhez a játékoshoz';

  @override
  String get allMonthsPaid => 'Minden hónap ki van fizetve!';

  @override
  String get paymentReminderEmail => 'Fizetési emlékeztető e-mail';

  @override
  String emailTo(String email) {
    return 'Címzett: $email';
  }

  @override
  String emailSubject(String playerName) {
    return 'Tárgy: Fizetési emlékeztető $playerName részére';
  }

  @override
  String get dearParent => 'Tisztelt Szülő/Gondviselő,';

  @override
  String get reminderUnpaidMonths =>
      'Ezúton emlékeztetjük, hogy az alábbi hónapok ki nem fizetettek:';

  @override
  String get pleasePayConvenience =>
      'Kérjük, teljesítse a fizetést a lehető leghamarabb.';

  @override
  String get thankYou => 'Köszönjük,';

  @override
  String get footballClubManagement => 'Futballklub vezetősége';

  @override
  String get close => 'Bezárás';

  @override
  String get sendEmail => 'E-mail küldése';

  @override
  String emailSentTo(String email) {
    return 'E-mail elküldve ide: $email';
  }

  @override
  String errorOccurred(String error) {
    return 'Hiba: $error';
  }

  @override
  String get paymentStatus => 'Fizetési állapot';

  @override
  String paymentManagement(String year) {
    return '$year fizetés kezelés';
  }

  @override
  String get paymentReminder => 'Fizetési emlékeztető';

  @override
  String get position => 'Pozíció';

  @override
  String get team => 'Csapat';

  @override
  String get selectTeam => 'Csapat kiválasztása';

  @override
  String get assignCoach => 'Edző hozzárendelése';

  @override
  String get trainingType => 'Edzés típusa';

  @override
  String get pitchLocation => 'Pálya helye';

  @override
  String get startTraining => 'Edzés indítása (2 órás időszak)';

  @override
  String get saveSession => 'Edzés mentése';

  @override
  String get failedToSendEmail =>
      'E-mail küldése sikertelen. Kérjük, próbálja újra.';

  @override
  String get totalPlayers => 'Összes játékos';

  @override
  String get totalTeams => 'Összes csapat';

  @override
  String get activeCoaches => 'Aktív edzők';

  @override
  String get keyStatistics => 'Fő statisztikák';

  @override
  String get recentTrainingSessions => 'Legutóbbi edzések';

  @override
  String get playerDetails => 'Játékos Részletek';

  @override
  String get generateReport => 'Jelentés Készítése';

  @override
  String get birthDate => 'Születési Dátum';

  @override
  String get lastSession => 'Utolsó Edzés';

  @override
  String get status => 'Státusz';

  @override
  String get present => 'Jelen volt';

  @override
  String get absent => 'Hiányzott';

  @override
  String get sessionStart => 'Edzés kezdete';

  @override
  String get sessionEnd => 'Edzés vége';

  @override
  String get trainingSummary => 'Edzés összesítő';

  @override
  String get noTrainingRecorded => 'Nincs rögzített edzés';

  @override
  String get playerReport => 'Játékos Jelentés';

  @override
  String get basicInfo => 'Alapinformációk';

  @override
  String get attendanceInfo => 'Részvételi információk';

  @override
  String get statistics => 'Statisztikák';

  @override
  String get totalMinutes => 'Összes perc';

  @override
  String get sessionsAttended => 'Részvett edzések';

  @override
  String get attendanceRate => 'Részvételi arány';

  @override
  String get errorLoadingData => 'Hiba az adatok betöltésekor';

  @override
  String get pdfGenerationError => 'Hiba a PDF készítésekor';

  @override
  String get pdfGeneratedSuccess => 'PDF sikeresen elkészítve';

  @override
  String get noImage => 'Nincs kép';

  @override
  String get loadError => 'Betöltési hiba';

  @override
  String get minutes => 'perc';

  @override
  String get sessions => 'edzések';

  @override
  String get exportPdf => 'PDF Exportálása';

  @override
  String get backToList => 'Vissza a listához';

  @override
  String get noTeamAssigned => 'Nincs csapat hozzárendelve';

  @override
  String get editFunctionality => 'Szerkesztés funkció hamarosan elérhető';

  @override
  String get userNotFound => 'Nem található felhasználó ezzel az e-mail címmel';

  @override
  String get wrongPassword => 'Helytelen jelszó';

  @override
  String get invalidEmail => 'Érvénytelen e-mail cím';

  @override
  String get userDisabled => 'A fiók le van tiltva';

  @override
  String get tooManyRequests =>
      'Túl sok bejelentkezési kísérlet. Próbálja újra később';

  @override
  String get networkError => 'Hálózati hiba. Ellenőrizze a kapcsolatot';

  @override
  String get loginFailed => 'Bejelentkezés sikertelen. Kérjük, próbálja újra';

  @override
  String get pleaseEnterEmail => 'Kérjük, adja meg az e-mail címét';

  @override
  String get pleaseEnterValidEmail =>
      'Kérjük, adjon meg egy érvényes e-mail címet';

  @override
  String get pleaseEnterPassword => 'Kérjük, adja meg a jelszavát';

  @override
  String get passwordMinLength =>
      'A jelszónak legalább 6 karakterből kell állnia';

  @override
  String get loading => 'Töltés...';

  @override
  String get refresh => 'Frissítés';

  @override
  String get comingSoon => 'Hamarosan elérhető!';

  @override
  String get logoutFailed => 'Kijelentkezés sikertelen';

  @override
  String get deleteSuccess => 'Sikeresen törölve.';

  @override
  String get coachDeleteSuccess =>
      'Edző sikeresen törölve az összes csapatból és a hitelesítésből.';

  @override
  String get somethingWentWrong => 'Valami hiba történt';

  @override
  String get tryAgainOrContact =>
      'Kérjük, próbálja újra vagy vegye fel a kapcsolatot a támogatással';

  @override
  String get retry => 'Újra';

  @override
  String get paymentOverview => 'Fizetési áttekintés';

  @override
  String get unnamedPlayer => 'Névtelen játékos';

  @override
  String get unnamedCoach => 'Névtelen edző';

  @override
  String get unnamedTeam => 'Névtelen csapat';

  @override
  String get coach => 'Edző';

  @override
  String get unknown => 'Ismeretlen';

  @override
  String get unknownTeam => 'Ismeretlen csapat';

  @override
  String get receptionist => 'Recepciós';

  @override
  String get noEmailForPlayer => 'Nincs elérhető e-mail cím ehhez a játékoshoz';

  @override
  String get to => 'Címzett';

  @override
  String get subject => 'Tárgy';

  @override
  String paymentReminderFor(String playerName) {
    return 'Fizetési emlékeztető $playerName számára';
  }

  @override
  String get dearParentGuardian => 'Kedves Szülő/Gondviselő!';

  @override
  String get pleasePayEarliest => 'Kérjük, fizesse ki a lehőtet legkorábban.';

  @override
  String get errorUpdatingPayment => 'Hiba a fizetés frissítésekor';

  @override
  String paymentManagementFor(String year) {
    return '$year fizetés kezelés';
  }

  @override
  String get adding => 'Hozzáadás...';

  @override
  String get personalInformation => 'Személyes adatok';

  @override
  String get coachNameRequired => 'Az edző neve kötelező';

  @override
  String get nameMinLength => 'A névnek legalább 2 karakterből kell állnia';

  @override
  String get emailRequired => 'Az e-mail cím kötelező';

  @override
  String get validEmailRequired => 'Adjon meg egy érvényes e-mail címet';

  @override
  String get roleDescriptionMaxLength =>
      'A szerepkör leírása kevesebb mint 100 karakterből kell álljon';

  @override
  String get teamAssignment => 'Csapat hozzárendelés';

  @override
  String get selectTeamsToTrain =>
      'Válassza ki a csapatokat, amelyeket ez az edző edzeni fog';

  @override
  String assignedTeams(String count) {
    return 'Hozzárendelt csapatok ($count)';
  }

  @override
  String get many => 'TÖBB';

  @override
  String get addTeam => 'Csapat hozzáadása';

  @override
  String get maximumTeamsAssigned => 'Maximum csapatok hozzárendelve';

  @override
  String get noTeamsAvailable => 'Nincsenek elérhető csapatok';

  @override
  String get allTeamsAssigned => 'Minden csapat hozzárendelve';

  @override
  String get loadingTeams => 'Csapatok betöltése...';

  @override
  String get selectTeamToAdd => 'Válassza ki a hozzáadandó csapatot';

  @override
  String get selectRole => 'Szerepkör kiválasztása';

  @override
  String forTeam(String teamName) {
    return '$teamName számára';
  }

  @override
  String get coachOptionalAssignment =>
      'Az edző több csapathoz is hozzárendelhető (opcionális)';

  @override
  String get playerInformation => 'Játékos adatok';

  @override
  String get enterPlayerName => 'Adja meg a játékos nevét';

  @override
  String get selectBirthDate => 'Válassza ki a születési dátumot';

  @override
  String get enterPosition => 'Adja meg a pozíciót';

  @override
  String get teamInformation => 'Csapat adatok';

  @override
  String get teamNameRequired => 'A csapat neve kötelező';

  @override
  String get teamNameMinLength =>
      'A csapat nevének legalább 2 karakterből kell állnia';

  @override
  String get teamNameMaxLength =>
      'A csapat neve kevesebb mint 30 karakterből kell álljon';

  @override
  String get teamDescription => 'Csapat leírása';

  @override
  String get teamDescriptionRequired => 'A csapat leírása kötelező';

  @override
  String get descriptionMinLength =>
      'A leírásnak legalább 10 karakterből kell állnia';

  @override
  String get descriptionMaxLength =>
      'A leírás kevesebb mint 200 karakterből kell álljon';

  @override
  String get coachAssignment => 'Edző hozzárendelés';

  @override
  String assignedCoaches(String count) {
    return 'Hozzárendelt edzők ($count)';
  }

  @override
  String get max => 'MAX';

  @override
  String get addCoach => 'Edző hozzáadása';

  @override
  String get maximumCoachesAssigned => 'Maximum edzők hozzárendelve';

  @override
  String get noCoachesAvailable => 'Nincsenek elérhető edzők';

  @override
  String get allCoachesAssigned => 'Minden edző hozzárendelve';

  @override
  String get loadingCoaches => 'Edzők betöltése...';

  @override
  String get selectCoachToAdd => 'Válassza ki a hozzáadandó edzőt';

  @override
  String get atLeastOneCoachRequired =>
      'Legalább egy edzőt hozzá kell rendelni a csapat létrehozásához';

  @override
  String get profilePicture => 'Profilkép';

  @override
  String get tapToSelectPicture =>
      'Kattintson a fenti körre profilkép kiválasztásához';

  @override
  String get uploadImage => 'Kép feltöltése';

  @override
  String get uploading => 'Feltöltés...';

  @override
  String get addNewCoach => 'Új edző hozzáadása a rendszerhez';

  @override
  String get registerNewPlayer => 'Új játékos regisztrálása';

  @override
  String get createNewTeam => 'Új csapat létrehozása';

  @override
  String get addNewEntry => 'Új bejegyzés hozzáadása';

  @override
  String get assignToTeam => 'Csapathoz rendelés';

  @override
  String get passwordMinLengthSix =>
      'A jelszónak legalább 6 karakterből kell állnia';

  @override
  String get failedToPickImage => 'Kép kiválasztása sikertelen';

  @override
  String get imageUploadedSuccessfully => 'Kép sikeresen feltöltve!';

  @override
  String get uploadFailed => 'Feltöltés sikertelen';

  @override
  String coachAddedSuccessfully(String teamCount) {
    return 'Edző sikeresen hozzáadva $teamCount csapathoz!';
  }

  @override
  String get coachAddedSuccessfullySimple => 'Edző sikeresen hozzáadva!';

  @override
  String get errorAddingCoach => 'Hiba az edző hozzáadásakor';

  @override
  String get pleaseSelectTeamForPlayer =>
      'Kérjük, válasszon csapatot a játékos számára.';

  @override
  String get playerAddedSuccessfully => 'Játékos sikeresen hozzáadva!';

  @override
  String get errorAddingPlayer => 'Hiba a játékos hozzáadásakor';

  @override
  String get atLeastOneCoachTeamRequired =>
      'Legalább egy edzőt hozzá kell rendelni a csapathoz.';

  @override
  String teamCreatedSuccessfully(String teamName, String coachCount) {
    return '\"$teamName\" csapat létrehozva $coachCount edzővel!';
  }

  @override
  String get failedToCreateTeam =>
      'Csapat létrehozása sikertelen. Kérjük, próbálja újra.';

  @override
  String get headCoach => 'Főedző';

  @override
  String get assistantCoach => 'Másodedző';

  @override
  String get tacticsCoach => 'Taktikai edző';

  @override
  String get fitnessCoach => 'Erőnléti edző';

  @override
  String get goalkeepingCoach => 'Kapusedző';

  @override
  String get youthCoach => 'Utánpótlás edző';

  @override
  String get markPayment => 'Fizetés jelölése';

  @override
  String recordPaymentFor(String year) {
    return 'Fizetés rögzítése $year-ra';
  }

  @override
  String get selectPlayer => 'Játékos kiválasztása';

  @override
  String get selectMonth => 'Hónap kiválasztása';

  @override
  String get paymentSummary => 'Fizetési összesítő';

  @override
  String get year => 'Év';

  @override
  String get month => 'hónap';

  @override
  String get amount => 'Összeg';

  @override
  String get paymentMethod => 'Fizetési mód';

  @override
  String get manualEntry => 'Kézi bevitel';

  @override
  String get noFeeConfigured =>
      'Ehhez a csapathoz nincs fizetési díj beállítva';

  @override
  String get notes => 'Megjegyzések';

  @override
  String get optionalNotes => 'Opcionális megjegyzések vagy kommentek...';

  @override
  String get partiallyPaid => 'Részben Fizetve';

  @override
  String get inactive => 'Inaktív';

  @override
  String get paymentFullyCompleted => 'Fizetés teljesen teljesítve';

  @override
  String get partialPaymentReceived => 'Részfizetés érkezett';

  @override
  String get noPaymentReceived => 'Nem érkezett fizetés';

  @override
  String get playerInactiveSuspended => 'Játékos inaktív/felfüggesztett';

  @override
  String get markAsPaid => 'Jelölés fizetettként';

  @override
  String get markAsPartial => 'Jelölés részben fizetettként';

  @override
  String get markAsUnpaid => 'Jelölés nem fizetettként';

  @override
  String get markAsInactive => 'Jelölés inaktívként';

  @override
  String get paymentMarkedPaidSuccess =>
      'Fizetés sikeresen FIZETETT-re jelölve!';

  @override
  String get paymentMarkedPartialSuccess =>
      'Fizetés sikeresen RÉSZBEN FIZETVE-re jelölve!';

  @override
  String get paymentMarkedUnpaidSuccess =>
      'Fizetés sikeresen FIZETETLEN-re jelölve!';

  @override
  String get playerMarkedInactiveSuccess =>
      'Játékos sikeresen INAKTÍV-ra jelölve!';

  @override
  String get errorMarkingPayment => 'Hiba a fizetés jelölésekor';

  @override
  String get activate => 'Aktiválás';

  @override
  String playerInactiveMonths(String months) {
    return 'Játékos $months hónapja inaktív';
  }

  @override
  String inactiveMonthsProgress(String months) {
    return 'Inaktív ($months/12 hónap)';
  }

  @override
  String activeMonthsProgress(String paid, String total) {
    return '$paid/$total aktív hónap';
  }

  @override
  String get editUser => 'Felhasználó szerkesztése';

  @override
  String get pleaseEnterName => 'Kérjük, adjon meg egy nevet';

  @override
  String get role => 'Szerepkör';

  @override
  String get enterRoleDescription => 'Adja meg a szerepkör leírását...';

  @override
  String get updating => 'Frissítés...';

  @override
  String get admin => 'Admin';

  @override
  String get loadingPaymentData => 'Fizetési adatok betöltése...';

  @override
  String get noPaymentDataAvailable => 'Nincs elérhető fizetési adat';

  @override
  String get filter => 'Szűrő';

  @override
  String get allPlayers => 'Minden játékos';

  @override
  String get overview => 'Áttekintés';

  @override
  String get reports => 'Jelentések';

  @override
  String get months => 'hónap';

  @override
  String get paid => 'Fizetve';

  @override
  String get paymentActions => 'Fizetési műveletek';

  @override
  String get recordNewPayment => 'Új fizetés rögzítése';

  @override
  String get sendBulkPaymentReminders =>
      'Tömeges fizetési emlékeztetők küldése';

  @override
  String get sendReminders => 'Emlékeztetők küldése';

  @override
  String get exportData => 'Adatok exportálása';

  @override
  String get downloadPaymentReport => 'Fizetési jelentés letöltése';

  @override
  String get quickActions => 'Gyors műveletek';

  @override
  String get goodMorning => 'Jó reggelt';

  @override
  String get goodAfternoon => 'Jó napot';

  @override
  String get goodEvening => 'Jó estét';

  @override
  String get clubOverviewToday => 'Itt a klubjának mai áttekintése';

  @override
  String get exportReport => 'Jelentés exportálása';

  @override
  String get monthlyReport => 'Havi jelentés';

  @override
  String get detailedBreakdownByMonth => 'Részletes havi bontás';

  @override
  String get teamReport => 'Csapat jelentés';

  @override
  String get paymentStatusByTeam => 'Fizetési állapot csapat szerint';

  @override
  String get overdueReport => 'Lejárt fizetések jelentése';

  @override
  String get playersWithOutstandingPayments => 'Játékosok függő fizetésekkel';

  @override
  String get annualSummary => 'Éves összesítő';

  @override
  String get completeYearOverview => 'Teljes éves áttekintés';

  @override
  String get downloadCenter => 'Letöltőközpont';

  @override
  String get noRecentDownloads => 'Nincsenek újabb letöltések';

  @override
  String get recentDownloads => 'Legutóbbi letöltések:';

  @override
  String get exportedReportsAvailable =>
      'Az exportált jelentések itt lesznek elérhetők a generálás után. Jelenleg nincsenek elérhető letöltések.';

  @override
  String paymentReminderSent(String playerName, String amount) {
    return 'Fizetési emlékeztető elküldve $playerName részére! Függő összeg: $amount';
  }

  @override
  String get monthlyReportGenerated => 'Havi jelentés sikeresen generálva!';

  @override
  String get teamReportGenerated => 'Csapat jelentés sikeresen generálva!';

  @override
  String get overdueReportGenerated =>
      'Lejárt fizetések jelentése sikeresen generálva!';

  @override
  String get annualReportGenerated => 'Éves jelentés sikeresen generálva!';

  @override
  String get settingsScreen => 'Beállítások';

  @override
  String get accountSettings => 'Fiók beállítások';

  @override
  String get changePassword => 'Jelszó megváltoztatása';

  @override
  String get personalInfo => 'Személyes adatok';

  @override
  String get editProfile => 'Profil szerkesztése';

  @override
  String get profilePictureUpdate => 'Profilkép frissítése';

  @override
  String get appPreferences => 'Alkalmazás beállítások';

  @override
  String get language => 'Nyelv';

  @override
  String get languageSelection => 'Nyelv kiválasztása';

  @override
  String get english => 'English';

  @override
  String get hungarian => 'Magyar';

  @override
  String get selectLanguage => 'Nyelv kiválasztása';

  @override
  String get theme => 'Téma';

  @override
  String get lightMode => 'Világos mód';

  @override
  String get darkMode => 'Sötét mód';

  @override
  String get systemDefault => 'Rendszer alapértelmezett';

  @override
  String get dateFormat => 'Dátum formátum';

  @override
  String get timeFormat => 'Idő formátum';

  @override
  String get hour12 => '12 órás';

  @override
  String get hour24 => '24 órás';

  @override
  String get notificationSettings => 'Értesítési beállítások';

  @override
  String get emailNotifications => 'E-mail értesítések';

  @override
  String get pushNotifications => 'Push értesítések';

  @override
  String get paymentReminders => 'Fizetési emlékeztetők';

  @override
  String get newPlayerAlerts => 'Új játékos értesítések';

  @override
  String get systemUpdates => 'Rendszer frissítések';

  @override
  String get marketingEmails => 'Marketing e-mailek';

  @override
  String get paymentPreferences => 'Fizetési beállítások';

  @override
  String get defaultCurrency => 'Alapértelmezett pénznem';

  @override
  String get reminderFrequency => 'Emlékeztető gyakoriság';

  @override
  String get daily => 'Napi';

  @override
  String get weekly => 'Heti';

  @override
  String get monthly => 'Havi';

  @override
  String get autoBackup => 'Automatikus mentés';

  @override
  String get securityPrivacy => 'Biztonság és adatvédelem';

  @override
  String get currentPassword => 'Jelenlegi jelszó';

  @override
  String get newPassword => 'Új jelszó';

  @override
  String get confirmPassword => 'Jelszó megerősítése';

  @override
  String get passwordRequirements =>
      'A jelszónak legalább 8 karakterből kell állnia';

  @override
  String get twoFactorAuth => 'Kétfaktoros hitelesítés';

  @override
  String get loginHistory => 'Bejelentkezési előzmények';

  @override
  String get privacySettings => 'Adatvédelmi beállítások';

  @override
  String get dataCollection => 'Adatgyűjtés';

  @override
  String get helpSupport => 'Súgó és támogatás';

  @override
  String get faq => 'Gyakran ismételt kérdések';

  @override
  String get contactSupport => 'Támogatás kapcsolat';

  @override
  String get tutorials => 'Oktatóanyagok';

  @override
  String get reportBug => 'Hiba jelentése';

  @override
  String get featureRequest => 'Funkció kérése';

  @override
  String get documentation => 'Dokumentáció';

  @override
  String get aboutApp => 'Alkalmazásról';

  @override
  String get version => 'Verzió';

  @override
  String get termsOfService => 'Felhasználási feltételek';

  @override
  String get privacyPolicy => 'Adatvédelmi irányelvek';

  @override
  String get licenses => 'Nyílt forráskódú licencek';

  @override
  String get releaseNotes => 'Kiadási jegyzet';

  @override
  String get dangerZone => 'Veszélyes zóna';

  @override
  String get logoutAllDevices => 'Kijelentkezés minden eszközről';

  @override
  String get deleteAccount => 'Fiók törlése';

  @override
  String get clearCache => 'Gyorsítótár törlése';

  @override
  String get resetSettings => 'Beállítások visszaállítása';

  @override
  String get saveChanges => 'Változtatások mentése';

  @override
  String get discardChanges => 'Változtatások elvetése';

  @override
  String get settingsSaved => 'Beállítások sikeresen mentve!';

  @override
  String get passwordChanged => 'Jelszó sikeresen megváltoztatva!';

  @override
  String get languageChanged => 'Nyelv sikeresen megváltoztatva!';

  @override
  String get profileUpdated => 'Profil sikeresen frissítve!';

  @override
  String get confirmLogoutAll =>
      'Biztos, hogy ki szeretne jelentkezni minden eszközről?';

  @override
  String get confirmDeleteAccount =>
      'Biztos, hogy törölni szeretné a fiókját? Ez a művelet nem vonható vissza.';

  @override
  String get confirmResetSettings =>
      'Biztos, hogy vissza szeretné állítani az összes beállítást alapértelmezettre?';

  @override
  String get passwordsDoNotMatch => 'A jelszavak nem egyeznek';

  @override
  String get currentPasswordIncorrect => 'A jelenlegi jelszó helytelen';

  @override
  String get enterCurrentPassword => 'Adja meg a jelenlegi jelszót';

  @override
  String get enterNewPassword => 'Adja meg az új jelszót';

  @override
  String get confirmNewPassword => 'Erősítse meg az új jelszót';

  @override
  String get enabled => 'Engedélyezve';

  @override
  String get disabled => 'Letiltva';

  @override
  String get never => 'Soha';

  @override
  String get immediately => 'Azonnal';

  @override
  String get after5Minutes => '5 perc után';

  @override
  String get after15Minutes => '15 perc után';

  @override
  String get after30Minutes => '30 perc után';

  @override
  String get after1Hour => '1 óra után';

  @override
  String get notifications => 'Értesítések';

  @override
  String get account => 'Fiók';

  @override
  String get administrator => 'Adminisztrátor';

  @override
  String get appearance => 'Megjelenés';

  @override
  String get enableDarkModeForApp => 'Sötét mód engedélyezése az alkalmazáshoz';

  @override
  String get languageAndRegion => 'Nyelv és régió';

  @override
  String get security => 'Biztonság';

  @override
  String get twoFactorAuthentication => 'Kétfaktoros hitelesítés';

  @override
  String get addExtraSecurityLayer => 'Extra biztonsági réteg hozzáadása';

  @override
  String get updateAccountPassword => 'Fiók jelszó frissítése';

  @override
  String get manageDataPrivacy => 'Adatvédelem kezelése';

  @override
  String get soon => 'Hamarosan';

  @override
  String get aboutThisApp => 'Az alkalmazásról';

  @override
  String get currentAppVersion => 'Jelenlegi alkalmazás verzió';

  @override
  String get readTermsOfService => 'Szolgáltatási feltételek elolvasása';

  @override
  String get readPrivacyPolicy => 'Adatvédelmi irányelvek elolvasása';

  @override
  String get viewOpenSourceLicenses => 'Nyílt forráskódú licencek megtekintése';

  @override
  String get searchUsers => 'Felhasználók keresése...';

  @override
  String get addNewUser => 'Új felhasználó hozzáadása';

  @override
  String get nameRequired => 'A név megadása kötelező';

  @override
  String get passwordRequired => 'A jelszó megadása kötelező';

  @override
  String get userAddedSuccessfully => 'Felhasználó sikeresen hozzáadva!';

  @override
  String get userUpdatedSuccessfully => 'Felhasználó sikeresen frissítve!';

  @override
  String get userDeletedSuccessfully => 'Felhasználó sikeresen törölve!';

  @override
  String get errorAddingUser => 'Hiba a felhasználó hozzáadásakor';

  @override
  String get errorUpdatingUser => 'Hiba a felhasználó frissítésekor';

  @override
  String get errorDeletingUser => 'Hiba a felhasználó törlésekor';

  @override
  String get confirmDeletion => 'Törlés megerősítése';

  @override
  String get deleteUserWarning =>
      'Biztosan törölni szeretné ezt a felhasználót?';

  @override
  String get deleteUserDescription =>
      'Ez a művelet nem vonható vissza. A felhasználó minden adata véglegesen törlődik.';

  @override
  String get leaveEmptyToKeep => 'Hagyja üresen, ha nem szeretné módosítani';

  @override
  String get sessionReport => 'Edzés jelentés';

  @override
  String get attendanceInformation => 'Jelenléti információk';

  @override
  String get trainingHistory => 'Edzéstörténet';

  @override
  String get duration => 'Időtartam';

  @override
  String get sessionDetails => 'Edzés részletei';

  @override
  String get playerName => 'Játékos neve';

  @override
  String get numberOfPlayers => 'Játékosok száma';

  @override
  String get sessionDate => 'Edzés dátuma';

  @override
  String get attendanceList => 'Jelenléti lista';

  @override
  String get presentPlayers => 'Jelen lévő játékosok';

  @override
  String get absentPlayers => 'Hiányzó játékosok';

  @override
  String get systemNotifications => 'Rendszer értesítések';

  @override
  String get securityAlerts => 'Biztonsági riasztások';

  @override
  String get refreshing => 'Frissítés...';

  @override
  String get seeAll => 'Összes megtekintése';

  @override
  String get organizationSetup => 'Szervezet beállítása';

  @override
  String get stepBasicInfo => 'Alapinformációk';

  @override
  String get stepAdminUser => 'Adminisztrátor';

  @override
  String get stepTeamSetup => 'Csapat beállítása';

  @override
  String get stepPaymentConfig => 'Fizetés beállítása';

  @override
  String get stepReview => 'Áttekintés és befejezés';

  @override
  String get organizationName => 'Szervezet neve';

  @override
  String get organizationAddress => 'Szervezet címe';

  @override
  String get organizationType => 'Szervezet típusa';

  @override
  String get selectOrgType => 'Válassza ki a szervezet típusát';

  @override
  String get club => 'Klub';

  @override
  String get school => 'Iskola';

  @override
  String get academy => 'Akadémia';

  @override
  String get other => 'Egyéb';

  @override
  String get adminSetup => 'Adminisztrátor beállítása';

  @override
  String get adminName => 'Adminisztrátor neve';

  @override
  String get adminEmail => 'Adminisztrátor e-mail';

  @override
  String get adminPassword => 'Adminisztrátor jelszó';

  @override
  String get createAdminAccount => 'Adminisztrátor fiók létrehozása';

  @override
  String get teamSetupTitle => 'Kezdeti csapatok létrehozása';

  @override
  String get addTeamsDescription =>
      'Adjon hozzá csapatokat és minta játékosokat a kezdéshez';

  @override
  String get enterTeamName => 'Adja meg a csapat nevét';

  @override
  String get addSamplePlayers => 'Minta játékosok hozzáadása';

  @override
  String get samplesPerTeam => 'játékos csapatonként';

  @override
  String get paymentConfiguration => 'Fizetés beállítása';

  @override
  String get defaultMonthlyFee => 'Alapértelmezett havi díj';

  @override
  String get currency => 'Pénznem';

  @override
  String get selectCurrency => 'Válasszon pénznemet';

  @override
  String get paymentDueDay => 'Fizetési határidő napja';

  @override
  String get dueDayDescription => 'A hónap napja, amikor a fizetés esedékes';

  @override
  String get reviewAndComplete => 'Áttekintés és befejezés';

  @override
  String get setupSummary => 'Beállítás összesítő';

  @override
  String get reviewDetails => 'Ellenőrizze az alábbi szervezeti adatokat';

  @override
  String get finishSetup => 'Beállítás befejezése';

  @override
  String get backToPrevious => 'Vissza az előzőhöz';

  @override
  String get nextStep => 'Következő lépés';

  @override
  String get setupInProgress => 'Beállítás folyamatban...';

  @override
  String get creatingOrganization => 'Szervezet létrehozása...';

  @override
  String get creatingAdminAccount => 'Adminisztrátor fiók létrehozása...';

  @override
  String get settingUpTeams => 'Csapatok beállítása...';

  @override
  String get configuringPayments => 'Fizetések beállítása...';

  @override
  String get finalizingSetup => 'Beállítás véglegesítése...';

  @override
  String get setupCompleteTitle => 'Beállítás kész!';

  @override
  String get setupCompleteMessage => 'A szervezete sikeresen létrehozva';

  @override
  String get getStarted => 'Kezdés';

  @override
  String get setupError => 'Beállítási hiba';

  @override
  String get setupErrorMessage =>
      'Hiba történt a beállítás során. Kérjük, próbálja újra.';

  @override
  String get contactSupportIfPersists =>
      'Vegye fel a kapcsolatot a támogatással, ha a hiba fennáll.';

  @override
  String get processingRequest => 'Kérés feldolgozása...';

  @override
  String get pleaseWait => 'Kérjük, várjon...';

  @override
  String get almostDone => 'Majdnem kész...';

  @override
  String get demoOrganization => 'Demo szervezet';

  @override
  String get demoMode => 'Demo mód';

  @override
  String get demoDataWarning =>
      'Ez demo adat. A változtatások nem lesznek véglegesen mentve.';

  @override
  String get cleanupDemoData => 'Demo adatok törlése';

  @override
  String get cleanupDescription =>
      '24 óránál régebbi demo szervezetek eltávolítása';

  @override
  String get performCleanup => 'Törlés végrehajtása';

  @override
  String get cleanupComplete => 'Törlés kész';

  @override
  String get noOldDemoData => 'Nem található régi demo adat törléshez';

  @override
  String get offlineMode => 'Offline mód';

  @override
  String get connectionLost => 'Kapcsolat megszakadt';

  @override
  String get reconnecting => 'Újracsatlakozás...';

  @override
  String get retryConnection => 'Kapcsolat újrapróbálása';

  @override
  String get offlineChanges =>
      'A változtatások szinkronizálódnak, amikor a kapcsolat helyreáll';

  @override
  String get validationError => 'Érvényesítési hiba';

  @override
  String get fieldRequired => 'Ez a mező kötelező';

  @override
  String get invalidFormat => 'Érvénytelen formátum';

  @override
  String get mustBeNumber => 'Érvényes számnak kell lennie';

  @override
  String get mustBePositive => 'Pozitív számnak kell lennie';

  @override
  String get tooShort => 'Túl rövid';

  @override
  String get tooLong => 'Túl hosszú';

  @override
  String get organizationExists => 'Ilyen nevű szervezet már létezik';

  @override
  String get emailTaken => 'Ez az e-mail cím már foglalt';

  @override
  String get weakPassword => 'A jelszó túl gyenge';

  @override
  String get invalidEmailFormat => 'Érvénytelen e-mail formátum';

  @override
  String get organizationNameTooShort => 'A szervezet neve túl rövid';

  @override
  String get addressRequired => 'A cím megadása kötelező';

  @override
  String get loadingOrganizations => 'Szervezetek betöltése...';

  @override
  String get selectExistingOrg => 'Meglévő szervezet kiválasztása';

  @override
  String get createNewOrg => 'Új szervezet létrehozása';

  @override
  String get joinOrganization => 'Csatlakozás szervezethez';

  @override
  String get switchOrganization => 'Szervezet váltása';

  @override
  String get noOrganizationAccess =>
      'Nincs hozzáférése egyetlen szervezethez sem';

  @override
  String get resumeSetup => 'Beállítás folytatása';

  @override
  String get continueSetup => 'Beállítás folytatása';

  @override
  String get startFresh => 'Újrakezdés';

  @override
  String get setupInterrupted => 'A beállítás megszakadt';

  @override
  String resumeFromStep(String stepNumber) {
    return 'Folytatás a $stepNumber. lépéstől';
  }

  @override
  String get abandonSetup => 'Beállítás megszakítása';

  @override
  String get networkTimeoutError =>
      'Hálózati időtúllépés. Kérjük, ellenőrizze a kapcsolatot.';

  @override
  String get serverError => 'Szerverhiba. Kérjük, próbálja újra később.';

  @override
  String get rateLimitExceeded => 'Túl sok kérés. Kérjük, várjon egy kicsit.';

  @override
  String get operationCancelled => 'A művelet megszakadt';

  @override
  String get batchOperationInProgress => 'Kötegelt művelet folyamatban...';

  @override
  String processingItems(String current, String total) {
    return '$current/$total elem feldolgozása...';
  }

  @override
  String get teamReportTitle => 'Csapat jelentés';

  @override
  String get teamDetails => 'Csapat részletek';

  @override
  String get positionDistribution => 'Pozíció eloszlás';

  @override
  String get teamPlayers => 'Csapat játékosok';

  @override
  String teamPlayersCount(String count) {
    return 'Csapat játékosok ($count)';
  }

  @override
  String get goalkeeper => 'Kapus';

  @override
  String get defender => 'Védő';

  @override
  String get midfielder => 'Középpályás';

  @override
  String get forward => 'Támadó';

  @override
  String get averageAge => 'Átlagos életkor';

  @override
  String get noPlayersFound => 'Nem található játékos ehhez a csapathoz.';

  @override
  String get loadingTeamDetails => 'Csapat részletek betöltése...';

  @override
  String get loadingPlayers => 'Játékosok betöltése...';

  @override
  String get calculatingStatistics => 'Statisztikák számítása...';

  @override
  String get errorLoadingTeamData => 'Hiba a csapat adatok betöltésekor';

  @override
  String get errorLoadingPlayers => 'Hiba a csapat játékosok betöltésekor';

  @override
  String get pdfSuccessfullyGenerated => 'PDF sikeresen generálva!';

  @override
  String errorGeneratingPdfReport(String error) {
    return 'Hiba a PDF jelentés generálásakor: $error';
  }

  @override
  String get generating => 'Generálás...';

  @override
  String get noDescription => 'Nincs leírás';

  @override
  String get unknownPlayer => 'Ismeretlen játékos';

  @override
  String get cannotLoadPlayerDetails =>
      'Nem lehet betölteni a részleteket: Hiányzó játékos azonosító.';

  @override
  String get loadingPlayerDetails => 'Játékos részletek betöltése...';

  @override
  String get playerDetailsNotFound => 'Játékos részletek nem találhatók.';

  @override
  String get errorLoadingPlayerDetails =>
      'Hiba a játékos részletek betöltésekor.';

  @override
  String get profile => 'Profil';

  @override
  String get help => 'Súgó';

  @override
  String get about => 'Névjegy';

  @override
  String get updateCloseSession => 'Frissítés és edzés bezárása';

  @override
  String get trainingActive => 'Edzés aktív';

  @override
  String endsAt(String time) {
    return 'Vége: $time';
  }

  @override
  String get closed => 'Bezárva';

  @override
  String get notesOptional => 'Megjegyzések (opcionális)';

  @override
  String get manageYourProfile => 'Profil kezelése';

  @override
  String get themeSettings => 'Téma beállítások';

  @override
  String get callSupport => 'Támogatás hívása';

  @override
  String get emailSupport => 'E-mail támogatás';

  @override
  String get getHelpSupport => 'Segítségkérés és támogatás';

  @override
  String get appInformation => 'Alkalmazás információk';

  @override
  String get signOutAccount => 'Kijelentkezés a fiókból';

  @override
  String get confirmSignOut => 'Biztosan ki szeretne jelentkezni a fiókjából?';

  @override
  String get tapToChangePhoto => 'Koppintson a fénykép megváltoztatásához';

  @override
  String get uploadPhoto => 'Fénykép feltöltése';

  @override
  String get nameField => 'Név';

  @override
  String get emailField => 'E-mail';

  @override
  String get saveButton => 'Mentés';

  @override
  String get trainingTypeGame => 'Mérkőzés';

  @override
  String get trainingTypeTraining => 'Edzés';

  @override
  String get trainingTypeTactical => 'Taktikai';

  @override
  String get trainingTypeFitness => 'Erőnléti';

  @override
  String get trainingTypeTechnical => 'Technikai';

  @override
  String get trainingTypeTheoretical => 'Elméleti';

  @override
  String get trainingTypeSurvey => 'Felmérés';

  @override
  String get trainingTypeMixed => 'Vegyes';

  @override
  String get trainingDescGame =>
      'Hivatalos vagy gyakorló mérkőzések más csapatok ellen';

  @override
  String get trainingDescTraining =>
      'Általános edzés készségfejlesztéssel és kondicionálással';

  @override
  String get trainingDescTactical =>
      'Taktikai formációk, stratégiák és csapatjáték gyakorlása';

  @override
  String get trainingDescFitness =>
      'Kondicionáló edzés, erősítő gyakorlatok és állóképesség fejlesztés';

  @override
  String get trainingDescTechnical =>
      'Egyéni technikai készségek: labdavezetés, lövés, passzolás';

  @override
  String get trainingDescTheoretical =>
      'Taktikai megbeszélések, játékszabályok és stratégiai tervezés';

  @override
  String get trainingDescSurvey =>
      'Játékos értékelések, tesztelések és készségfelmérések';

  @override
  String get trainingDescMixed => 'Kombinált edzés több típus elemével';

  @override
  String get unknownCoachName => 'Ismeretlen edző';

  @override
  String get notSpecified => 'Nincs megadva';

  @override
  String get trainingSessionSaved =>
      'Edzés elmentve! Még egyszer szerkesztheti.';

  @override
  String get errorLoadingTeams => 'Hiba a csapatok betöltésekor';

  @override
  String get noTeamsAssigned => 'Nincs hozzárendelt csapat';

  @override
  String trainingEndsAt(String time) {
    return 'Vége: $time';
  }

  @override
  String get noPlayersFoundInTeam => 'Nem található játékos ebben a csapatban';

  @override
  String get themeTitle => 'Téma';

  @override
  String get coachRole => 'Edző';

  @override
  String callPhoneNumber(String phoneNumber) {
    return 'Hívás: $phoneNumber\nKoppintson a telefonszámra másoláshoz és tárcsázáshoz';
  }

  @override
  String emailAddress(String email) {
    return 'Email: $email\nKoppintson az emailre másoláshoz és küldéshez';
  }

  @override
  String get themeSettingsComingSoon => 'Téma beállítások';

  @override
  String get darkModeComingSoon =>
      'Sötét mód és téma testreszabási lehetőségek hamarosan elérhetők lesznek.';

  @override
  String languageChangedTo(String languageName) {
    return 'Nyelv megváltoztatva: $languageName';
  }

  @override
  String get helpSupportComingSoon => 'Súgó és támogatás hamarosan';

  @override
  String get footballTrainingApp => 'Futballedzés alkalmazás';

  @override
  String get versionLabel => 'Verzió: 1.0.0';

  @override
  String get appDescription => 'Átfogó futballedzés kezelő rendszer.';

  @override
  String get uploadTimeout =>
      'Feltöltési időtúllépés. Kérjük, ellenőrizze a kapcsolatot.';

  @override
  String get userNotAuthenticated =>
      'Felhasználó nincs hitelesítve vagy szervezet nincs inicializálva';

  @override
  String get currentPasswordRequiredForChanges =>
      'Jelenlegi jelszó szükséges az email vagy jelszó változtatásához';

  @override
  String get nameLabel => 'Név';

  @override
  String get emailLabel => 'Email';

  @override
  String get changePasswordLabel => 'Jelszó megváltoztatása';

  @override
  String get currentPasswordLabel => 'Jelenlegi jelszó';

  @override
  String get newPasswordLabel => 'Új jelszó';

  @override
  String get confirmNewPasswordLabel => 'Új jelszó megerősítése';

  @override
  String get saveLabel => 'Mentés';

  @override
  String get contact => 'Kapcsolat';

  @override
  String get phoneSupport => 'Telefonos támogatás';

  @override
  String get support => 'Támogatás';

  @override
  String get profileManagement => 'Profil kezelése';

  @override
  String get helpAndSupport => 'Segítség és támogatás';

  @override
  String get applicationInfo => 'Alkalmazás információ';
}
