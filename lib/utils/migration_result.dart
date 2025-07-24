/// Migration result summary
class MigrationResult {
  final int totalTeams;
  final int migratedTeams;
  final int skippedTeams;
  final int errorTeams;
  final List<String> errors;
  final Map<String, dynamic> statistics;

  MigrationResult({
    required this.totalTeams,
    required this.migratedTeams,
    required this.skippedTeams,
    required this.errorTeams,
    required this.errors,
    required this.statistics,
  });

  @override
  String toString() {
    return '''
Migration Summary:
- Total Teams: $totalTeams
- Migrated: $migratedTeams
- Skipped: $skippedTeams
- Errors: $errorTeams
- Success Rate: ${totalTeams > 0 ? ((migratedTeams / totalTeams) * 100).toStringAsFixed(1) : 0}%
    ''';
  }
}