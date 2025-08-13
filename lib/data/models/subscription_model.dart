import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription model for SaaS licensing system
class Subscription {
  final String id;
  final String organizationId;
  final String planId;
  final String status; // active, past_due, cancelled, trialing
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialEnd;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double pricePerMonth;
  final String currency;
  final int maxPlayers;
  final int maxTeams;
  final int maxCoaches;
  final Map<String, bool> features;
  final Map<String, dynamic>? paymentMethod;
  final Map<String, dynamic>? lastPayment;

  const Subscription({
    required this.id,
    required this.organizationId,
    required this.planId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialEnd,
    required this.createdAt,
    required this.updatedAt,
    required this.pricePerMonth,
    required this.currency,
    required this.maxPlayers,
    required this.maxTeams,
    required this.maxCoaches,
    required this.features,
    this.paymentMethod,
    this.lastPayment,
  });

  /// Create Subscription from Firestore document
  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Subscription(
      id: doc.id,
      organizationId: data['organization_id'] ?? '',
      planId: data['plan_id'] ?? '',
      status: data['status'] ?? 'active',
      currentPeriodStart: (data['current_period_start'] as Timestamp).toDate(),
      currentPeriodEnd: (data['current_period_end'] as Timestamp).toDate(),
      trialEnd: data['trial_end'] != null 
          ? (data['trial_end'] as Timestamp).toDate() 
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      pricePerMonth: (data['price_per_month'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      maxPlayers: data['max_players'] ?? 0,
      maxTeams: data['max_teams'] ?? 0,
      maxCoaches: data['max_coaches'] ?? 0,
      features: Map<String, bool>.from(data['features'] ?? {}),
      paymentMethod: data['payment_method'],
      lastPayment: data['last_payment'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'organization_id': organizationId,
      'plan_id': planId,
      'status': status,
      'current_period_start': Timestamp.fromDate(currentPeriodStart),
      'current_period_end': Timestamp.fromDate(currentPeriodEnd),
      'trial_end': trialEnd != null ? Timestamp.fromDate(trialEnd!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'price_per_month': pricePerMonth,
      'currency': currency,
      'max_players': maxPlayers,
      'max_teams': maxTeams,
      'max_coaches': maxCoaches,
      'features': features,
      'payment_method': paymentMethod,
      'last_payment': lastPayment,
    };
  }

  /// Check if subscription is active
  bool get isActive => status == 'active';

  /// Check if subscription is in trial
  bool get isTrialing => status == 'trialing';

  /// Check if trial has expired
  bool get isTrialExpired {
    if (trialEnd == null) return false;
    return DateTime.now().isAfter(trialEnd!);
  }

  /// Check if current period has expired
  bool get isPeriodExpired {
    return DateTime.now().isAfter(currentPeriodEnd);
  }

  /// Days remaining in current period
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(currentPeriodEnd)) return 0;
    return currentPeriodEnd.difference(now).inDays;
  }

  /// Create a copy with updated values
  Subscription copyWith({
    String? id,
    String? organizationId,
    String? planId,
    String? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? pricePerMonth,
    String? currency,
    int? maxPlayers,
    int? maxTeams,
    int? maxCoaches,
    Map<String, bool>? features,
    Map<String, dynamic>? paymentMethod,
    Map<String, dynamic>? lastPayment,
  }) {
    return Subscription(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      trialEnd: trialEnd ?? this.trialEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      currency: currency ?? this.currency,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      maxTeams: maxTeams ?? this.maxTeams,
      maxCoaches: maxCoaches ?? this.maxCoaches,
      features: features ?? this.features,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lastPayment: lastPayment ?? this.lastPayment,
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, organizationId: $organizationId, planId: $planId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined subscription plans
class SubscriptionPlans {
  static const String basic = 'basic';
  static const String premium = 'premium';
  static const String enterprise = 'enterprise';

  static const Map<String, Map<String, dynamic>> plans = {
    basic: {
      'name': 'Basic',
      'price': 29.0,
      'max_players': 50,
      'max_teams': 3,
      'max_coaches': 2,
      'features': {
        'analytics': false,
        'reports': true,
        'api_access': false,
        'priority_support': false,
        'custom_branding': false,
      },
    },
    premium: {
      'name': 'Premium',
      'price': 79.0,
      'max_players': 200,
      'max_teams': 10,
      'max_coaches': 10,
      'features': {
        'analytics': true,
        'reports': true,
        'api_access': false,
        'priority_support': true,
        'custom_branding': false,
      },
    },
    enterprise: {
      'name': 'Enterprise',
      'price': 199.0,
      'max_players': -1, // unlimited
      'max_teams': -1, // unlimited
      'max_coaches': -1, // unlimited
      'features': {
        'analytics': true,
        'reports': true,
        'api_access': true,
        'priority_support': true,
        'custom_branding': true,
      },
    },
  };

  static Map<String, dynamic>? getPlan(String planId) {
    return plans[planId];
  }

  static List<String> get allPlans => plans.keys.toList();
}