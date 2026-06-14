import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Football Training'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @adminManagement.
  ///
  /// In en, this message translates to:
  /// **'Admin Management'**
  String get adminManagement;

  /// No description provided for @createNewOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create New Organization'**
  String get createNewOrganization;

  /// No description provided for @adminScreen.
  ///
  /// In en, this message translates to:
  /// **'Admin Screen'**
  String get adminScreen;

  /// No description provided for @coachScreen.
  ///
  /// In en, this message translates to:
  /// **'Coach Screen'**
  String get coachScreen;

  /// No description provided for @receptionistScreen.
  ///
  /// In en, this message translates to:
  /// **'Receptionist Screen'**
  String get receptionistScreen;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverview;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @coaches.
  ///
  /// In en, this message translates to:
  /// **'Coaches'**
  String get coaches;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @attendances.
  ///
  /// In en, this message translates to:
  /// **'Attendances'**
  String get attendances;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {entity}...'**
  String searchHint(String entity);

  /// No description provided for @addEntity.
  ///
  /// In en, this message translates to:
  /// **'Add {entity}'**
  String addEntity(String entity);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @playerInfo.
  ///
  /// In en, this message translates to:
  /// **'Player Info'**
  String get playerInfo;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @paymentProgress.
  ///
  /// In en, this message translates to:
  /// **'Payment Progress'**
  String get paymentProgress;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @notActive.
  ///
  /// In en, this message translates to:
  /// **'Not Active'**
  String get notActive;

  /// No description provided for @monthlyCollectionTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection Trend'**
  String get monthlyCollectionTrend;

  /// No description provided for @totalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Collected'**
  String get totalCollected;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @paidPlayers.
  ///
  /// In en, this message translates to:
  /// **'Paid Players'**
  String get paidPlayers;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @noEntitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No {entity} found'**
  String noEntitiesFound(String entity);

  /// No description provided for @addSomeEntities.
  ///
  /// In en, this message translates to:
  /// **'Add some {entity} to get started'**
  String addSomeEntities(String entity);

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingSearch;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @roleDescription.
  ///
  /// In en, this message translates to:
  /// **'Role Description'**
  String get roleDescription;

  /// No description provided for @coachesManagement.
  ///
  /// In en, this message translates to:
  /// **'Coaches Management'**
  String get coachesManagement;

  /// No description provided for @manageTeamCoaches.
  ///
  /// In en, this message translates to:
  /// **'Manage Team Coaches'**
  String get manageTeamCoaches;

  /// No description provided for @assignMultipleCoaches.
  ///
  /// In en, this message translates to:
  /// **'Assign multiple coaches with different roles'**
  String get assignMultipleCoaches;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @editEntity.
  ///
  /// In en, this message translates to:
  /// **'Edit {entity}'**
  String editEntity(String entity);

  /// No description provided for @successfullyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated'**
  String get successfullyUpdated;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdate(String error);

  /// No description provided for @coachDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Coach deleted from all teams and authentication successfully'**
  String get coachDeletedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(String error);

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMayFull.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMayFull;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @sendReminderButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminderButton;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player not found'**
  String get playerNotFound;

  /// No description provided for @noEmailAvailable.
  ///
  /// In en, this message translates to:
  /// **'No email available for this player'**
  String get noEmailAvailable;

  /// No description provided for @allMonthsPaid.
  ///
  /// In en, this message translates to:
  /// **'All months are paid!'**
  String get allMonthsPaid;

  /// No description provided for @paymentReminderEmail.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminder Email'**
  String get paymentReminderEmail;

  /// No description provided for @emailTo.
  ///
  /// In en, this message translates to:
  /// **'To: {email}'**
  String emailTo(String email);

  /// No description provided for @emailSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject: Payment Reminder for {playerName}'**
  String emailSubject(String playerName);

  /// No description provided for @dearParent.
  ///
  /// In en, this message translates to:
  /// **'Dear Parent/Guardian,'**
  String get dearParent;

  /// No description provided for @reminderUnpaidMonths.
  ///
  /// In en, this message translates to:
  /// **'This is a reminder that the following months are unpaid:'**
  String get reminderUnpaidMonths;

  /// No description provided for @pleasePayConvenience.
  ///
  /// In en, this message translates to:
  /// **'Please make the payment at your earliest convenience.'**
  String get pleasePayConvenience;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you,'**
  String get thankYou;

  /// No description provided for @footballClubManagement.
  ///
  /// In en, this message translates to:
  /// **'Football Club Management'**
  String get footballClubManagement;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @emailSentTo.
  ///
  /// In en, this message translates to:
  /// **'Email sent to {email}'**
  String emailSentTo(String email);

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(String error);

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentManagement.
  ///
  /// In en, this message translates to:
  /// **'{year} Payment Management'**
  String paymentManagement(String year);

  /// No description provided for @paymentReminder.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminder'**
  String get paymentReminder;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @selectTeam.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectTeam;

  /// No description provided for @assignCoach.
  ///
  /// In en, this message translates to:
  /// **'Assign Coach'**
  String get assignCoach;

  /// No description provided for @trainingType.
  ///
  /// In en, this message translates to:
  /// **'Training Type'**
  String get trainingType;

  /// No description provided for @pitchLocation.
  ///
  /// In en, this message translates to:
  /// **'Pitch Location'**
  String get pitchLocation;

  /// No description provided for @startTraining.
  ///
  /// In en, this message translates to:
  /// **'Start Training (2-hour window)'**
  String get startTraining;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// No description provided for @failedToSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send email. Please try again.'**
  String get failedToSendEmail;

  /// No description provided for @totalPlayers.
  ///
  /// In en, this message translates to:
  /// **'Total Players'**
  String get totalPlayers;

  /// No description provided for @totalTeams.
  ///
  /// In en, this message translates to:
  /// **'Total Teams'**
  String get totalTeams;

  /// No description provided for @activeCoaches.
  ///
  /// In en, this message translates to:
  /// **'Active Coaches'**
  String get activeCoaches;

  /// No description provided for @keyStatistics.
  ///
  /// In en, this message translates to:
  /// **'Key Statistics'**
  String get keyStatistics;

  /// No description provided for @recentTrainingSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent Training Sessions'**
  String get recentTrainingSessions;

  /// No description provided for @playerDetails.
  ///
  /// In en, this message translates to:
  /// **'Player Details'**
  String get playerDetails;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last Session'**
  String get lastSession;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @sessionStart.
  ///
  /// In en, this message translates to:
  /// **'Session Start'**
  String get sessionStart;

  /// No description provided for @sessionEnd.
  ///
  /// In en, this message translates to:
  /// **'Session End'**
  String get sessionEnd;

  /// No description provided for @trainingSummary.
  ///
  /// In en, this message translates to:
  /// **'Training Summary'**
  String get trainingSummary;

  /// No description provided for @noTrainingRecorded.
  ///
  /// In en, this message translates to:
  /// **'No training recorded'**
  String get noTrainingRecorded;

  /// No description provided for @playerReport.
  ///
  /// In en, this message translates to:
  /// **'Player Report'**
  String get playerReport;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @attendanceInfo.
  ///
  /// In en, this message translates to:
  /// **'Attendance Information'**
  String get attendanceInfo;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @totalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Total Minutes'**
  String get totalMinutes;

  /// No description provided for @sessionsAttended.
  ///
  /// In en, this message translates to:
  /// **'Sessions Attended'**
  String get sessionsAttended;

  /// No description provided for @attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance Rate'**
  String get attendanceRate;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @pdfGenerationError.
  ///
  /// In en, this message translates to:
  /// **'PDF generation error'**
  String get pdfGenerationError;

  /// No description provided for @pdfGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF generated successfully'**
  String get pdfGeneratedSuccess;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get noImage;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Load Error'**
  String get loadError;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get sessions;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to List'**
  String get backToList;

  /// No description provided for @noTeamAssigned.
  ///
  /// In en, this message translates to:
  /// **'No Team Assigned'**
  String get noTeamAssigned;

  /// No description provided for @editFunctionality.
  ///
  /// In en, this message translates to:
  /// **'Edit functionality coming soon'**
  String get editFunctionality;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account has been disabled'**
  String get userDisabled;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many login attempts. Try again later'**
  String get tooManyRequests;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection'**
  String get networkError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again'**
  String get loginFailed;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully.'**
  String get deleteSuccess;

  /// No description provided for @coachDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Coach deleted from all teams and authentication successfully.'**
  String get coachDeleteSuccess;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgainOrContact.
  ///
  /// In en, this message translates to:
  /// **'Please try again or contact support'**
  String get tryAgainOrContact;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @paymentOverview.
  ///
  /// In en, this message translates to:
  /// **'Payment Overview'**
  String get paymentOverview;

  /// No description provided for @unnamedPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Player'**
  String get unnamedPlayer;

  /// No description provided for @unnamedCoach.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Coach'**
  String get unnamedCoach;

  /// No description provided for @unnamedTeam.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Team'**
  String get unnamedTeam;

  /// No description provided for @coach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coach;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownTeam.
  ///
  /// In en, this message translates to:
  /// **'Unknown Team'**
  String get unknownTeam;

  /// No description provided for @receptionist.
  ///
  /// In en, this message translates to:
  /// **'Receptionist'**
  String get receptionist;

  /// No description provided for @noEmailForPlayer.
  ///
  /// In en, this message translates to:
  /// **'No email available for this player'**
  String get noEmailForPlayer;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @paymentReminderFor.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminder for {playerName}'**
  String paymentReminderFor(String playerName);

  /// No description provided for @dearParentGuardian.
  ///
  /// In en, this message translates to:
  /// **'Dear Parent/Guardian,'**
  String get dearParentGuardian;

  /// No description provided for @pleasePayEarliest.
  ///
  /// In en, this message translates to:
  /// **'Please make the payment at your earliest convenience.'**
  String get pleasePayEarliest;

  /// No description provided for @errorUpdatingPayment.
  ///
  /// In en, this message translates to:
  /// **'Error updating payment'**
  String get errorUpdatingPayment;

  /// No description provided for @paymentManagementFor.
  ///
  /// In en, this message translates to:
  /// **'{year} Payment Management'**
  String paymentManagementFor(String year);

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get adding;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @coachNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Coach name is required'**
  String get coachNameRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validEmailRequired;

  /// No description provided for @roleDescriptionMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Role description must be less than 100 characters'**
  String get roleDescriptionMaxLength;

  /// No description provided for @teamAssignment.
  ///
  /// In en, this message translates to:
  /// **'Team Assignment'**
  String get teamAssignment;

  /// No description provided for @selectTeamsToTrain.
  ///
  /// In en, this message translates to:
  /// **'Select teams this coach will train'**
  String get selectTeamsToTrain;

  /// No description provided for @assignedTeams.
  ///
  /// In en, this message translates to:
  /// **'Assigned Teams ({count})'**
  String assignedTeams(String count);

  /// No description provided for @many.
  ///
  /// In en, this message translates to:
  /// **'MANY'**
  String get many;

  /// No description provided for @addTeam.
  ///
  /// In en, this message translates to:
  /// **'Add Team'**
  String get addTeam;

  /// No description provided for @maximumTeamsAssigned.
  ///
  /// In en, this message translates to:
  /// **'Maximum teams assigned'**
  String get maximumTeamsAssigned;

  /// No description provided for @noTeamsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No teams available'**
  String get noTeamsAvailable;

  /// No description provided for @allTeamsAssigned.
  ///
  /// In en, this message translates to:
  /// **'All teams assigned'**
  String get allTeamsAssigned;

  /// No description provided for @loadingTeams.
  ///
  /// In en, this message translates to:
  /// **'Loading teams...'**
  String get loadingTeams;

  /// No description provided for @selectTeamToAdd.
  ///
  /// In en, this message translates to:
  /// **'Select Team to Add'**
  String get selectTeamToAdd;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @forTeam.
  ///
  /// In en, this message translates to:
  /// **'for {teamName}'**
  String forTeam(String teamName);

  /// No description provided for @coachOptionalAssignment.
  ///
  /// In en, this message translates to:
  /// **'Coach can be assigned to multiple teams (optional)'**
  String get coachOptionalAssignment;

  /// No description provided for @playerInformation.
  ///
  /// In en, this message translates to:
  /// **'Player Information'**
  String get playerInformation;

  /// No description provided for @enterPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Enter player name'**
  String get enterPlayerName;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select birth date'**
  String get selectBirthDate;

  /// No description provided for @enterPosition.
  ///
  /// In en, this message translates to:
  /// **'Enter position'**
  String get enterPosition;

  /// No description provided for @teamInformation.
  ///
  /// In en, this message translates to:
  /// **'Team Information'**
  String get teamInformation;

  /// No description provided for @teamNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Team name is required'**
  String get teamNameRequired;

  /// No description provided for @teamNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Team name must be at least 2 characters'**
  String get teamNameMinLength;

  /// No description provided for @teamNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Team name must be less than 30 characters'**
  String get teamNameMaxLength;

  /// No description provided for @teamDescription.
  ///
  /// In en, this message translates to:
  /// **'Team Description'**
  String get teamDescription;

  /// No description provided for @teamDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Team description is required'**
  String get teamDescriptionRequired;

  /// No description provided for @descriptionMinLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get descriptionMinLength;

  /// No description provided for @descriptionMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be less than 200 characters'**
  String get descriptionMaxLength;

  /// No description provided for @coachAssignment.
  ///
  /// In en, this message translates to:
  /// **'Coach Assignment'**
  String get coachAssignment;

  /// No description provided for @assignedCoaches.
  ///
  /// In en, this message translates to:
  /// **'Assigned Coaches ({count})'**
  String assignedCoaches(String count);

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get max;

  /// No description provided for @addCoach.
  ///
  /// In en, this message translates to:
  /// **'Add Coach'**
  String get addCoach;

  /// No description provided for @maximumCoachesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Maximum coaches assigned'**
  String get maximumCoachesAssigned;

  /// No description provided for @noCoachesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No coaches available'**
  String get noCoachesAvailable;

  /// No description provided for @allCoachesAssigned.
  ///
  /// In en, this message translates to:
  /// **'All coaches assigned'**
  String get allCoachesAssigned;

  /// No description provided for @loadingCoaches.
  ///
  /// In en, this message translates to:
  /// **'Loading coaches...'**
  String get loadingCoaches;

  /// No description provided for @selectCoachToAdd.
  ///
  /// In en, this message translates to:
  /// **'Select Coach to Add'**
  String get selectCoachToAdd;

  /// No description provided for @atLeastOneCoachRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one coach must be assigned to create a team'**
  String get atLeastOneCoachRequired;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @tapToSelectPicture.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle above to select a profile picture'**
  String get tapToSelectPicture;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @addNewCoach.
  ///
  /// In en, this message translates to:
  /// **'Add a new coach to the system'**
  String get addNewCoach;

  /// No description provided for @registerNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Register a new player'**
  String get registerNewPlayer;

  /// No description provided for @createNewTeam.
  ///
  /// In en, this message translates to:
  /// **'Create a new team'**
  String get createNewTeam;

  /// No description provided for @addNewEntry.
  ///
  /// In en, this message translates to:
  /// **'Add new entry'**
  String get addNewEntry;

  /// No description provided for @assignToTeam.
  ///
  /// In en, this message translates to:
  /// **'Assign to Team'**
  String get assignToTeam;

  /// No description provided for @passwordMinLengthSix.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLengthSix;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @imageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully!'**
  String get imageUploadedSuccessfully;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @coachAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Coach added successfully to {teamCount} team(s)!'**
  String coachAddedSuccessfully(String teamCount);

  /// No description provided for @coachAddedSuccessfullySimple.
  ///
  /// In en, this message translates to:
  /// **'Coach added successfully!'**
  String get coachAddedSuccessfullySimple;

  /// No description provided for @errorAddingCoach.
  ///
  /// In en, this message translates to:
  /// **'Error adding coach'**
  String get errorAddingCoach;

  /// No description provided for @pleaseSelectTeamForPlayer.
  ///
  /// In en, this message translates to:
  /// **'Please select a team for the player.'**
  String get pleaseSelectTeamForPlayer;

  /// No description provided for @playerAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Player added successfully!'**
  String get playerAddedSuccessfully;

  /// No description provided for @errorAddingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Error adding player'**
  String get errorAddingPlayer;

  /// No description provided for @atLeastOneCoachTeamRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one coach must be assigned to the team.'**
  String get atLeastOneCoachTeamRequired;

  /// No description provided for @teamCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Team \"{teamName}\" created with {coachCount} coach(es)!'**
  String teamCreatedSuccessfully(String teamName, String coachCount);

  /// No description provided for @failedToCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Failed to create team. Please try again.'**
  String get failedToCreateTeam;

  /// No description provided for @headCoach.
  ///
  /// In en, this message translates to:
  /// **'Head Coach'**
  String get headCoach;

  /// No description provided for @assistantCoach.
  ///
  /// In en, this message translates to:
  /// **'Assistant Coach'**
  String get assistantCoach;

  /// No description provided for @tacticsCoach.
  ///
  /// In en, this message translates to:
  /// **'Tactics Coach'**
  String get tacticsCoach;

  /// No description provided for @fitnessCoach.
  ///
  /// In en, this message translates to:
  /// **'Fitness Coach'**
  String get fitnessCoach;

  /// No description provided for @goalkeepingCoach.
  ///
  /// In en, this message translates to:
  /// **'Goalkeeping Coach'**
  String get goalkeepingCoach;

  /// No description provided for @youthCoach.
  ///
  /// In en, this message translates to:
  /// **'Youth Coach'**
  String get youthCoach;

  /// No description provided for @markPayment.
  ///
  /// In en, this message translates to:
  /// **'Mark Payment'**
  String get markPayment;

  /// No description provided for @recordPaymentFor.
  ///
  /// In en, this message translates to:
  /// **'Record a payment for {year}'**
  String recordPaymentFor(String year);

  /// No description provided for @selectPlayer.
  ///
  /// In en, this message translates to:
  /// **'Select Player'**
  String get selectPlayer;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @noFeeConfigured.
  ///
  /// In en, this message translates to:
  /// **'This team has no payment fee configured'**
  String get noFeeConfigured;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes or comments...'**
  String get optionalNotes;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @paymentFullyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment fully completed'**
  String get paymentFullyCompleted;

  /// No description provided for @partialPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Partial payment received'**
  String get partialPaymentReceived;

  /// No description provided for @noPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'No payment received'**
  String get noPaymentReceived;

  /// No description provided for @playerInactiveSuspended.
  ///
  /// In en, this message translates to:
  /// **'Player inactive/suspended'**
  String get playerInactiveSuspended;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @markAsPartial.
  ///
  /// In en, this message translates to:
  /// **'Mark as Partial'**
  String get markAsPartial;

  /// No description provided for @markAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unpaid'**
  String get markAsUnpaid;

  /// No description provided for @markAsInactive.
  ///
  /// In en, this message translates to:
  /// **'Mark as Inactive'**
  String get markAsInactive;

  /// No description provided for @paymentMarkedPaidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as PAID successfully!'**
  String get paymentMarkedPaidSuccess;

  /// No description provided for @paymentMarkedPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as PARTIAL successfully!'**
  String get paymentMarkedPartialSuccess;

  /// No description provided for @paymentMarkedUnpaidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as UNPAID successfully!'**
  String get paymentMarkedUnpaidSuccess;

  /// No description provided for @playerMarkedInactiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Player marked as INACTIVE successfully!'**
  String get playerMarkedInactiveSuccess;

  /// No description provided for @errorMarkingPayment.
  ///
  /// In en, this message translates to:
  /// **'Error marking payment'**
  String get errorMarkingPayment;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @playerInactiveMonths.
  ///
  /// In en, this message translates to:
  /// **'Player inactive for {months} months'**
  String playerInactiveMonths(String months);

  /// No description provided for @inactiveMonthsProgress.
  ///
  /// In en, this message translates to:
  /// **'Inactive ({months}/12 months)'**
  String inactiveMonthsProgress(String months);

  /// No description provided for @activeMonthsProgress.
  ///
  /// In en, this message translates to:
  /// **'{paid}/{total} active months'**
  String activeMonthsProgress(String paid, String total);

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @enterRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter role description...'**
  String get enterRoleDescription;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @loadingPaymentData.
  ///
  /// In en, this message translates to:
  /// **'Loading payment data...'**
  String get loadingPaymentData;

  /// No description provided for @noPaymentDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No payment data available'**
  String get noPaymentDataAvailable;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @allPlayers.
  ///
  /// In en, this message translates to:
  /// **'All Players'**
  String get allPlayers;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paymentActions.
  ///
  /// In en, this message translates to:
  /// **'Payment Actions'**
  String get paymentActions;

  /// No description provided for @recordNewPayment.
  ///
  /// In en, this message translates to:
  /// **'Record a new payment'**
  String get recordNewPayment;

  /// No description provided for @sendBulkPaymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Send bulk payment reminders'**
  String get sendBulkPaymentReminders;

  /// No description provided for @sendReminders.
  ///
  /// In en, this message translates to:
  /// **'Send Reminders'**
  String get sendReminders;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @downloadPaymentReport.
  ///
  /// In en, this message translates to:
  /// **'Download payment report'**
  String get downloadPaymentReport;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @clubOverviewToday.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your club overview for today'**
  String get clubOverviewToday;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @detailedBreakdownByMonth.
  ///
  /// In en, this message translates to:
  /// **'Detailed breakdown by month'**
  String get detailedBreakdownByMonth;

  /// No description provided for @teamReport.
  ///
  /// In en, this message translates to:
  /// **'Team Report'**
  String get teamReport;

  /// No description provided for @paymentStatusByTeam.
  ///
  /// In en, this message translates to:
  /// **'Payment status by team'**
  String get paymentStatusByTeam;

  /// No description provided for @overdueReport.
  ///
  /// In en, this message translates to:
  /// **'Overdue Report'**
  String get overdueReport;

  /// No description provided for @playersWithOutstandingPayments.
  ///
  /// In en, this message translates to:
  /// **'Players with outstanding payments'**
  String get playersWithOutstandingPayments;

  /// No description provided for @annualSummary.
  ///
  /// In en, this message translates to:
  /// **'Annual Summary'**
  String get annualSummary;

  /// No description provided for @completeYearOverview.
  ///
  /// In en, this message translates to:
  /// **'Complete year overview'**
  String get completeYearOverview;

  /// No description provided for @downloadCenter.
  ///
  /// In en, this message translates to:
  /// **'Download Center'**
  String get downloadCenter;

  /// No description provided for @noRecentDownloads.
  ///
  /// In en, this message translates to:
  /// **'No recent downloads'**
  String get noRecentDownloads;

  /// No description provided for @recentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Recent Downloads:'**
  String get recentDownloads;

  /// No description provided for @exportedReportsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your exported reports will be available here once generated. Currently, no downloads are available.'**
  String get exportedReportsAvailable;

  /// No description provided for @paymentReminderSent.
  ///
  /// In en, this message translates to:
  /// **'Payment reminder sent to {playerName}! Outstanding: {amount}'**
  String paymentReminderSent(String playerName, String amount);

  /// No description provided for @monthlyReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Monthly report generated successfully!'**
  String get monthlyReportGenerated;

  /// No description provided for @teamReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Team report generated successfully!'**
  String get teamReportGenerated;

  /// No description provided for @overdueReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Overdue report generated successfully!'**
  String get overdueReportGenerated;

  /// No description provided for @annualReportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Annual report generated successfully!'**
  String get annualReportGenerated;

  /// No description provided for @settingsScreen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreen;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profilePictureUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Picture'**
  String get profilePictureUpdate;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSelection.
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageSelection;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hungarian.
  ///
  /// In en, this message translates to:
  /// **'Magyar'**
  String get hungarian;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @hour12.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get hour12;

  /// No description provided for @hour24.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get hour24;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @paymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminders'**
  String get paymentReminders;

  /// No description provided for @newPlayerAlerts.
  ///
  /// In en, this message translates to:
  /// **'New Player Alerts'**
  String get newPlayerAlerts;

  /// No description provided for @systemUpdates.
  ///
  /// In en, this message translates to:
  /// **'System Updates'**
  String get systemUpdates;

  /// No description provided for @marketingEmails.
  ///
  /// In en, this message translates to:
  /// **'Marketing Emails'**
  String get marketingEmails;

  /// No description provided for @paymentPreferences.
  ///
  /// In en, this message translates to:
  /// **'Payment Preferences'**
  String get paymentPreferences;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// No description provided for @reminderFrequency.
  ///
  /// In en, this message translates to:
  /// **'Reminder Frequency'**
  String get reminderFrequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @securityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityPrivacy;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordRequirements;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @loginHistory.
  ///
  /// In en, this message translates to:
  /// **'Login History'**
  String get loginHistory;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @dataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get dataCollection;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @tutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get tutorials;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licenses;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @logoutAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Logout All Devices'**
  String get logoutAllDevices;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully!'**
  String get settingsSaved;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChanged;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully!'**
  String get languageChanged;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @confirmLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from all devices?'**
  String get confirmLogoutAll;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get confirmDeleteAccount;

  /// No description provided for @confirmResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to default?'**
  String get confirmResetSettings;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @immediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// No description provided for @after5Minutes.
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get after5Minutes;

  /// No description provided for @after15Minutes.
  ///
  /// In en, this message translates to:
  /// **'After 15 minutes'**
  String get after15Minutes;

  /// No description provided for @after30Minutes.
  ///
  /// In en, this message translates to:
  /// **'After 30 minutes'**
  String get after30Minutes;

  /// No description provided for @after1Hour.
  ///
  /// In en, this message translates to:
  /// **'After 1 hour'**
  String get after1Hour;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @enableDarkModeForApp.
  ///
  /// In en, this message translates to:
  /// **'Enable dark mode for the app'**
  String get enableDarkModeForApp;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get languageAndRegion;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// No description provided for @addExtraSecurityLayer.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get addExtraSecurityLayer;

  /// No description provided for @updateAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateAccountPassword;

  /// No description provided for @manageDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Manage your data privacy'**
  String get manageDataPrivacy;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About This App'**
  String get aboutThisApp;

  /// No description provided for @currentAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Current app version'**
  String get currentAppVersion;

  /// No description provided for @readTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get readTermsOfService;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// No description provided for @viewOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'View open source licenses'**
  String get viewOpenSourceLicenses;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @userAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User added successfully!'**
  String get userAddedSuccessfully;

  /// No description provided for @userUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully!'**
  String get userUpdatedSuccessfully;

  /// No description provided for @userDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully!'**
  String get userDeletedSuccessfully;

  /// No description provided for @errorAddingUser.
  ///
  /// In en, this message translates to:
  /// **'Error adding user'**
  String get errorAddingUser;

  /// No description provided for @errorUpdatingUser.
  ///
  /// In en, this message translates to:
  /// **'Error updating user'**
  String get errorUpdatingUser;

  /// No description provided for @errorDeletingUser.
  ///
  /// In en, this message translates to:
  /// **'Error deleting user'**
  String get errorDeletingUser;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deleteUserWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get deleteUserWarning;

  /// No description provided for @deleteUserDescription.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All user data will be permanently deleted.'**
  String get deleteUserDescription;

  /// No description provided for @leaveEmptyToKeep.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep current password'**
  String get leaveEmptyToKeep;

  /// No description provided for @sessionReport.
  ///
  /// In en, this message translates to:
  /// **'Session Report'**
  String get sessionReport;

  /// No description provided for @attendanceInformation.
  ///
  /// In en, this message translates to:
  /// **'Attendance Information'**
  String get attendanceInformation;

  /// No description provided for @trainingHistory.
  ///
  /// In en, this message translates to:
  /// **'Training History'**
  String get trainingHistory;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @playerName.
  ///
  /// In en, this message translates to:
  /// **'Player Name'**
  String get playerName;

  /// No description provided for @numberOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'Number of Players'**
  String get numberOfPlayers;

  /// No description provided for @sessionDate.
  ///
  /// In en, this message translates to:
  /// **'Session Date'**
  String get sessionDate;

  /// No description provided for @attendanceList.
  ///
  /// In en, this message translates to:
  /// **'Attendance List'**
  String get attendanceList;

  /// No description provided for @presentPlayers.
  ///
  /// In en, this message translates to:
  /// **'Present Players'**
  String get presentPlayers;

  /// No description provided for @absentPlayers.
  ///
  /// In en, this message translates to:
  /// **'Absent Players'**
  String get absentPlayers;

  /// No description provided for @systemNotifications.
  ///
  /// In en, this message translates to:
  /// **'System Notifications'**
  String get systemNotifications;

  /// No description provided for @securityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get securityAlerts;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @organizationSetup.
  ///
  /// In en, this message translates to:
  /// **'Organization Setup'**
  String get organizationSetup;

  /// No description provided for @stepBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get stepBasicInfo;

  /// No description provided for @stepAdminUser.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get stepAdminUser;

  /// No description provided for @stepTeamSetup.
  ///
  /// In en, this message translates to:
  /// **'Team Setup'**
  String get stepTeamSetup;

  /// No description provided for @stepPaymentConfig.
  ///
  /// In en, this message translates to:
  /// **'Payment Configuration'**
  String get stepPaymentConfig;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review & Complete'**
  String get stepReview;

  /// No description provided for @organizationName.
  ///
  /// In en, this message translates to:
  /// **'Organization Name'**
  String get organizationName;

  /// No description provided for @organizationAddress.
  ///
  /// In en, this message translates to:
  /// **'Organization Address'**
  String get organizationAddress;

  /// No description provided for @organizationType.
  ///
  /// In en, this message translates to:
  /// **'Organization Type'**
  String get organizationType;

  /// No description provided for @selectOrgType.
  ///
  /// In en, this message translates to:
  /// **'Select organization type'**
  String get selectOrgType;

  /// No description provided for @club.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get club;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @academy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get academy;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @adminSetup.
  ///
  /// In en, this message translates to:
  /// **'Administrator Setup'**
  String get adminSetup;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Administrator Name'**
  String get adminName;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Administrator Email'**
  String get adminEmail;

  /// No description provided for @adminPassword.
  ///
  /// In en, this message translates to:
  /// **'Administrator Password'**
  String get adminPassword;

  /// No description provided for @createAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Create administrator account'**
  String get createAdminAccount;

  /// No description provided for @teamSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Initial Teams'**
  String get teamSetupTitle;

  /// No description provided for @addTeamsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add teams and sample players to get started'**
  String get addTeamsDescription;

  /// No description provided for @enterTeamName.
  ///
  /// In en, this message translates to:
  /// **'Enter team name'**
  String get enterTeamName;

  /// No description provided for @addSamplePlayers.
  ///
  /// In en, this message translates to:
  /// **'Add sample players'**
  String get addSamplePlayers;

  /// No description provided for @samplesPerTeam.
  ///
  /// In en, this message translates to:
  /// **'players per team'**
  String get samplesPerTeam;

  /// No description provided for @paymentConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Payment Configuration'**
  String get paymentConfiguration;

  /// No description provided for @defaultMonthlyFee.
  ///
  /// In en, this message translates to:
  /// **'Default Monthly Fee'**
  String get defaultMonthlyFee;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get selectCurrency;

  /// No description provided for @paymentDueDay.
  ///
  /// In en, this message translates to:
  /// **'Payment Due Day'**
  String get paymentDueDay;

  /// No description provided for @dueDayDescription.
  ///
  /// In en, this message translates to:
  /// **'Day of the month when payments are due'**
  String get dueDayDescription;

  /// No description provided for @reviewAndComplete.
  ///
  /// In en, this message translates to:
  /// **'Review & Complete'**
  String get reviewAndComplete;

  /// No description provided for @setupSummary.
  ///
  /// In en, this message translates to:
  /// **'Setup Summary'**
  String get setupSummary;

  /// No description provided for @reviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Review your organization details below'**
  String get reviewDetails;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// No description provided for @backToPrevious.
  ///
  /// In en, this message translates to:
  /// **'Back to Previous'**
  String get backToPrevious;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @setupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup in Progress...'**
  String get setupInProgress;

  /// No description provided for @creatingOrganization.
  ///
  /// In en, this message translates to:
  /// **'Creating organization...'**
  String get creatingOrganization;

  /// No description provided for @creatingAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating admin account...'**
  String get creatingAdminAccount;

  /// No description provided for @settingUpTeams.
  ///
  /// In en, this message translates to:
  /// **'Setting up teams...'**
  String get settingUpTeams;

  /// No description provided for @configuringPayments.
  ///
  /// In en, this message translates to:
  /// **'Configuring payments...'**
  String get configuringPayments;

  /// No description provided for @finalizingSetup.
  ///
  /// In en, this message translates to:
  /// **'Finalizing setup...'**
  String get finalizingSetup;

  /// No description provided for @setupCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Complete!'**
  String get setupCompleteTitle;

  /// No description provided for @setupCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your organization has been successfully created'**
  String get setupCompleteMessage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @setupError.
  ///
  /// In en, this message translates to:
  /// **'Setup Error'**
  String get setupError;

  /// No description provided for @setupErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during setup. Please try again.'**
  String get setupErrorMessage;

  /// No description provided for @contactSupportIfPersists.
  ///
  /// In en, this message translates to:
  /// **'Contact support if this error persists.'**
  String get contactSupportIfPersists;

  /// No description provided for @processingRequest.
  ///
  /// In en, this message translates to:
  /// **'Processing request...'**
  String get processingRequest;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @almostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done...'**
  String get almostDone;

  /// No description provided for @demoOrganization.
  ///
  /// In en, this message translates to:
  /// **'Demo Organization'**
  String get demoOrganization;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoMode;

  /// No description provided for @demoDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This is demo data. Changes will not be saved permanently.'**
  String get demoDataWarning;

  /// No description provided for @cleanupDemoData.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Demo Data'**
  String get cleanupDemoData;

  /// No description provided for @cleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all demo organizations older than 24 hours'**
  String get cleanupDescription;

  /// No description provided for @performCleanup.
  ///
  /// In en, this message translates to:
  /// **'Perform Cleanup'**
  String get performCleanup;

  /// No description provided for @cleanupComplete.
  ///
  /// In en, this message translates to:
  /// **'Cleanup complete'**
  String get cleanupComplete;

  /// No description provided for @noOldDemoData.
  ///
  /// In en, this message translates to:
  /// **'No old demo data found to cleanup'**
  String get noOldDemoData;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionLost;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @offlineChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes will be synced when connection is restored'**
  String get offlineChanges;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation Error'**
  String get validationError;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidFormat;

  /// No description provided for @mustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a valid number'**
  String get mustBeNumber;

  /// No description provided for @mustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Must be a positive number'**
  String get mustBePositive;

  /// No description provided for @tooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get tooShort;

  /// No description provided for @tooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get tooLong;

  /// No description provided for @organizationExists.
  ///
  /// In en, this message translates to:
  /// **'Organization with this name already exists'**
  String get organizationExists;

  /// No description provided for @emailTaken.
  ///
  /// In en, this message translates to:
  /// **'Email address is already taken'**
  String get emailTaken;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get weakPassword;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @organizationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Organization name is too short'**
  String get organizationNameTooShort;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @loadingOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Loading organizations...'**
  String get loadingOrganizations;

  /// No description provided for @selectExistingOrg.
  ///
  /// In en, this message translates to:
  /// **'Select existing organization'**
  String get selectExistingOrg;

  /// No description provided for @createNewOrg.
  ///
  /// In en, this message translates to:
  /// **'Create new organization'**
  String get createNewOrg;

  /// No description provided for @joinOrganization.
  ///
  /// In en, this message translates to:
  /// **'Join Organization'**
  String get joinOrganization;

  /// No description provided for @switchOrganization.
  ///
  /// In en, this message translates to:
  /// **'Switch Organization'**
  String get switchOrganization;

  /// No description provided for @noOrganizationAccess.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to any organizations'**
  String get noOrganizationAccess;

  /// No description provided for @resumeSetup.
  ///
  /// In en, this message translates to:
  /// **'Resume Setup'**
  String get resumeSetup;

  /// No description provided for @continueSetup.
  ///
  /// In en, this message translates to:
  /// **'Continue Setup'**
  String get continueSetup;

  /// No description provided for @startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get startFresh;

  /// No description provided for @setupInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Your setup was interrupted'**
  String get setupInterrupted;

  /// No description provided for @resumeFromStep.
  ///
  /// In en, this message translates to:
  /// **'Resume from step {stepNumber}'**
  String resumeFromStep(String stepNumber);

  /// No description provided for @abandonSetup.
  ///
  /// In en, this message translates to:
  /// **'Abandon Setup'**
  String get abandonSetup;

  /// No description provided for @networkTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Network timeout. Please check your connection.'**
  String get networkTimeoutError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @rateLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait before trying again.'**
  String get rateLimitExceeded;

  /// No description provided for @operationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Operation was cancelled'**
  String get operationCancelled;

  /// No description provided for @batchOperationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Batch operation in progress...'**
  String get batchOperationInProgress;

  /// No description provided for @processingItems.
  ///
  /// In en, this message translates to:
  /// **'Processing {current} of {total} items...'**
  String processingItems(String current, String total);

  /// No description provided for @teamReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Report'**
  String get teamReportTitle;

  /// No description provided for @teamDetails.
  ///
  /// In en, this message translates to:
  /// **'Team Details'**
  String get teamDetails;

  /// No description provided for @positionDistribution.
  ///
  /// In en, this message translates to:
  /// **'Position Distribution'**
  String get positionDistribution;

  /// No description provided for @teamPlayers.
  ///
  /// In en, this message translates to:
  /// **'Team Players'**
  String get teamPlayers;

  /// No description provided for @teamPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'Team Players ({count})'**
  String teamPlayersCount(String count);

  /// No description provided for @goalkeeper.
  ///
  /// In en, this message translates to:
  /// **'Goalkeeper'**
  String get goalkeeper;

  /// No description provided for @defender.
  ///
  /// In en, this message translates to:
  /// **'Defender'**
  String get defender;

  /// No description provided for @midfielder.
  ///
  /// In en, this message translates to:
  /// **'Midfielder'**
  String get midfielder;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @averageAge.
  ///
  /// In en, this message translates to:
  /// **'Average Age'**
  String get averageAge;

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found for this team.'**
  String get noPlayersFound;

  /// No description provided for @loadingTeamDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading team details...'**
  String get loadingTeamDetails;

  /// No description provided for @loadingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Loading players...'**
  String get loadingPlayers;

  /// No description provided for @calculatingStatistics.
  ///
  /// In en, this message translates to:
  /// **'Calculating statistics...'**
  String get calculatingStatistics;

  /// No description provided for @errorLoadingTeamData.
  ///
  /// In en, this message translates to:
  /// **'Error loading team data'**
  String get errorLoadingTeamData;

  /// No description provided for @errorLoadingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Error loading team players'**
  String get errorLoadingPlayers;

  /// No description provided for @pdfSuccessfullyGenerated.
  ///
  /// In en, this message translates to:
  /// **'PDF successfully generated!'**
  String get pdfSuccessfullyGenerated;

  /// No description provided for @errorGeneratingPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF report: {error}'**
  String errorGeneratingPdfReport(String error);

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @unknownPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unknown Player'**
  String get unknownPlayer;

  /// No description provided for @cannotLoadPlayerDetails.
  ///
  /// In en, this message translates to:
  /// **'Cannot load details: Missing player ID.'**
  String get cannotLoadPlayerDetails;

  /// No description provided for @loadingPlayerDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading player details...'**
  String get loadingPlayerDetails;

  /// No description provided for @playerDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player details not found.'**
  String get playerDetailsNotFound;

  /// No description provided for @errorLoadingPlayerDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading player details.'**
  String get errorLoadingPlayerDetails;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @updateCloseSession.
  ///
  /// In en, this message translates to:
  /// **'Update & Close Session'**
  String get updateCloseSession;

  /// No description provided for @trainingActive.
  ///
  /// In en, this message translates to:
  /// **'Training Active'**
  String get trainingActive;

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String endsAt(String time);

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @manageYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile'**
  String get manageYourProfile;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get callSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @getHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help & support'**
  String get getHelpSupport;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get appInformation;

  /// No description provided for @signOutAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutAccount;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get confirmSignOut;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @nameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// No description provided for @emailField.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailField;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @trainingTypeGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get trainingTypeGame;

  /// No description provided for @trainingTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get trainingTypeTraining;

  /// No description provided for @trainingTypeTactical.
  ///
  /// In en, this message translates to:
  /// **'Tactical'**
  String get trainingTypeTactical;

  /// No description provided for @trainingTypeFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get trainingTypeFitness;

  /// No description provided for @trainingTypeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get trainingTypeTechnical;

  /// No description provided for @trainingTypeTheoretical.
  ///
  /// In en, this message translates to:
  /// **'Theoretical'**
  String get trainingTypeTheoretical;

  /// No description provided for @trainingTypeSurvey.
  ///
  /// In en, this message translates to:
  /// **'Survey'**
  String get trainingTypeSurvey;

  /// No description provided for @trainingTypeMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get trainingTypeMixed;

  /// No description provided for @trainingDescGame.
  ///
  /// In en, this message translates to:
  /// **'Official or practice matches against other teams'**
  String get trainingDescGame;

  /// No description provided for @trainingDescTraining.
  ///
  /// In en, this message translates to:
  /// **'General training with skill development and conditioning'**
  String get trainingDescTraining;

  /// No description provided for @trainingDescTactical.
  ///
  /// In en, this message translates to:
  /// **'Tactical formations, strategies, and team play practice'**
  String get trainingDescTactical;

  /// No description provided for @trainingDescFitness.
  ///
  /// In en, this message translates to:
  /// **'Conditioning workouts, strength training, and endurance building'**
  String get trainingDescFitness;

  /// No description provided for @trainingDescTechnical.
  ///
  /// In en, this message translates to:
  /// **'Individual technical skills: dribbling, shooting, passing'**
  String get trainingDescTechnical;

  /// No description provided for @trainingDescTheoretical.
  ///
  /// In en, this message translates to:
  /// **'Tactical discussions, game rules, and strategic planning'**
  String get trainingDescTheoretical;

  /// No description provided for @trainingDescSurvey.
  ///
  /// In en, this message translates to:
  /// **'Player assessments, testing, and skill evaluations'**
  String get trainingDescSurvey;

  /// No description provided for @trainingDescMixed.
  ///
  /// In en, this message translates to:
  /// **'Combined training with elements from multiple types'**
  String get trainingDescMixed;

  /// No description provided for @unknownCoachName.
  ///
  /// In en, this message translates to:
  /// **'Unknown Coach'**
  String get unknownCoachName;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @trainingSessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Training session saved! You can edit it once more.'**
  String get trainingSessionSaved;

  /// No description provided for @errorLoadingTeams.
  ///
  /// In en, this message translates to:
  /// **'Error loading teams'**
  String get errorLoadingTeams;

  /// No description provided for @noTeamsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No teams assigned'**
  String get noTeamsAssigned;

  /// No description provided for @trainingEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String trainingEndsAt(String time);

  /// No description provided for @noPlayersFoundInTeam.
  ///
  /// In en, this message translates to:
  /// **'No players found in this team'**
  String get noPlayersFoundInTeam;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @coachRole.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachRole;

  /// No description provided for @callPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Call: {phoneNumber}\nTap phone number to copy and dial'**
  String callPhoneNumber(String phoneNumber);

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}\nTap email to copy and send'**
  String emailAddress(String email);

  /// No description provided for @themeSettingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettingsComingSoon;

  /// No description provided for @darkModeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Dark mode and theme customization options will be available soon.'**
  String get darkModeComingSoon;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {languageName}'**
  String languageChangedTo(String languageName);

  /// No description provided for @helpSupportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help & Support coming soon'**
  String get helpSupportComingSoon;

  /// No description provided for @footballTrainingApp.
  ///
  /// In en, this message translates to:
  /// **'FootballTraining App'**
  String get footballTrainingApp;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: 1.0.0'**
  String get versionLabel;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive football training management system.'**
  String get appDescription;

  /// No description provided for @uploadTimeout.
  ///
  /// In en, this message translates to:
  /// **'Upload timeout. Please check your connection.'**
  String get uploadTimeout;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated or organization not initialized'**
  String get userNotAuthenticated;

  /// No description provided for @currentPasswordRequiredForChanges.
  ///
  /// In en, this message translates to:
  /// **'Current password is required for email or password changes'**
  String get currentPasswordRequiredForChanges;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordLabel;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @profileManagement.
  ///
  /// In en, this message translates to:
  /// **'Profile Management'**
  String get profileManagement;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and Support'**
  String get helpAndSupport;

  /// No description provided for @applicationInfo.
  ///
  /// In en, this message translates to:
  /// **'Application Information'**
  String get applicationInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
