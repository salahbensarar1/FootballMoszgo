import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/organization_model.dart';
import 'package:footballtraining/data/models/subscription_model.dart';
import 'package:logger/logger.dart';

/// Service for managing organization context in multi-tenant SaaS architecture
class OrganizationContext {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current organization state
  static String? _currentOrgId;
  static Organization? _currentOrg;
  static Subscription? _currentSubscription;
  static Map<String, dynamic>? _userPermissions;
  
  // Getters for current organization context
  static String get currentOrgId {
    if (_currentOrgId == null) {
      throw Exception('Organization context not initialized. Call OrganizationContext.initialize() first.');
    }
    return _currentOrgId!;
  }
  
  static Organization get currentOrg {
    if (_currentOrg == null) {
      throw Exception('Organization context not initialized. Call OrganizationContext.initialize() first.');
    }
    return _currentOrg!;
  }
  
  static Subscription? get currentSubscription => _currentSubscription;
  static Map<String, dynamic> get userPermissions => _userPermissions ?? {};
  static bool get isInitialized => _currentOrgId != null;
  
  /// Initialize organization context for the current user
  static Future<void> initialize({String? specificOrgId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      _logger.i('🏢 Initializing organization context for user: ${user.uid}');
      
      String orgId;
      if (specificOrgId != null) {
        orgId = specificOrgId;
      } else {
        // Get user's primary organization
        orgId = await _getUserPrimaryOrganization(user.uid);
      }
      
      await setCurrentOrganization(orgId);
      await _loadUserPermissions(user.uid, orgId);
      
      _logger.i('✅ Organization context initialized: ${_currentOrg?.name}');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize organization context', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Set current organization context
  static Future<void> setCurrentOrganization(String orgId) async {
    try {
      _logger.i('📋 Setting current organization: $orgId');
      
      // Load organization data
      final orgDoc = await _firestore.collection('organizations').doc(orgId).get();
      if (!orgDoc.exists) {
        throw Exception('Organization not found: $orgId');
      }
      
      _currentOrgId = orgId;
      _currentOrg = Organization.fromFirestore(orgDoc);
      
      // Load subscription data
      await _loadSubscriptionData(orgId);
      
      _logger.i('✅ Organization context set: ${_currentOrg?.name}');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to set organization context', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Get user's primary organization ID
  static Future<String> _getUserPrimaryOrganization(String userId) async {
    // First, check if user has a profile in any organization
    final orgsQuery = await _firestore.collectionGroup('users')
        .where('uid', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();
    
    if (orgsQuery.docs.isEmpty) {
      throw Exception('User not found in any organization');
    }
    
    final userDoc = orgsQuery.docs.first;
    // Extract organization ID from document path
    final pathSegments = userDoc.reference.path.split('/');
    return pathSegments[1]; // organizations/{orgId}/users/{userId}
  }
  
  /// Load subscription data for current organization
  static Future<void> _loadSubscriptionData(String orgId) async {
    try {
      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('organization_id', isEqualTo: orgId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      
      if (subscriptionQuery.docs.isNotEmpty) {
        _currentSubscription = Subscription.fromFirestore(subscriptionQuery.docs.first);
        _logger.i('📊 Subscription loaded: ${_currentSubscription?.planId}');
      } else {
        _logger.w('⚠️ No active subscription found for organization: $orgId');
        _currentSubscription = null;
      }
    } catch (e) {
      _logger.w('⚠️ Failed to load subscription data: $e');
      _currentSubscription = null;
    }
  }
  
  /// Load user permissions for current organization
  static Future<void> _loadUserPermissions(String userId, String orgId) async {
    try {
      final userDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _userPermissions = {
          'role': userData['role'] ?? 'user',
          'permissions': userData['permissions'] ?? [],
          'is_active': userData['is_active'] ?? false,
        };
        _logger.i('👤 User permissions loaded: ${_userPermissions?['role']}');
      }
    } catch (e) {
      _logger.w('⚠️ Failed to load user permissions: $e');
      _userPermissions = {'role': 'user', 'permissions': [], 'is_active': false};
    }
  }
  
  /// Check if user has specific role
  static bool hasRole(String role) {
    return _userPermissions?['role'] == role;
  }
  
  /// Check if user has any of the specified roles
  static bool hasAnyRole(List<String> roles) {
    final userRole = _userPermissions?['role'] as String?;
    return userRole != null && roles.contains(userRole);
  }
  
  /// Check if user has specific permission
  static bool hasPermission(String permission) {
    final permissions = _userPermissions?['permissions'] as List<dynamic>? ?? [];
    return permissions.contains(permission);
  }
  
  /// Check if current subscription allows feature
  static bool hasFeature(String feature) {
    if (_currentSubscription == null) return false;
    return _currentSubscription!.features[feature] == true;
  }
  
  /// Check if organization is within subscription limits
  static Future<bool> isWithinLimits({
    int? additionalPlayers,
    int? additionalTeams,
    int? additionalCoaches,
  }) async {
    if (_currentSubscription == null) return false;
    
    try {
      // Get current counts
      final futures = await Future.wait([
        _getCurrentPlayerCount(),
        _getCurrentTeamCount(),
        _getCurrentCoachCount(),
      ]);
      
      final currentPlayers = futures[0] + (additionalPlayers ?? 0);
      final currentTeams = futures[1] + (additionalTeams ?? 0);
      final currentCoaches = futures[2] + (additionalCoaches ?? 0);
      
      return currentPlayers <= _currentSubscription!.maxPlayers &&
             currentTeams <= _currentSubscription!.maxTeams &&
             currentCoaches <= _currentSubscription!.maxCoaches;
      
    } catch (e) {
      _logger.w('⚠️ Failed to check subscription limits: $e');
      return false;
    }
  }
  
  /// Get current player count for organization
  static Future<int> _getCurrentPlayerCount() async {
    final playersSnapshot = await _firestore
        .collection('organizations')
        .doc(_currentOrgId!)
        .collection('players')
        .where('is_active', isEqualTo: true)
        .count()
        .get();
    return playersSnapshot.count ?? 0;
  }
  
  /// Get current team count for organization
  static Future<int> _getCurrentTeamCount() async {
    final teamsSnapshot = await _firestore
        .collection('organizations')
        .doc(_currentOrgId!)
        .collection('teams')
        .where('is_active', isEqualTo: true)
        .count()
        .get();
    return teamsSnapshot.count ?? 0;
  }
  
  /// Get current coach count for organization
  static Future<int> _getCurrentCoachCount() async {
    final coachesSnapshot = await _firestore
        .collection('organizations')
        .doc(_currentOrgId!)
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('is_active', isEqualTo: true)
        .count()
        .get();
    return coachesSnapshot.count ?? 0;
  }
  
  /// Clear organization context (for logout)
  static void clear() {
    _currentOrgId = null;
    _currentOrg = null;
    _currentSubscription = null;
    _userPermissions = null;
    _logger.i('🧹 Organization context cleared');
  }
  
  /// Get organization-scoped collection reference
  static CollectionReference getCollection(String collectionName) {
    if (_currentOrgId == null) {
      throw Exception('Organization context not initialized');
    }
    
    return _firestore
        .collection('organizations')
        .doc(_currentOrgId!)
        .collection(collectionName);
  }
  
  /// Refresh organization context
  static Future<void> refresh() async {
    if (_currentOrgId != null) {
      await setCurrentOrganization(_currentOrgId!);
    }
  }
}