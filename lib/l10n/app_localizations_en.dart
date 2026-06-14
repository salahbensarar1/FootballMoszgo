// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Football Training';

  @override
  String get login => 'Login';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get adminManagement => 'Admin Management';

  @override
  String get createNewOrganization => 'Create New Organization';

  @override
  String get adminScreen => 'Admin Screen';

  @override
  String get coachScreen => 'Coach Screen';

  @override
  String get receptionistScreen => 'Receptionist Screen';

  @override
  String get dashboardOverview => 'Dashboard Overview';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get coaches => 'Coaches';

  @override
  String get players => 'Players';

  @override
  String get teams => 'Teams';

  @override
  String get attendances => 'Attendances';

  @override
  String searchHint(String entity) {
    return 'Search $entity...';
  }

  @override
  String addEntity(String entity) {
    return 'Add $entity';
  }

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get playerInfo => 'Player Info';

  @override
  String get payments => 'Payments';

  @override
  String get paymentProgress => 'Payment Progress';

  @override
  String get viewDetails => 'View Details';

  @override
  String get sendReminder => 'Send Reminder';

  @override
  String get fullyPaid => 'Fully Paid';

  @override
  String get partial => 'Partial';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get notActive => 'Not Active';

  @override
  String get monthlyCollectionTrend => 'Monthly Collection Trend';

  @override
  String get totalCollected => 'Total Collected';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get paidPlayers => 'Paid Players';

  @override
  String get thisMonth => 'This Month';

  @override
  String noEntitiesFound(String entity) {
    return 'No $entity found';
  }

  @override
  String addSomeEntities(String entity) {
    return 'Add some $entity to get started';
  }

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get tryAdjustingSearch => 'Try adjusting your search terms';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get teamName => 'Team Name';

  @override
  String get name => 'Name';

  @override
  String get roleDescription => 'Role Description';

  @override
  String get coachesManagement => 'Coaches Management';

  @override
  String get manageTeamCoaches => 'Manage Team Coaches';

  @override
  String get assignMultipleCoaches =>
      'Assign multiple coaches with different roles';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this item? This action cannot be undone.';

  @override
  String editEntity(String entity) {
    return 'Edit $entity';
  }

  @override
  String get successfullyUpdated => 'Successfully updated';

  @override
  String failedToUpdate(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get coachDeletedSuccessfully =>
      'Coach deleted from all teams and authentication successfully';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMayFull => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get sendReminderButton => 'Send Reminder';

  @override
  String get playerNotFound => 'Player not found';

  @override
  String get noEmailAvailable => 'No email available for this player';

  @override
  String get allMonthsPaid => 'All months are paid!';

  @override
  String get paymentReminderEmail => 'Payment Reminder Email';

  @override
  String emailTo(String email) {
    return 'To: $email';
  }

  @override
  String emailSubject(String playerName) {
    return 'Subject: Payment Reminder for $playerName';
  }

  @override
  String get dearParent => 'Dear Parent/Guardian,';

  @override
  String get reminderUnpaidMonths =>
      'This is a reminder that the following months are unpaid:';

  @override
  String get pleasePayConvenience =>
      'Please make the payment at your earliest convenience.';

  @override
  String get thankYou => 'Thank you,';

  @override
  String get footballClubManagement => 'Football Club Management';

  @override
  String get close => 'Close';

  @override
  String get sendEmail => 'Send Email';

  @override
  String emailSentTo(String email) {
    return 'Email sent to $email';
  }

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String paymentManagement(String year) {
    return '$year Payment Management';
  }

  @override
  String get paymentReminder => 'Payment Reminder';

  @override
  String get position => 'Position';

  @override
  String get team => 'Team';

  @override
  String get selectTeam => 'Select Team';

  @override
  String get assignCoach => 'Assign Coach';

  @override
  String get trainingType => 'Training Type';

  @override
  String get pitchLocation => 'Pitch Location';

  @override
  String get startTraining => 'Start Training (2-hour window)';

  @override
  String get saveSession => 'Save Session';

  @override
  String get failedToSendEmail => 'Failed to send email. Please try again.';

  @override
  String get totalPlayers => 'Total Players';

  @override
  String get totalTeams => 'Total Teams';

  @override
  String get activeCoaches => 'Active Coaches';

  @override
  String get keyStatistics => 'Key Statistics';

  @override
  String get recentTrainingSessions => 'Recent Training Sessions';

  @override
  String get playerDetails => 'Player Details';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get lastSession => 'Last Session';

  @override
  String get status => 'Status';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get sessionStart => 'Session Start';

  @override
  String get sessionEnd => 'Session End';

  @override
  String get trainingSummary => 'Training Summary';

  @override
  String get noTrainingRecorded => 'No training recorded';

  @override
  String get playerReport => 'Player Report';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get attendanceInfo => 'Attendance Information';

  @override
  String get statistics => 'Statistics';

  @override
  String get totalMinutes => 'Total Minutes';

  @override
  String get sessionsAttended => 'Sessions Attended';

  @override
  String get attendanceRate => 'Attendance Rate';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get pdfGenerationError => 'PDF generation error';

  @override
  String get pdfGeneratedSuccess => 'PDF generated successfully';

  @override
  String get noImage => 'No Image';

  @override
  String get loadError => 'Load Error';

  @override
  String get minutes => 'minutes';

  @override
  String get sessions => 'sessions';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get backToList => 'Back to List';

  @override
  String get noTeamAssigned => 'No Team Assigned';

  @override
  String get editFunctionality => 'Edit functionality coming soon';

  @override
  String get userNotFound => 'No user found with this email';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get userDisabled => 'Account has been disabled';

  @override
  String get tooManyRequests => 'Too many login attempts. Try again later';

  @override
  String get networkError => 'Network error. Check your connection';

  @override
  String get loginFailed => 'Login failed. Please try again';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get loading => 'Loading...';

  @override
  String get refresh => 'Refresh';

  @override
  String get comingSoon => 'Coming Soon!';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get deleteSuccess => 'Deleted successfully.';

  @override
  String get coachDeleteSuccess =>
      'Coach deleted from all teams and authentication successfully.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgainOrContact => 'Please try again or contact support';

  @override
  String get retry => 'Retry';

  @override
  String get paymentOverview => 'Payment Overview';

  @override
  String get unnamedPlayer => 'Unnamed Player';

  @override
  String get unnamedCoach => 'Unnamed Coach';

  @override
  String get unnamedTeam => 'Unnamed Team';

  @override
  String get coach => 'Coach';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownTeam => 'Unknown Team';

  @override
  String get receptionist => 'Receptionist';

  @override
  String get noEmailForPlayer => 'No email available for this player';

  @override
  String get to => 'To';

  @override
  String get subject => 'Subject';

  @override
  String paymentReminderFor(String playerName) {
    return 'Payment Reminder for $playerName';
  }

  @override
  String get dearParentGuardian => 'Dear Parent/Guardian,';

  @override
  String get pleasePayEarliest =>
      'Please make the payment at your earliest convenience.';

  @override
  String get errorUpdatingPayment => 'Error updating payment';

  @override
  String paymentManagementFor(String year) {
    return '$year Payment Management';
  }

  @override
  String get adding => 'Adding...';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get coachNameRequired => 'Coach name is required';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmailRequired => 'Enter a valid email address';

  @override
  String get roleDescriptionMaxLength =>
      'Role description must be less than 100 characters';

  @override
  String get teamAssignment => 'Team Assignment';

  @override
  String get selectTeamsToTrain => 'Select teams this coach will train';

  @override
  String assignedTeams(String count) {
    return 'Assigned Teams ($count)';
  }

  @override
  String get many => 'MANY';

  @override
  String get addTeam => 'Add Team';

  @override
  String get maximumTeamsAssigned => 'Maximum teams assigned';

  @override
  String get noTeamsAvailable => 'No teams available';

  @override
  String get allTeamsAssigned => 'All teams assigned';

  @override
  String get loadingTeams => 'Loading teams...';

  @override
  String get selectTeamToAdd => 'Select Team to Add';

  @override
  String get selectRole => 'Select Role';

  @override
  String forTeam(String teamName) {
    return 'for $teamName';
  }

  @override
  String get coachOptionalAssignment =>
      'Coach can be assigned to multiple teams (optional)';

  @override
  String get playerInformation => 'Player Information';

  @override
  String get enterPlayerName => 'Enter player name';

  @override
  String get selectBirthDate => 'Select birth date';

  @override
  String get enterPosition => 'Enter position';

  @override
  String get teamInformation => 'Team Information';

  @override
  String get teamNameRequired => 'Team name is required';

  @override
  String get teamNameMinLength => 'Team name must be at least 2 characters';

  @override
  String get teamNameMaxLength => 'Team name must be less than 30 characters';

  @override
  String get teamDescription => 'Team Description';

  @override
  String get teamDescriptionRequired => 'Team description is required';

  @override
  String get descriptionMinLength =>
      'Description must be at least 10 characters';

  @override
  String get descriptionMaxLength =>
      'Description must be less than 200 characters';

  @override
  String get coachAssignment => 'Coach Assignment';

  @override
  String assignedCoaches(String count) {
    return 'Assigned Coaches ($count)';
  }

  @override
  String get max => 'MAX';

  @override
  String get addCoach => 'Add Coach';

  @override
  String get maximumCoachesAssigned => 'Maximum coaches assigned';

  @override
  String get noCoachesAvailable => 'No coaches available';

  @override
  String get allCoachesAssigned => 'All coaches assigned';

  @override
  String get loadingCoaches => 'Loading coaches...';

  @override
  String get selectCoachToAdd => 'Select Coach to Add';

  @override
  String get atLeastOneCoachRequired =>
      'At least one coach must be assigned to create a team';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get tapToSelectPicture =>
      'Tap the circle above to select a profile picture';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get uploading => 'Uploading...';

  @override
  String get addNewCoach => 'Add a new coach to the system';

  @override
  String get registerNewPlayer => 'Register a new player';

  @override
  String get createNewTeam => 'Create a new team';

  @override
  String get addNewEntry => 'Add new entry';

  @override
  String get assignToTeam => 'Assign to Team';

  @override
  String get passwordMinLengthSix => 'Password must be at least 6 characters';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get imageUploadedSuccessfully => 'Image uploaded successfully!';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String coachAddedSuccessfully(String teamCount) {
    return 'Coach added successfully to $teamCount team(s)!';
  }

  @override
  String get coachAddedSuccessfullySimple => 'Coach added successfully!';

  @override
  String get errorAddingCoach => 'Error adding coach';

  @override
  String get pleaseSelectTeamForPlayer =>
      'Please select a team for the player.';

  @override
  String get playerAddedSuccessfully => 'Player added successfully!';

  @override
  String get errorAddingPlayer => 'Error adding player';

  @override
  String get atLeastOneCoachTeamRequired =>
      'At least one coach must be assigned to the team.';

  @override
  String teamCreatedSuccessfully(String teamName, String coachCount) {
    return 'Team \"$teamName\" created with $coachCount coach(es)!';
  }

  @override
  String get failedToCreateTeam => 'Failed to create team. Please try again.';

  @override
  String get headCoach => 'Head Coach';

  @override
  String get assistantCoach => 'Assistant Coach';

  @override
  String get tacticsCoach => 'Tactics Coach';

  @override
  String get fitnessCoach => 'Fitness Coach';

  @override
  String get goalkeepingCoach => 'Goalkeeping Coach';

  @override
  String get youthCoach => 'Youth Coach';

  @override
  String get markPayment => 'Mark Payment';

  @override
  String recordPaymentFor(String year) {
    return 'Record a payment for $year';
  }

  @override
  String get selectPlayer => 'Select Player';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get paymentSummary => 'Payment Summary';

  @override
  String get year => 'Year';

  @override
  String get month => 'month';

  @override
  String get amount => 'Amount';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get noFeeConfigured => 'This team has no payment fee configured';

  @override
  String get notes => 'Notes';

  @override
  String get optionalNotes => 'Optional notes or comments...';

  @override
  String get partiallyPaid => 'Partially Paid';

  @override
  String get inactive => 'Inactive';

  @override
  String get paymentFullyCompleted => 'Payment fully completed';

  @override
  String get partialPaymentReceived => 'Partial payment received';

  @override
  String get noPaymentReceived => 'No payment received';

  @override
  String get playerInactiveSuspended => 'Player inactive/suspended';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get markAsPartial => 'Mark as Partial';

  @override
  String get markAsUnpaid => 'Mark as Unpaid';

  @override
  String get markAsInactive => 'Mark as Inactive';

  @override
  String get paymentMarkedPaidSuccess => 'Payment marked as PAID successfully!';

  @override
  String get paymentMarkedPartialSuccess =>
      'Payment marked as PARTIAL successfully!';

  @override
  String get paymentMarkedUnpaidSuccess =>
      'Payment marked as UNPAID successfully!';

  @override
  String get playerMarkedInactiveSuccess =>
      'Player marked as INACTIVE successfully!';

  @override
  String get errorMarkingPayment => 'Error marking payment';

  @override
  String get activate => 'Activate';

  @override
  String playerInactiveMonths(String months) {
    return 'Player inactive for $months months';
  }

  @override
  String inactiveMonthsProgress(String months) {
    return 'Inactive ($months/12 months)';
  }

  @override
  String activeMonthsProgress(String paid, String total) {
    return '$paid/$total active months';
  }

  @override
  String get editUser => 'Edit User';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get role => 'Role';

  @override
  String get enterRoleDescription => 'Enter role description...';

  @override
  String get updating => 'Updating...';

  @override
  String get admin => 'Admin';

  @override
  String get loadingPaymentData => 'Loading payment data...';

  @override
  String get noPaymentDataAvailable => 'No payment data available';

  @override
  String get filter => 'Filter';

  @override
  String get allPlayers => 'All Players';

  @override
  String get overview => 'Overview';

  @override
  String get reports => 'Reports';

  @override
  String get months => 'months';

  @override
  String get paid => 'Paid';

  @override
  String get paymentActions => 'Payment Actions';

  @override
  String get recordNewPayment => 'Record a new payment';

  @override
  String get sendBulkPaymentReminders => 'Send bulk payment reminders';

  @override
  String get sendReminders => 'Send Reminders';

  @override
  String get exportData => 'Export Data';

  @override
  String get downloadPaymentReport => 'Download payment report';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get clubOverviewToday => 'Here\'s your club overview for today';

  @override
  String get exportReport => 'Export Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get detailedBreakdownByMonth => 'Detailed breakdown by month';

  @override
  String get teamReport => 'Team Report';

  @override
  String get paymentStatusByTeam => 'Payment status by team';

  @override
  String get overdueReport => 'Overdue Report';

  @override
  String get playersWithOutstandingPayments =>
      'Players with outstanding payments';

  @override
  String get annualSummary => 'Annual Summary';

  @override
  String get completeYearOverview => 'Complete year overview';

  @override
  String get downloadCenter => 'Download Center';

  @override
  String get noRecentDownloads => 'No recent downloads';

  @override
  String get recentDownloads => 'Recent Downloads:';

  @override
  String get exportedReportsAvailable =>
      'Your exported reports will be available here once generated. Currently, no downloads are available.';

  @override
  String paymentReminderSent(String playerName, String amount) {
    return 'Payment reminder sent to $playerName! Outstanding: $amount';
  }

  @override
  String get monthlyReportGenerated => 'Monthly report generated successfully!';

  @override
  String get teamReportGenerated => 'Team report generated successfully!';

  @override
  String get overdueReportGenerated => 'Overdue report generated successfully!';

  @override
  String get annualReportGenerated => 'Annual report generated successfully!';

  @override
  String get settingsScreen => 'Settings';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get changePassword => 'Change Password';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profilePictureUpdate => 'Update Profile Picture';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get language => 'Language';

  @override
  String get languageSelection => 'Language Selection';

  @override
  String get english => 'English';

  @override
  String get hungarian => 'Magyar';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get hour12 => '12-hour';

  @override
  String get hour24 => '24-hour';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get paymentReminders => 'Payment Reminders';

  @override
  String get newPlayerAlerts => 'New Player Alerts';

  @override
  String get systemUpdates => 'System Updates';

  @override
  String get marketingEmails => 'Marketing Emails';

  @override
  String get paymentPreferences => 'Payment Preferences';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get reminderFrequency => 'Reminder Frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get securityPrivacy => 'Security & Privacy';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordRequirements => 'Password must be at least 8 characters';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get loginHistory => 'Login History';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get dataCollection => 'Data Collection';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get tutorials => 'Tutorials';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get featureRequest => 'Feature Request';

  @override
  String get documentation => 'Documentation';

  @override
  String get aboutApp => 'About App';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get logoutAllDevices => 'Logout All Devices';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get discardChanges => 'Discard Changes';

  @override
  String get settingsSaved => 'Settings saved successfully!';

  @override
  String get passwordChanged => 'Password changed successfully!';

  @override
  String get languageChanged => 'Language changed successfully!';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get confirmLogoutAll =>
      'Are you sure you want to logout from all devices?';

  @override
  String get confirmDeleteAccount =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get confirmResetSettings =>
      'Are you sure you want to reset all settings to default?';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get never => 'Never';

  @override
  String get immediately => 'Immediately';

  @override
  String get after5Minutes => 'After 5 minutes';

  @override
  String get after15Minutes => 'After 15 minutes';

  @override
  String get after30Minutes => 'After 30 minutes';

  @override
  String get after1Hour => 'After 1 hour';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Account';

  @override
  String get administrator => 'Administrator';

  @override
  String get appearance => 'Appearance';

  @override
  String get enableDarkModeForApp => 'Enable dark mode for the app';

  @override
  String get languageAndRegion => 'Language & Region';

  @override
  String get security => 'Security';

  @override
  String get twoFactorAuthentication => 'Two-Factor Authentication';

  @override
  String get addExtraSecurityLayer => 'Add an extra layer of security';

  @override
  String get updateAccountPassword => 'Update your account password';

  @override
  String get manageDataPrivacy => 'Manage your data privacy';

  @override
  String get soon => 'Soon';

  @override
  String get aboutThisApp => 'About This App';

  @override
  String get currentAppVersion => 'Current app version';

  @override
  String get readTermsOfService => 'Read our terms of service';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get viewOpenSourceLicenses => 'View open source licenses';

  @override
  String get searchUsers => 'Search users...';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get userAddedSuccessfully => 'User added successfully!';

  @override
  String get userUpdatedSuccessfully => 'User updated successfully!';

  @override
  String get userDeletedSuccessfully => 'User deleted successfully!';

  @override
  String get errorAddingUser => 'Error adding user';

  @override
  String get errorUpdatingUser => 'Error updating user';

  @override
  String get errorDeletingUser => 'Error deleting user';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get deleteUserWarning => 'Are you sure you want to delete this user?';

  @override
  String get deleteUserDescription =>
      'This action cannot be undone. All user data will be permanently deleted.';

  @override
  String get leaveEmptyToKeep => 'Leave empty to keep current password';

  @override
  String get sessionReport => 'Session Report';

  @override
  String get attendanceInformation => 'Attendance Information';

  @override
  String get trainingHistory => 'Training History';

  @override
  String get duration => 'Duration';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get playerName => 'Player Name';

  @override
  String get numberOfPlayers => 'Number of Players';

  @override
  String get sessionDate => 'Session Date';

  @override
  String get attendanceList => 'Attendance List';

  @override
  String get presentPlayers => 'Present Players';

  @override
  String get absentPlayers => 'Absent Players';

  @override
  String get systemNotifications => 'System Notifications';

  @override
  String get securityAlerts => 'Security Alerts';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get seeAll => 'See All';

  @override
  String get organizationSetup => 'Organization Setup';

  @override
  String get stepBasicInfo => 'Basic Information';

  @override
  String get stepAdminUser => 'Administrator';

  @override
  String get stepTeamSetup => 'Team Setup';

  @override
  String get stepPaymentConfig => 'Payment Configuration';

  @override
  String get stepReview => 'Review & Complete';

  @override
  String get organizationName => 'Organization Name';

  @override
  String get organizationAddress => 'Organization Address';

  @override
  String get organizationType => 'Organization Type';

  @override
  String get selectOrgType => 'Select organization type';

  @override
  String get club => 'Club';

  @override
  String get school => 'School';

  @override
  String get academy => 'Academy';

  @override
  String get other => 'Other';

  @override
  String get adminSetup => 'Administrator Setup';

  @override
  String get adminName => 'Administrator Name';

  @override
  String get adminEmail => 'Administrator Email';

  @override
  String get adminPassword => 'Administrator Password';

  @override
  String get createAdminAccount => 'Create administrator account';

  @override
  String get teamSetupTitle => 'Create Initial Teams';

  @override
  String get addTeamsDescription =>
      'Add teams and sample players to get started';

  @override
  String get enterTeamName => 'Enter team name';

  @override
  String get addSamplePlayers => 'Add sample players';

  @override
  String get samplesPerTeam => 'players per team';

  @override
  String get paymentConfiguration => 'Payment Configuration';

  @override
  String get defaultMonthlyFee => 'Default Monthly Fee';

  @override
  String get currency => 'Currency';

  @override
  String get selectCurrency => 'Select currency';

  @override
  String get paymentDueDay => 'Payment Due Day';

  @override
  String get dueDayDescription => 'Day of the month when payments are due';

  @override
  String get reviewAndComplete => 'Review & Complete';

  @override
  String get setupSummary => 'Setup Summary';

  @override
  String get reviewDetails => 'Review your organization details below';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get backToPrevious => 'Back to Previous';

  @override
  String get nextStep => 'Next Step';

  @override
  String get setupInProgress => 'Setup in Progress...';

  @override
  String get creatingOrganization => 'Creating organization...';

  @override
  String get creatingAdminAccount => 'Creating admin account...';

  @override
  String get settingUpTeams => 'Setting up teams...';

  @override
  String get configuringPayments => 'Configuring payments...';

  @override
  String get finalizingSetup => 'Finalizing setup...';

  @override
  String get setupCompleteTitle => 'Setup Complete!';

  @override
  String get setupCompleteMessage =>
      'Your organization has been successfully created';

  @override
  String get getStarted => 'Get Started';

  @override
  String get setupError => 'Setup Error';

  @override
  String get setupErrorMessage =>
      'An error occurred during setup. Please try again.';

  @override
  String get contactSupportIfPersists =>
      'Contact support if this error persists.';

  @override
  String get processingRequest => 'Processing request...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get almostDone => 'Almost done...';

  @override
  String get demoOrganization => 'Demo Organization';

  @override
  String get demoMode => 'Demo Mode';

  @override
  String get demoDataWarning =>
      'This is demo data. Changes will not be saved permanently.';

  @override
  String get cleanupDemoData => 'Cleanup Demo Data';

  @override
  String get cleanupDescription =>
      'Remove all demo organizations older than 24 hours';

  @override
  String get performCleanup => 'Perform Cleanup';

  @override
  String get cleanupComplete => 'Cleanup complete';

  @override
  String get noOldDemoData => 'No old demo data found to cleanup';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get retryConnection => 'Retry Connection';

  @override
  String get offlineChanges =>
      'Changes will be synced when connection is restored';

  @override
  String get validationError => 'Validation Error';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidFormat => 'Invalid format';

  @override
  String get mustBeNumber => 'Must be a valid number';

  @override
  String get mustBePositive => 'Must be a positive number';

  @override
  String get tooShort => 'Too short';

  @override
  String get tooLong => 'Too long';

  @override
  String get organizationExists => 'Organization with this name already exists';

  @override
  String get emailTaken => 'Email address is already taken';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get organizationNameTooShort => 'Organization name is too short';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get loadingOrganizations => 'Loading organizations...';

  @override
  String get selectExistingOrg => 'Select existing organization';

  @override
  String get createNewOrg => 'Create new organization';

  @override
  String get joinOrganization => 'Join Organization';

  @override
  String get switchOrganization => 'Switch Organization';

  @override
  String get noOrganizationAccess =>
      'You don\'t have access to any organizations';

  @override
  String get resumeSetup => 'Resume Setup';

  @override
  String get continueSetup => 'Continue Setup';

  @override
  String get startFresh => 'Start Fresh';

  @override
  String get setupInterrupted => 'Your setup was interrupted';

  @override
  String resumeFromStep(String stepNumber) {
    return 'Resume from step $stepNumber';
  }

  @override
  String get abandonSetup => 'Abandon Setup';

  @override
  String get networkTimeoutError =>
      'Network timeout. Please check your connection.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get rateLimitExceeded =>
      'Too many requests. Please wait before trying again.';

  @override
  String get operationCancelled => 'Operation was cancelled';

  @override
  String get batchOperationInProgress => 'Batch operation in progress...';

  @override
  String processingItems(String current, String total) {
    return 'Processing $current of $total items...';
  }

  @override
  String get teamReportTitle => 'Team Report';

  @override
  String get teamDetails => 'Team Details';

  @override
  String get positionDistribution => 'Position Distribution';

  @override
  String get teamPlayers => 'Team Players';

  @override
  String teamPlayersCount(String count) {
    return 'Team Players ($count)';
  }

  @override
  String get goalkeeper => 'Goalkeeper';

  @override
  String get defender => 'Defender';

  @override
  String get midfielder => 'Midfielder';

  @override
  String get forward => 'Forward';

  @override
  String get averageAge => 'Average Age';

  @override
  String get noPlayersFound => 'No players found for this team.';

  @override
  String get loadingTeamDetails => 'Loading team details...';

  @override
  String get loadingPlayers => 'Loading players...';

  @override
  String get calculatingStatistics => 'Calculating statistics...';

  @override
  String get errorLoadingTeamData => 'Error loading team data';

  @override
  String get errorLoadingPlayers => 'Error loading team players';

  @override
  String get pdfSuccessfullyGenerated => 'PDF successfully generated!';

  @override
  String errorGeneratingPdfReport(String error) {
    return 'Error generating PDF report: $error';
  }

  @override
  String get generating => 'Generating...';

  @override
  String get noDescription => 'No description';

  @override
  String get unknownPlayer => 'Unknown Player';

  @override
  String get cannotLoadPlayerDetails =>
      'Cannot load details: Missing player ID.';

  @override
  String get loadingPlayerDetails => 'Loading player details...';

  @override
  String get playerDetailsNotFound => 'Player details not found.';

  @override
  String get errorLoadingPlayerDetails => 'Error loading player details.';

  @override
  String get profile => 'Profile';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get updateCloseSession => 'Update & Close Session';

  @override
  String get trainingActive => 'Training Active';

  @override
  String endsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get closed => 'Closed';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get manageYourProfile => 'Manage your profile';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get callSupport => 'Call Support';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get getHelpSupport => 'Get help & support';

  @override
  String get appInformation => 'App information';

  @override
  String get signOutAccount => 'Sign out of your account';

  @override
  String get confirmSignOut =>
      'Are you sure you want to sign out of your account?';

  @override
  String get tapToChangePhoto => 'Tap to change photo';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get nameField => 'Name';

  @override
  String get emailField => 'Email';

  @override
  String get saveButton => 'Save';

  @override
  String get trainingTypeGame => 'Game';

  @override
  String get trainingTypeTraining => 'Training';

  @override
  String get trainingTypeTactical => 'Tactical';

  @override
  String get trainingTypeFitness => 'Fitness';

  @override
  String get trainingTypeTechnical => 'Technical';

  @override
  String get trainingTypeTheoretical => 'Theoretical';

  @override
  String get trainingTypeSurvey => 'Survey';

  @override
  String get trainingTypeMixed => 'Mixed';

  @override
  String get trainingDescGame =>
      'Official or practice matches against other teams';

  @override
  String get trainingDescTraining =>
      'General training with skill development and conditioning';

  @override
  String get trainingDescTactical =>
      'Tactical formations, strategies, and team play practice';

  @override
  String get trainingDescFitness =>
      'Conditioning workouts, strength training, and endurance building';

  @override
  String get trainingDescTechnical =>
      'Individual technical skills: dribbling, shooting, passing';

  @override
  String get trainingDescTheoretical =>
      'Tactical discussions, game rules, and strategic planning';

  @override
  String get trainingDescSurvey =>
      'Player assessments, testing, and skill evaluations';

  @override
  String get trainingDescMixed =>
      'Combined training with elements from multiple types';

  @override
  String get unknownCoachName => 'Unknown Coach';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get trainingSessionSaved =>
      'Training session saved! You can edit it once more.';

  @override
  String get errorLoadingTeams => 'Error loading teams';

  @override
  String get noTeamsAssigned => 'No teams assigned';

  @override
  String trainingEndsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get noPlayersFoundInTeam => 'No players found in this team';

  @override
  String get themeTitle => 'Theme';

  @override
  String get coachRole => 'Coach';

  @override
  String callPhoneNumber(String phoneNumber) {
    return 'Call: $phoneNumber\nTap phone number to copy and dial';
  }

  @override
  String emailAddress(String email) {
    return 'Email: $email\nTap email to copy and send';
  }

  @override
  String get themeSettingsComingSoon => 'Theme Settings';

  @override
  String get darkModeComingSoon =>
      'Dark mode and theme customization options will be available soon.';

  @override
  String languageChangedTo(String languageName) {
    return 'Language changed to $languageName';
  }

  @override
  String get helpSupportComingSoon => 'Help & Support coming soon';

  @override
  String get footballTrainingApp => 'FootballTraining App';

  @override
  String get versionLabel => 'Version: 1.0.0';

  @override
  String get appDescription =>
      'A comprehensive football training management system.';

  @override
  String get uploadTimeout => 'Upload timeout. Please check your connection.';

  @override
  String get userNotAuthenticated =>
      'User not authenticated or organization not initialized';

  @override
  String get currentPasswordRequiredForChanges =>
      'Current password is required for email or password changes';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get changePasswordLabel => 'Change Password';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get saveLabel => 'Save';

  @override
  String get contact => 'Contact';

  @override
  String get phoneSupport => 'Phone Support';

  @override
  String get support => 'Support';

  @override
  String get profileManagement => 'Profile Management';

  @override
  String get helpAndSupport => 'Help and Support';

  @override
  String get applicationInfo => 'Application Information';
}
