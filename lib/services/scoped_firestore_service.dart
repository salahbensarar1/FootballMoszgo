import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/services/logging_service.dart';

/// Centralized Firestore service that enforces organization-scoped access
/// This ensures complete data isolation between different clubs/organizations
class ScopedFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get organization-scoped collection reference
  /// All club data is accessed through: organizations/{orgId}/{collection}
  static CollectionReference getCollection(String collectionName) {
    final orgId = OrganizationContext.currentOrgId;
    LoggingService.info(
        '🏢 Accessing scoped collection: organizations/$orgId/$collectionName');

    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection(collectionName);
  }

  /// Get global collection reference (for system-level data only)
  static CollectionReference getGlobalCollection(String collectionName) {
    LoggingService.info('🌍 Accessing global collection: $collectionName');
    return _firestore.collection(collectionName);
  }

  // ==============================================================
  // ORGANIZATION-SCOPED COLLECTIONS (Club-specific data)
  // ==============================================================

  /// Users collection for current organization
  /// Path: organizations/{orgId}/users
  static CollectionReference get users => getCollection('users');

  /// Teams collection for current organization
  /// Path: organizations/{orgId}/teams
  static CollectionReference get teams => getCollection('teams');

  /// Players collection for current organization
  /// Path: organizations/{orgId}/players
  static CollectionReference get players => getCollection('players');

  /// Training sessions collection for current organization
  /// Path: organizations/{orgId}/training_sessions
  static CollectionReference get trainingSessions =>
      getCollection('training_sessions');

  /// Payments collection for current organization
  /// Path: organizations/{orgId}/payments
  static CollectionReference get payments => getCollection('payments');

  /// Reports collection for current organization
  /// Path: organizations/{orgId}/reports
  static CollectionReference get reports => getCollection('reports');

  /// Attendance records collection for current organization
  /// Path: organizations/{orgId}/attendance
  static CollectionReference get attendance => getCollection('attendance');

  // ==============================================================
  // GLOBAL COLLECTIONS (System-level data shared across all orgs)
  // ==============================================================

  /// Organizations collection (global)
  /// Path: organizations
  static CollectionReference get organizations =>
      getGlobalCollection('organizations');

  /// Subscriptions collection (global)
  /// Path: subscriptions
  static CollectionReference get subscriptions =>
      getGlobalCollection('subscriptions');

  /// Payment history collection (global billing records)
  /// Path: payment_history
  static CollectionReference get paymentHistory =>
      getGlobalCollection('payment_history');

  /// System logs collection (global)
  /// Path: system_logs
  static CollectionReference get systemLogs =>
      getGlobalCollection('system_logs');

  // ==============================================================
  // UTILITY METHODS
  // ==============================================================

  /// Create a document in organization-scoped collection with auto-metadata
  static Future<DocumentReference> createScopedDocument(
    String collectionName,
    Map<String, dynamic> data, {
    String? documentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Add organization context and audit metadata
    final enhancedData = {
      ...data,
      'organization_id': OrganizationContext.currentOrgId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'created_by': user.uid,
      'updated_by': user.uid,
    };

    final collection = getCollection(collectionName);

    if (documentId != null) {
      await collection.doc(documentId).set(enhancedData);
      return collection.doc(documentId);
    } else {
      return await collection.add(enhancedData);
    }
  }

  /// Update a document in organization-scoped collection with auto-metadata
  static Future<void> updateScopedDocument(
    String collectionName,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Add audit metadata
    final enhancedData = {
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': user.uid,
    };

    await getCollection(collectionName).doc(documentId).update(enhancedData);
  }

  /// Delete a document from organization-scoped collection
  static Future<void> deleteScopedDocument(
    String collectionName,
    String documentId,
  ) async {
    await getCollection(collectionName).doc(documentId).delete();
    LoggingService.info(
        '🗑️ Deleted document: $collectionName/$documentId from org ${OrganizationContext.currentOrgId}');
  }

  /// Get document from organization-scoped collection
  static Future<DocumentSnapshot> getScopedDocument(
    String collectionName,
    String documentId,
  ) async {
    return await getCollection(collectionName).doc(documentId).get();
  }

  /// Query organization-scoped collection
  static Query queryScopedCollection(
    String collectionName, {
    Object? field,
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) {
    Query query = getCollection(collectionName);

    if (field != null) {
      query = query.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      );
    }

    return query;
  }

  /// Stream organization-scoped collection
  static Stream<QuerySnapshot> streamScopedCollection(
    String collectionName, {
    Object? field,
    Object? isEqualTo,
    int? limit,
    List<Object?>? orderBy,
    bool descending = false,
  }) {
    Query query = getCollection(collectionName);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }

    if (orderBy != null) {
      for (final field in orderBy) {
        query = query.orderBy(field as Object, descending: descending);
      }
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Check if current user has access to organization
  static Future<bool> hasOrganizationAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await getCollection('users').doc(user.uid).get();

      return userDoc.exists && userDoc.data() != null;
    } catch (e) {
      LoggingService.error('Error checking organization access', e);
      return false;
    }
  }

  /// Validate organization context before operations
  static void validateContext() {
    if (!OrganizationContext.isInitialized) {
      throw OrganizationContextException(
          'Organization context must be initialized before accessing scoped data');
    }
  }
}
