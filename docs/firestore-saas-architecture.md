# Football Training Manager - SaaS Firestore Architecture

## Overview
Multi-tenant SaaS architecture where each football club operates in complete isolation with their own data, users, and subscription management.

## Collection Structure

### Root Level Collections

#### 1. `organizations` (Top-level tenant isolation)
```
organizations/{orgId}
├── name: string
├── slug: string (unique, URL-friendly)
├── created_at: timestamp
├── updated_at: timestamp
├── contact_email: string
├── phone: string
├── address: object
├── logo_url: string
├── website: string
├── timezone: string
├── default_currency: string
├── settings: object
│   ├── default_monthly_fee: number
│   ├── payment_methods: array
│   └── training_session_duration: number
└── status: string (active, suspended, cancelled)
```

#### 2. `subscriptions` (Licensing & billing)
```
subscriptions/{subscriptionId}
├── organization_id: string (reference to org)
├── plan_id: string (basic, premium, enterprise)
├── status: string (active, past_due, cancelled, trialing)
├── current_period_start: timestamp
├── current_period_end: timestamp
├── trial_end: timestamp
├── created_at: timestamp
├── updated_at: timestamp
├── price_per_month: number
├── currency: string
├── max_players: number
├── max_teams: number
├── max_coaches: number
├── features: object
│   ├── analytics: boolean
│   ├── reports: boolean
│   ├── api_access: boolean
│   └── priority_support: boolean
├── payment_method: object
└── last_payment: object
```

#### 3. `payment_history` (Billing records)
```
payment_history/{paymentId}
├── organization_id: string
├── subscription_id: string
├── amount: number
├── currency: string
├── status: string (succeeded, failed, pending)
├── payment_date: timestamp
├── payment_method: string
├── invoice_url: string
└── description: string
```

### Organization-Scoped Collections
All user data is scoped under organizations for complete isolation:

#### 4. `organizations/{orgId}/users` (Organization members)
```
organizations/{orgId}/users/{userId}
├── uid: string (Firebase Auth UID)
├── email: string
├── name: string
├── role: string (super_admin, admin, coach, receptionist)
├── phone: string
├── avatar_url: string
├── created_at: timestamp
├── updated_at: timestamp
├── last_login: timestamp
├── is_active: boolean
├── permissions: array
├── created_by: string (userId)
└── profile: object
```

#### 5. `organizations/{orgId}/teams`
```
organizations/{orgId}/teams/{teamId}
├── name: string
├── age_group: string
├── created_at: timestamp
├── updated_at: timestamp
├── is_active: boolean
├── coach_id: string
├── assistant_coaches: array
├── training_schedule: object
├── number_of_players: number (calculated)
├── payment_fee: number (overrides default)
├── currency: string
└── season: string
```

#### 6. `organizations/{orgId}/players`
```
organizations/{orgId}/players/{playerId}
├── name: string
├── email: string
├── phone: string
├── date_of_birth: timestamp
├── position: string
├── team_id: string (reference)
├── parent_contact: object
├── emergency_contact: object
├── created_at: timestamp
├── updated_at: timestamp
├── is_active: boolean
├── registration_date: timestamp
├── medical_info: object
├── jersey_number: number
└── payment_status: string (current, overdue, exempt)
```

#### 7. `organizations/{orgId}/training_sessions`
```
organizations/{orgId}/training_sessions/{sessionId}
├── team_id: string
├── coach_id: string
├── start_time: timestamp
├── end_time: timestamp
├── location: string
├── training_type: string
├── description: string
├── created_at: timestamp
├── updated_at: timestamp
├── attendance: array
│   └── {player_id: string, present: boolean, notes: string}
├── notes: string
└── weather: string
```

#### 8. `organizations/{orgId}/payments`
```
organizations/{orgId}/payments/{paymentId}
├── player_id: string
├── amount: number
├── currency: string
├── payment_date: timestamp
├── payment_method: string
├── status: string (paid, pending, overdue)
├── due_date: timestamp
├── created_at: timestamp
├── updated_at: timestamp
├── invoice_number: string
├── notes: string
├── recorded_by: string (userId)
└── receipt_url: string
```

#### 9. `organizations/{orgId}/reports` (Cached analytics)
```
organizations/{orgId}/reports/{reportId}
├── type: string (attendance, payment, performance)
├── generated_at: timestamp
├── generated_by: string (userId)
├── date_range: object
├── data: object (cached results)
├── filters: object
└── export_url: string
```

## Security Rules Strategy

### Multi-tenant Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Organization access control
    function isOrgMember(orgId) {
      return exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid));
    }
    
    function hasRole(orgId, role) {
      return get(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid)).data.role == role;
    }
    
    function isAdminOrSuperAdmin(orgId) {
      let userRole = get(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid)).data.role;
      return userRole in ['admin', 'super_admin'];
    }

    // Organizations collection - only super admins can create
    match /organizations/{orgId} {
      allow read: if isOrgMember(orgId);
      allow create: if request.auth != null; // During setup
      allow update: if isAdminOrSuperAdmin(orgId);
      allow delete: if hasRole(orgId, 'super_admin');
    }

    // Organization-scoped data
    match /organizations/{orgId}/{collection}/{docId} {
      allow read, write: if isOrgMember(orgId);
      allow create: if isOrgMember(orgId);
      allow update: if isOrgMember(orgId);
      allow delete: if isAdminOrSuperAdmin(orgId);
    }

    // Subscriptions - only system can write
    match /subscriptions/{subscriptionId} {
      allow read: if resource.data.organization_id in getUserOrgs();
      allow write: if false; // Only server-side functions
    }
  }
}
```

## Data Access Patterns

### 1. Organization Context Service
```dart
class OrganizationContext {
  static String? _currentOrgId;
  static Organization? _currentOrg;
  
  static String get currentOrgId => _currentOrgId!;
  static Organization get currentOrg => _currentOrg!;
  
  static Future<void> initialize(String userId) async {
    // Get user's organization from user profile
    final userOrgs = await getUserOrganizations(userId);
    setCurrentOrganization(userOrgs.first.id);
  }
}
```

### 2. Scoped Firestore Service
```dart
class FirestoreService {
  static CollectionReference users() =>
    _firestore.collection('organizations')
        .doc(OrganizationContext.currentOrgId)
        .collection('users');
        
  static CollectionReference teams() =>
    _firestore.collection('organizations')
        .doc(OrganizationContext.currentOrgId)
        .collection('teams');
}
```

## Migration Strategy

### Phase 1: Create New Structure
1. Create new collections with proper organization scoping
2. Keep existing collections for backward compatibility
3. Add organization_id to all existing documents

### Phase 2: Data Migration
1. Create migration scripts to move data to organization-scoped collections
2. Update all queries to use scoped collections
3. Test data isolation

### Phase 3: Security Implementation
1. Deploy new Firestore security rules
2. Update authentication flow to include organization context
3. Remove backward compatibility code

## Subscription Plans

### Basic Plan ($29/month)
- Up to 50 players
- Up to 3 teams  
- 2 coaches
- Basic reports
- Email support

### Premium Plan ($79/month)
- Up to 200 players
- Up to 10 teams
- 10 coaches
- Advanced analytics
- Payment tracking
- Priority support

### Enterprise Plan ($199/month)
- Unlimited players/teams/coaches
- API access
- Custom reports
- White-label options
- Dedicated support

## Implementation Benefits

1. **Complete Data Isolation**: Each club's data is completely separate
2. **Scalable**: Can handle thousands of clubs without performance issues
3. **Secure**: Proper multi-tenant security rules
4. **Flexible Billing**: Per-organization subscription management
5. **Feature Gating**: Different features based on subscription level
6. **Compliance Ready**: Easier GDPR compliance with data isolation