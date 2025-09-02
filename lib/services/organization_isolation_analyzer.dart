import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/logging_service.dart';

/// Utility to analyze current Firestore structure and organization isolation
class OrganizationIsolationAnalyzer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Analyze organization isolation status
  Future<Map<String, dynamic>> analyzeIsolationStatus() async {
    try {
      LoggingService.info('🔍 Analyzing organization isolation status...');

      final analysis = <String, dynamic>{};

      // 1. Check organizations structure
      final orgsSnapshot = await _firestore.collection('organizations').get();
      analysis['organizations_count'] = orgsSnapshot.docs.length;
      analysis['organizations'] = <String, dynamic>{};

      for (final orgDoc in orgsSnapshot.docs) {
        final orgId = orgDoc.id;
        final orgData = orgDoc.data();

        final orgAnalysis = <String, dynamic>{
          'name': orgData['name'] ?? 'Unknown',
          'created_at': orgData['created_at'],
          'admin_user_id': orgData['admin_user_id'],
          'collections': <String, int>{},
        };

        // Check each scoped collection
        final collections = [
          'users',
          'teams',
          'players',
          'training_sessions',
          'payments'
        ];

        for (final collection in collections) {
          try {
            final collectionSnapshot = await _firestore
                .collection('organizations')
                .doc(orgId)
                .collection(collection)
                .count()
                .get();
            orgAnalysis['collections'][collection] =
                collectionSnapshot.count ?? 0;
          } catch (e) {
            orgAnalysis['collections'][collection] = 0;
          }
        }

        analysis['organizations'][orgId] = orgAnalysis;
      }

      // 2. Check global collections (potential isolation issues)
      final globalCollections = [
        'teams',
        'players',
        'users',
        'training_sessions',
        'payments'
      ];
      analysis['global_collections'] = <String, dynamic>{};

      for (final collection in globalCollections) {
        try {
          final globalSnapshot =
              await _firestore.collection(collection).count().get();
          final globalCount = globalSnapshot.count ?? 0;

          if (globalCount > 0) {
            // Check if these have organization_id field
            final sampleDoc =
                await _firestore.collection(collection).limit(1).get();
            final hasOrgId = sampleDoc.docs.isNotEmpty &&
                sampleDoc.docs.first.data().containsKey('organization_id');

            analysis['global_collections'][collection] = {
              'count': globalCount,
              'has_organization_id': hasOrgId,
              'needs_migration': hasOrgId, // Can be migrated if has org_id
            };
          } else {
            analysis['global_collections'][collection] = {
              'count': 0,
              'has_organization_id': false,
              'needs_migration': false,
            };
          }
        } catch (e) {
          LoggingService.error(
              'Error checking global collection: $collection', e);
        }
      }

      // 3. Isolation assessment
      analysis['isolation_status'] = _assessIsolationStatus(analysis);

      LoggingService.info('✅ Organization isolation analysis completed');
      return analysis;
    } catch (e, stackTrace) {
      LoggingService.error(
          '❌ Failed to analyze isolation status', e, stackTrace);
      rethrow;
    }
  }

  /// Assess overall isolation status
  Map<String, dynamic> _assessIsolationStatus(Map<String, dynamic> analysis) {
    final orgsCount = analysis['organizations_count'] as int;
    final globalCollections =
        analysis['global_collections'] as Map<String, dynamic>;

    int globalDataCount = 0;
    int migrableDataCount = 0;

    for (final entry in globalCollections.entries) {
      final collectionData = entry.value as Map<String, dynamic>;
      final count = collectionData['count'] as int;
      final needsMigration = collectionData['needs_migration'] as bool;

      globalDataCount += count;
      if (needsMigration) {
        migrableDataCount += count;
      }
    }

    String status;
    String recommendation;

    if (globalDataCount == 0) {
      status = 'PERFECT_ISOLATION';
      recommendation = 'All data is properly isolated. No action needed.';
    } else if (migrableDataCount == globalDataCount) {
      status = 'NEEDS_MIGRATION';
      recommendation =
          'Global data exists but can be migrated to organization-scoped collections.';
    } else if (globalDataCount > 0) {
      status = 'MIXED_DATA';
      recommendation =
          'Some global data cannot be automatically migrated. Manual review needed.';
    } else {
      status = 'UNKNOWN';
      recommendation = 'Unable to determine isolation status.';
    }

    return {
      'status': status,
      'recommendation': recommendation,
      'organizations_count': orgsCount,
      'global_data_count': globalDataCount,
      'migrable_data_count': migrableDataCount,
      'isolation_percentage': orgsCount > 0
          ? ((orgsCount * 100) / (orgsCount + (globalDataCount > 0 ? 1 : 0)))
              .round()
          : 100,
    };
  }

  /// Generate isolation report
  Future<String> generateIsolationReport() async {
    final analysis = await analyzeIsolationStatus();
    final buffer = StringBuffer();

    buffer.writeln('# 🏢 Organization Isolation Report');
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    // Overall status
    final isolation = analysis['isolation_status'] as Map<String, dynamic>;
    buffer.writeln('## 📊 Overall Status');
    buffer.writeln('- **Status**: ${isolation['status']}');
    buffer.writeln('- **Organizations**: ${isolation['organizations_count']}');
    buffer.writeln(
        '- **Isolation Score**: ${isolation['isolation_percentage']}%');
    buffer.writeln('- **Recommendation**: ${isolation['recommendation']}');
    buffer.writeln('');

    // Organizations breakdown
    buffer.writeln('## 🏢 Organizations');
    final organizations = analysis['organizations'] as Map<String, dynamic>;

    for (final entry in organizations.entries) {
      final orgId = entry.key;
      final orgData = entry.value as Map<String, dynamic>;

      buffer.writeln('### ${orgData['name']} (`$orgId`)');
      buffer.writeln('- **Admin User ID**: ${orgData['admin_user_id']}');

      final collections = orgData['collections'] as Map<String, dynamic>;
      buffer.writeln('- **Data Distribution**:');
      for (final collEntry in collections.entries) {
        buffer.writeln('  - ${collEntry.key}: ${collEntry.value} documents');
      }
      buffer.writeln('');
    }

    // Global collections status
    buffer.writeln('## 🌍 Global Collections Status');
    final globalCollections =
        analysis['global_collections'] as Map<String, dynamic>;

    for (final entry in globalCollections.entries) {
      final collection = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final count = data['count'];
      final needsMigration = data['needs_migration'];

      if (count > 0) {
        buffer.writeln('- **$collection**: $count documents');
        buffer.writeln(
            '  - Migration needed: ${needsMigration ? "✅ Yes" : "❌ No"}');
      } else {
        buffer.writeln('- **$collection**: ✅ Empty (properly isolated)');
      }
    }
    buffer.writeln('');

    // Action items
    buffer.writeln('## 🎯 Action Items');

    if (isolation['status'] == 'PERFECT_ISOLATION') {
      buffer
          .writeln('✅ **No action needed** - Your data is perfectly isolated!');
    } else if (isolation['status'] == 'NEEDS_MIGRATION') {
      buffer.writeln('📋 **Migration Recommended**:');
      buffer.writeln(
          '1. Use the Organization Migration Screen to migrate global data');
      buffer.writeln('2. Verify migration results');
      buffer.writeln('3. Cleanup global collections after verification');
    } else {
      buffer.writeln('⚠️ **Manual Review Required**:');
      buffer.writeln('1. Analyze global collections manually');
      buffer.writeln('2. Determine migration strategy for each collection');
      buffer.writeln('3. Run custom migration scripts if needed');
    }

    return buffer.toString();
  }

  /// Check specific organization isolation
  Future<bool> isOrganizationIsolated(String organizationId) async {
    try {
      // Check if organization has scoped collections
      final collections = ['users', 'teams', 'players'];

      for (final collection in collections) {
        final snapshot = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection(collection)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Found scoped data - good isolation
          return true;
        }
      }

      // No scoped data found - check if global data exists for this org
      final globalTeams = await _firestore
          .collection('teams')
          .where('organization_id', isEqualTo: organizationId)
          .limit(1)
          .get();

      if (globalTeams.docs.isNotEmpty) {
        // Has global data - needs migration
        return false;
      }

      // No data at all - considered isolated (new org)
      return true;
    } catch (e) {
      LoggingService.error('Error checking organization isolation', e);
      return false;
    }
  }
}
