import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/organization_context.dart';
import '../services/logging_service.dart';

/// Service for batched Firestore operations to improve performance
class BatchedFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Batch read multiple documents efficiently
  static Future<Map<String, DocumentSnapshot?>> batchRead(
    List<DocumentReference> refs, {
    Source source = Source.serverAndCache,
  }) async {
    if (refs.isEmpty) return {};

    try {
      final futures = refs.map((ref) => ref.get(GetOptions(source: source)));
      final results = await Future.wait(futures);
      
      final resultMap = <String, DocumentSnapshot?>{};
      for (int i = 0; i < refs.length; i++) {
        resultMap[refs[i].path] = results[i].exists ? results[i] : null;
      }
      
      return resultMap;
    } catch (e, stackTrace) {
      LoggingService.error('Batch read failed', e, stackTrace);
      rethrow;
    }
  }

  /// Batch read collection documents with pagination
  static Future<BatchedCollectionResult> batchReadCollection(
    String collectionPath, {
    List<QueryConstraint> constraints = const [],
    int? limit,
    DocumentSnapshot? startAfter,
    Source source = Source.serverAndCache,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);
      
      // Apply constraints
      for (final constraint in constraints) {
        query = constraint.apply(query);
      }
      
      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get(GetOptions(source: source));
      
      return BatchedCollectionResult(
        documents: snapshot.docs,
        hasMore: snapshot.docs.length == (limit ?? 0),
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e, stackTrace) {
      LoggingService.error('Batch collection read failed', e, stackTrace);
      rethrow;
    }
  }

  /// Batch read organization-scoped collection
  static Future<BatchedCollectionResult> batchReadOrgCollection(
    String collectionName, {
    List<QueryConstraint> constraints = const [],
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    OrganizationContext.enforceContext();
    
    final collectionPath = OrganizationContext.getCollectionPath(collectionName);
    return batchReadCollection(
      collectionPath,
      constraints: constraints,
      limit: limit,
      startAfter: startAfter,
    );
  }

  /// Read players with their payment status for a specific month
  static Future<List<PlayerWithPayments>> readPlayersWithPayments(
    String year, 
    String month, {
    String? teamFilter,
  }) async {
    OrganizationContext.enforceContext();
    
    try {
      // Read all players
      List<QueryConstraint> constraints = [];
      if (teamFilter != null) {
        constraints.add(WhereConstraint('team', isEqualTo: teamFilter));
      }
      
      final playersResult = await batchReadOrgCollection(
        'players',
        constraints: constraints,
      );
      
      if (playersResult.documents.isEmpty) {
        return [];
      }

      // Get payment references for all players
      final paymentRefs = playersResult.documents.map((playerDoc) {
        return OrganizationContext
            .getCollection('players')
            .doc(playerDoc.id)
            .collection('payments')
            .doc('$year-$month');
      }).toList();

      // Batch read all payments
      final paymentResults = await batchRead(paymentRefs);
      
      // Combine players with their payment status
      final results = <PlayerWithPayments>[];
      for (int i = 0; i < playersResult.documents.length; i++) {
        final playerDoc = playersResult.documents[i];
        final paymentPath = paymentRefs[i].path;
        final paymentDoc = paymentResults[paymentPath];
        
        results.add(PlayerWithPayments(
          playerDocument: playerDoc,
          paymentDocument: paymentDoc,
          year: year,
          month: month,
        ));
      }
      
      return results;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to read players with payments', e, stackTrace);
      rethrow;
    }
  }

  /// Read team statistics with aggregated data
  static Future<List<TeamStatistics>> readTeamStatistics() async {
    OrganizationContext.enforceContext();
    
    try {
      final teamsResult = await batchReadOrgCollection('teams');
      if (teamsResult.documents.isEmpty) return [];

      final results = <TeamStatistics>[];
      
      for (final teamDoc in teamsResult.documents) {
        final teamData = teamDoc.data() as Map<String, dynamic>;
        final teamName = teamData['team_name'] ?? '';
        
        // Get player count for team
        final playersQuery = await OrganizationContext
            .getCollection('players')
            .where('team', isEqualTo: teamName)
            .where('is_active', isEqualTo: true)
            .count()
            .get();
        
        results.add(TeamStatistics(
          teamDocument: teamDoc,
          activePlayerCount: playersQuery.count ?? 0,
          totalRevenue: 0, // Will be calculated from payments
          lastUpdated: DateTime.now(),
        ));
      }
      
      return results;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to read team statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Batch write operations
  static Future<void> batchWrite(List<BatchOperation> operations) async {
    if (operations.isEmpty) return;

    final batch = _firestore.batch();
    
    for (final operation in operations) {
      operation.apply(batch);
    }
    
    try {
      await batch.commit();
      LoggingService.info('Batch write completed: ${operations.length} operations');
    } catch (e, stackTrace) {
      LoggingService.error('Batch write failed', e, stackTrace);
      rethrow;
    }
  }
}

/// Result of batched collection read
class BatchedCollectionResult {
  final List<DocumentSnapshot> documents;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const BatchedCollectionResult({
    required this.documents,
    required this.hasMore,
    this.lastDocument,
  });
}

/// Player with payment information
class PlayerWithPayments {
  final DocumentSnapshot playerDocument;
  final DocumentSnapshot? paymentDocument;
  final String year;
  final String month;

  const PlayerWithPayments({
    required this.playerDocument,
    this.paymentDocument,
    required this.year,
    required this.month,
  });

  Map<String, dynamic> get playerData => 
      playerDocument.data() as Map<String, dynamic>;
  
  Map<String, dynamic>? get paymentData => 
      paymentDocument?.data() as Map<String, dynamic>?;
  
  bool get isPaid => paymentData?['isPaid'] == true;
  bool get isActive => paymentData?['isActive'] != false;
  String get playerName => playerData['name'] ?? 'Unknown';
  String get teamName => playerData['team'] ?? 'No Team';
}

/// Team statistics aggregation
class TeamStatistics {
  final DocumentSnapshot teamDocument;
  final int activePlayerCount;
  final double totalRevenue;
  final DateTime lastUpdated;

  const TeamStatistics({
    required this.teamDocument,
    required this.activePlayerCount,
    required this.totalRevenue,
    required this.lastUpdated,
  });

  Map<String, dynamic> get teamData => 
      teamDocument.data() as Map<String, dynamic>;
  
  String get teamName => teamData['team_name'] ?? 'Unknown';
  String get teamId => teamDocument.id;
}

/// Query constraint wrapper
abstract class QueryConstraint {
  Query apply(Query query);
}

/// Where constraint
class WhereConstraint extends QueryConstraint {
  final String field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic isLessThan;
  final List<dynamic>? whereIn;

  WhereConstraint(
    this.field, {
    this.isEqualTo,
    this.isGreaterThan,
    this.isLessThan,
    this.whereIn,
  });

  @override
  Query apply(Query query) {
    if (isEqualTo != null) {
      return query.where(field, isEqualTo: isEqualTo);
    }
    if (isGreaterThan != null) {
      return query.where(field, isGreaterThan: isGreaterThan);
    }
    if (isLessThan != null) {
      return query.where(field, isLessThan: isLessThan);
    }
    if (whereIn != null) {
      return query.where(field, whereIn: whereIn);
    }
    return query;
  }
}

/// Order by constraint
class OrderByConstraint extends QueryConstraint {
  final String field;
  final bool descending;

  OrderByConstraint(this.field, {this.descending = false});

  @override
  Query apply(Query query) {
    return query.orderBy(field, descending: descending);
  }
}

/// Batch operation wrapper
abstract class BatchOperation {
  void apply(WriteBatch batch);
}

/// Set operation
class SetOperation extends BatchOperation {
  final DocumentReference reference;
  final Map<String, dynamic> data;
  final SetOptions? options;

  SetOperation(this.reference, this.data, {this.options});

  @override
  void apply(WriteBatch batch) {
    if (options != null) {
      batch.set(reference, data, options!);
    } else {
      batch.set(reference, data);
    }
  }
}

/// Update operation
class UpdateOperation extends BatchOperation {
  final DocumentReference reference;
  final Map<String, dynamic> data;

  UpdateOperation(this.reference, this.data);

  @override
  void apply(WriteBatch batch) {
    batch.update(reference, data);
  }
}

/// Delete operation
class DeleteOperation extends BatchOperation {
  final DocumentReference reference;

  DeleteOperation(this.reference);

  @override
  void apply(WriteBatch batch) {
    batch.delete(reference);
  }
}