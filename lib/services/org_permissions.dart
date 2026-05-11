class OrgPermissions {
  static const String manageOrganization = 'manage_organization';
  static const String manageUsers = 'manage_users';
  static const String manageTeams = 'manage_teams';
  static const String managePlayers = 'manage_players';
  static const String manageSessions = 'manage_sessions';
  static const String manageAttendance = 'manage_attendance';
  static const String managePayments = 'manage_payments';
  static const String manageReports = 'manage_reports';
  static const String viewPlayers = 'view_players';
  static const String viewTeams = 'view_teams';
  static const String viewSessions = 'view_sessions';
  static const String viewReports = 'view_reports';
  static const String exportData = 'export_data';

  static Map<String, bool> adminAll() => {
        manageOrganization: true,
        manageUsers: true,
        manageTeams: true,
        managePlayers: true,
        manageSessions: true,
        manageAttendance: true,
        managePayments: true,
        manageReports: true,
        viewPlayers: true,
        viewTeams: true,
        viewSessions: true,
        viewReports: true,
        exportData: true,
      };

  static Map<String, bool> receptionistDefault() => {
        manageAttendance: true,
        managePlayers: true,
        managePayments: true,
        viewPlayers: true,
        viewTeams: true,
        viewSessions: true,
        viewReports: true,
      };

  static Map<String, bool> coachDefault() => {
        manageAttendance: true,
        manageSessions: true,
        viewPlayers: true,
        viewTeams: true,
        viewSessions: true,
      };
}
