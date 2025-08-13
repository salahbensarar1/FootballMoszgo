import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Organization model for multi-tenant SaaS support
class Organization extends Equatable {
  final String id;
  final String name;
  final String slug; // URL-friendly identifier
  final String address;
  final String? phoneNumber;
  final String? email;
  final String? contactEmail;
  final String? website;
  final String? logoUrl;
  final OrganizationType type;
  final String adminUserId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // active, suspended, cancelled
  final String timezone;
  final String defaultCurrency;
  final Map<String, dynamic> settings;
  final List<String> allowedDomains;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.address,
    this.phoneNumber,
    this.email,
    this.contactEmail,
    this.website,
    this.logoUrl,
    required this.type,
    required this.adminUserId,
    required this.createdAt,
    this.updatedAt,
    this.status = 'active',
    this.timezone = 'UTC',
    this.defaultCurrency = 'USD',
    this.settings = const {},
    this.allowedDomains = const [],
  });

  /// Create organization from Firestore document
  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? doc.id,
      address: data['address'] ?? '',
      phoneNumber: data['phone_number'],
      email: data['email'],
      contactEmail: data['contact_email'],
      website: data['website'],
      logoUrl: data['logo_url'],
      type: OrganizationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => OrganizationType.club,
      ),
      adminUserId: data['admin_user_id'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      timezone: data['timezone'] ?? 'UTC',
      defaultCurrency: data['default_currency'] ?? 'USD',
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      allowedDomains: List<String>.from(data['allowed_domains'] ?? []),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'contact_email': contactEmail,
      'website': website,
      'logo_url': logoUrl,
      'type': type.name,
      'admin_user_id': adminUserId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
      'timezone': timezone,
      'default_currency': defaultCurrency,
      'settings': settings,
      'allowed_domains': allowedDomains,
    };
  }

  /// Create a copy with updated fields
  Organization copyWith({
    String? id,
    String? name,
    String? slug,
    String? address,
    String? phoneNumber,
    String? email,
    String? contactEmail,
    String? website,
    String? logoUrl,
    OrganizationType? type,
    String? adminUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? timezone,
    String? defaultCurrency,
    Map<String, dynamic>? settings,
    List<String>? allowedDomains,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      contactEmail: contactEmail ?? this.contactEmail,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      type: type ?? this.type,
      adminUserId: adminUserId ?? this.adminUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      timezone: timezone ?? this.timezone,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      settings: settings ?? this.settings,
      allowedDomains: allowedDomains ?? this.allowedDomains,
    );
  }

  /// Get display name for organization type
  String get typeDisplayName {
    switch (type) {
      case OrganizationType.club:
        return 'Football Club';
      case OrganizationType.academy:
        return 'Football Academy';
      case OrganizationType.school:
        return 'School';
      case OrganizationType.other:
        return 'Other Organization';
    }
  }

  /// Check if organization is active
  bool get isActive => status == 'active';
  
  /// Check if organization is suspended
  bool get isSuspended => status == 'suspended';
  
  /// Check if organization is cancelled
  bool get isCancelled => status == 'cancelled';
  
  /// Check if organization is properly configured
  bool get isConfigured {
    return name.isNotEmpty &&
        address.isNotEmpty &&
        adminUserId.isNotEmpty &&
        slug.isNotEmpty;
  }

  /// Get organization setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return settings[key] as T? ?? defaultValue;
  }

  /// Update organization setting
  Organization updateSetting(String key, dynamic value) {
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings[key] = value;
    return copyWith(settings: updatedSettings);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    address,
    phoneNumber,
    email,
    contactEmail,
    website,
    logoUrl,
    type,
    adminUserId,
    createdAt,
    updatedAt,
    status,
    timezone,
    defaultCurrency,
    settings,
    allowedDomains,
  ];

  @override
  String toString() => 'Organization(id: $id, name: $name, type: ${type.name})';
}

/// Organization type enumeration
enum OrganizationType {
  club,
  academy,
  school,
  other;

  String get displayName {
    switch (this) {
      case OrganizationType.club:
        return 'Football Club';
      case OrganizationType.academy:
        return 'Football Academy';
      case OrganizationType.school:
        return 'School';
      case OrganizationType.other:
        return 'Other Organization';
    }
  }

  String get description {
    switch (this) {
      case OrganizationType.club:
        return 'Professional or amateur football club';
      case OrganizationType.academy:
        return 'Youth development academy';
      case OrganizationType.school:
        return 'Educational institution with sports programs';
      case OrganizationType.other:
        return 'Other type of sports organization';
    }
  }
}

/// Organization setup progress tracking
class OrganizationSetupProgress extends Equatable {
  final String organizationId;
  final bool basicInfoCompleted;
  final bool adminCreated;
  final bool teamsCreated;
  final bool playersAdded;
  final bool paymentsConfigured;
  final DateTime lastUpdated;

  const OrganizationSetupProgress({
    required this.organizationId,
    this.basicInfoCompleted = false,
    this.adminCreated = false,
    this.teamsCreated = false,
    this.playersAdded = false,
    this.paymentsConfigured = false,
    required this.lastUpdated,
  });

  /// Calculate completion percentage
  double get completionPercentage {
    int completed = 0;
    int total = 5;

    if (basicInfoCompleted) completed++;
    if (adminCreated) completed++;
    if (teamsCreated) completed++;
    if (playersAdded) completed++;
    if (paymentsConfigured) completed++;

    return completed / total;
  }

  /// Check if setup is complete
  bool get isComplete {
    return basicInfoCompleted &&
        adminCreated &&
        teamsCreated &&
        playersAdded &&
        paymentsConfigured;
  }

  /// Get next required step
  String get nextStep {
    if (!basicInfoCompleted) return 'Complete basic organization information';
    if (!adminCreated) return 'Create administrator account';
    if (!teamsCreated) return 'Create teams';
    if (!playersAdded) return 'Add players';
    if (!paymentsConfigured) return 'Configure payment settings';
    return 'Setup complete!';
  }

  /// Create from Firestore
  factory OrganizationSetupProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrganizationSetupProgress(
      organizationId: doc.id,
      basicInfoCompleted: data['basic_info_completed'] ?? false,
      adminCreated: data['admin_created'] ?? false,
      teamsCreated: data['teams_created'] ?? false,
      playersAdded: data['players_added'] ?? false,
      paymentsConfigured: data['payments_configured'] ?? false,
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'basic_info_completed': basicInfoCompleted,
      'admin_created': adminCreated,
      'teams_created': teamsCreated,
      'players_added': playersAdded,
      'payments_configured': paymentsConfigured,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create copy with updated fields
  OrganizationSetupProgress copyWith({
    String? organizationId,
    bool? basicInfoCompleted,
    bool? adminCreated,
    bool? teamsCreated,
    bool? playersAdded,
    bool? paymentsConfigured,
    DateTime? lastUpdated,
  }) {
    return OrganizationSetupProgress(
      organizationId: organizationId ?? this.organizationId,
      basicInfoCompleted: basicInfoCompleted ?? this.basicInfoCompleted,
      adminCreated: adminCreated ?? this.adminCreated,
      teamsCreated: teamsCreated ?? this.teamsCreated,
      playersAdded: playersAdded ?? this.playersAdded,
      paymentsConfigured: paymentsConfigured ?? this.paymentsConfigured,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    organizationId,
    basicInfoCompleted,
    adminCreated,
    teamsCreated,
    playersAdded,
    paymentsConfigured,
    lastUpdated,
  ];
}