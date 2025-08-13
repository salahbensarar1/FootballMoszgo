# 🔥 Firestore Permission Fix

## Problem Analysis
You're getting permission-denied errors during organization setup because:

1. **Complex Rules**: Your current Firestore rules expect organization membership, but during initial setup, no organization exists yet.
2. **Authentication Flow**: The setup process needs to create organizations before users exist in them.

## Quick Fix - Temporary Simple Rules

Replace your current `firestore.rules` with this simpler version for initial testing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Simple rule: Allow all authenticated users to read/write during setup phase
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## After Setup Works - Enhanced Rules

Once your setup flow is working, replace with these enhanced rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Organizations - allow creation during setup, restrict updates to admins
    match /organizations/{orgId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null; // During setup
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.admin_user_id ||
         exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid)));
      allow delete: if request.auth != null && request.auth.uid == resource.data.admin_user_id;
    }
    
    // Setup progress tracking
    match /organization_setup_progress/{docId} {
      allow read, write: if request.auth != null;
    }
    
    // Global users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Organization-scoped collections
    match /organizations/{orgId}/users/{userId} {
      allow read, write: if request.auth != null;
    }
    
    match /organizations/{orgId}/teams/{teamId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid));
    }
    
    match /organizations/{orgId}/players/{playerId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid));
    }
    
    match /organizations/{orgId}/training_sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid));
    }
    
    match /organizations/{orgId}/payments/{paymentId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid));
    }
    
    // Any other organization subcollections
    match /organizations/{orgId}/{collection}/{docId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/organizations/$(orgId)/users/$(request.auth.uid));
    }
  }
}
```

## Steps to Fix:

### 1. Immediate Fix (Do this now):
```bash
# In Firebase Console:
1. Go to Firestore Database
2. Click "Rules" tab
3. Replace with the simple rules above
4. Click "Publish"
```

### 2. Test the Setup:
```dart
// Add this to test your setup flow
import 'package:footballtraining/services/firestore_debug_service.dart';

// In your setup wizard or main.dart:
final debugService = FirestoreDebugService();
await debugService.testFirestoreAccess();
await debugService.testOrganizationCreation();
```

### 3. Debug Authentication:
```dart
// Add this before organization creation:
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
print('Is anonymous: ${FirebaseAuth.instance.currentUser?.isAnonymous}');
```

## Root Cause Analysis:

Your error happens because:
1. ❌ Complex rules expect user to be member of organization
2. ❌ During setup, organization doesn't exist yet
3. ❌ Chicken-and-egg problem: Can't create org without membership, can't have membership without org

## The Solution:

1. ✅ Use simple rules during setup phase
2. ✅ Create organization first (with anonymous or new user auth)
3. ✅ Add user to organization
4. ✅ Switch to complex rules for production

Try the simple rules first, and your setup should work immediately! 🚀
