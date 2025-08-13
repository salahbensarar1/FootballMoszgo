import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:logger/logger.dart';

/// Multi-tenant Firestore service that automatically scopes all operations to current organization
class MultiTenantFirestoreService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get organization-scoped collection reference
  static CollectionReference collection(String collectionName) {
    if (!OrganizationContext.isInitialized) {
      throw Exception('Organization context not initialized. Call OrganizationContext.initialize() first.');
    }
    
    return _firestore
        .collection('organizations')
        .doc(OrganizationContext.currentOrgId)
        .collection(collectionName);
  }
  
  /// Get global collection reference (for system-level data)
  static CollectionReference globalCollection(String collectionName) {
    return _firestore.collection(collectionName);
  }
  
  /// Users collection for current organization
  static CollectionReference get users => collection('users');
  
  /// Teams collection for current organization
  static CollectionReference get teams => collection('teams');
  
  /// Players collection for current organization
  static CollectionReference get players => collection('players');
  
  /// Training sessions collection for current organization
  static CollectionReference get trainingSessions => collection('training_sessions');
  
  /// Payments collection for current organization
  static CollectionReference get payments => collection('payments');
  
  /// Reports collection for current organization
  static CollectionReference get reports => collection('reports');
  
  /// Organizations collection (global)
  static CollectionReference get organizations => globalCollection('organizations');
  
  /// Subscriptions collection (global)
  static CollectionReference get subscriptions => globalCollection('subscriptions');
  
  /// Payment history collection (global)
  static CollectionReference get paymentHistory => globalCollection('payment_history');
  
  /// Create organization-scoped document with automatic metadata
  static Future<DocumentReference> createDocument(
    String collectionName,
    Map<String, dynamic> data, {
    String? documentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Add automatic metadata
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    data['created_by'] = user.uid;
    data['organization_id'] = OrganizationContext.currentOrgId;
    
    try {
      DocumentReference docRef;
      if (documentId != null) {
        docRef = collection(collectionName).doc(documentId);
        await docRef.set(data);
      } else {
        docRef = await collection(collectionName).add(data);
      }
      
      _logger.d('✅ Created document in $collectionName: ${docRef.id}');
      return docRef;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to create document in $collectionName', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Update organization-scoped document with automatic metadata
  static Future<void> updateDocument(
    String collectionName,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Add automatic metadata
    data['updated_at'] = FieldValue.serverTimestamp();
    data['updated_by'] = user.uid;
    
    try {
      if (merge) {
        await collection(collectionName).doc(documentId).update(data);
      } else {
        await collection(collectionName).doc(documentId).set(data);
      }
      
      _logger.d('✅ Updated document in $collectionName: $documentId');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to update document in $collectionName/$documentId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Delete organization-scoped document with soft delete option
  static Future<void> deleteDocument(
    String collectionName,
    String documentId, {
    bool softDelete = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      if (softDelete) {
        // Soft delete: mark as inactive
        await updateDocument(collectionName, documentId, {
          'is_active': false,
          'deleted_at': FieldValue.serverTimestamp(),
          'deleted_by': user.uid,
        });
        _logger.d('✅ Soft deleted document in $collectionName: $documentId');
      } else {
        // Hard delete
        await collection(collectionName).doc(documentId).delete();
        _logger.d('✅ Hard deleted document in $collectionName: $documentId');
      }
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to delete document in $collectionName/$documentId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Get document with organization scope validation
  static Future<DocumentSnapshot> getDocument(
    String collectionName,
    String documentId,
  ) async {
    try {
      final doc = await collection(collectionName).doc(documentId).get();
      
      if (!doc.exists) {
        throw Exception('Document not found: $collectionName/$documentId');
      }
      
      // Validate organization scope
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('organization_id')) {
        final docOrgId = data['organization_id'] as String?;
        if (docOrgId != OrganizationContext.currentOrgId) {
          throw Exception('Access denied: Document belongs to different organization');
        }
      }
      
      return doc;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to get document $collectionName/$documentId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Query documents with automatic organization scoping
  static Query queryCollection(
    String collectionName, {
    bool includeInactive = false,
  }) {
    Query query = collection(collectionName);
    
    // Filter out inactive documents by default
    if (!includeInactive) {
      query = query.where('is_active', isNotEqualTo: false);
    }
    
    return query;
  }
  
  /// Batch write operations with organization scoping
  static Future<void> batchWrite(List<BatchOperation> operations) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();
      
      for (final operation in operations) {
        final docRef = collection(operation.collectionName).doc(operation.documentId);
        
        switch (operation.type) {
          case BatchOperationType.create:
          case BatchOperationType.set:
            operation.data['created_at'] ??= timestamp;
            operation.data['updated_at'] = timestamp;
            operation.data['created_by'] ??= user.uid;
            operation.data['organization_id'] = OrganizationContext.currentOrgId;
            batch.set(docRef, operation.data, SetOptions(merge: operation.merge));
            break;
            
          case BatchOperationType.update:
            operation.data['updated_at'] = timestamp;
            operation.data['updated_by'] = user.uid;
            batch.update(docRef, operation.data);
            break;
            
          case BatchOperationType.delete:
            batch.delete(docRef);
            break;
        }
      }
      
      await batch.commit();
      _logger.d('✅ Batch operation completed: ${operations.length} operations');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Batch operation failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Check subscription limits before allowing operations
  static Future<bool> checkSubscriptionLimits({
    int additionalPlayers = 0,
    int additionalTeams = 0,
    int additionalCoaches = 0,
  }) async {
    return await OrganizationContext.isWithinLimits(
      additionalPlayers: additionalPlayers,
      additionalTeams: additionalTeams,
      additionalCoaches: additionalCoaches,
    );
  }
  
  /// Validate feature access based on subscription
  static bool hasFeatureAccess(String feature) {
    return OrganizationContext.hasFeature(feature);
  }
  
  /// Get current user's role in organization
  static String? getCurrentUserRole() {
    return OrganizationContext.userPermissions['role'] as String?;
  }
  
  /// Check if current user has required role
  static bool hasRole(String role) {
    return OrganizationContext.hasRole(role);
  }
  
  /// Check if current user has required permission
  static bool hasPermission(String permission) {
    return OrganizationContext.hasPermission(permission);
  }
}

/// Batch operation definition
class BatchOperation {
  final BatchOperationType type;
  final String collectionName;
  final String? documentId;
  final Map<String, dynamic> data;
  final bool merge;
  
  const BatchOperation({
    required this.type,
    required this.collectionName,
    this.documentId,
    this.data = const {},
    this.merge = true,
  });
  
  factory BatchOperation.create(
    String collectionName,
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    return BatchOperation(
      type: BatchOperationType.create,
      collectionName: collectionName,
      documentId: documentId,
      data: data,
    );
  }
  
  factory BatchOperation.update(
    String collectionName,
    String documentId,
    Map<String, dynamic> data,
  ) {
    return BatchOperation(
      type: BatchOperationType.update,
      collectionName: collectionName,
      documentId: documentId,
      data: data,
    );
  }
  
  factory BatchOperation.delete(
    String collectionName,
    String documentId,
  ) {
    return BatchOperation(
      type: BatchOperationType.delete,
      collectionName: collectionName,
      documentId: documentId,
    );
  }
}

enum BatchOperationType {
  create,
  set,
  update,
  delete,
}