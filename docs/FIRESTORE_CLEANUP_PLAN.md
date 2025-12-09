# Firestore Database Cleanup Plan

## 🎯 **Goal**: Clean database for thesis defense and new organization testing

## ❌ **COLLECTIONS TO DELETE** (Global/Deprecated):

### 1. **`organization_setup_progress`**
- **Purpose**: One-time setup tracking collection
- **Status**: No longer needed after setup completion
- **Action**: **DELETE ENTIRE COLLECTION**

### 2. **`players`** (Global)
- **Purpose**: Old global players collection (security vulnerability)
- **Status**: Data should be in `/organizations/{orgId}/players/` only
- **Current Data**: Should have been migrated to organization scopes
- **Action**: **DELETE ENTIRE COLLECTION**

### 3. **`training_sessions`** (Global)
- **Purpose**: Old global training sessions (security vulnerability)
- **Status**: Data should be in `/organizations/{orgId}/training_sessions/` only
- **Action**: **DELETE ENTIRE COLLECTION**

### 4. **`users`** (Global)
- **Purpose**: Old global users collection (security vulnerability)
- **Status**: Data should be in `/organizations/{orgId}/users/` only
- **Action**: **DELETE ENTIRE COLLECTION**

## ✅ **COLLECTIONS TO KEEP** (Organization-Scoped):

### **UYM9gTWj8o2HgEcOFpsG** (Nagykoros Club) - PRIMARY ORG:
```
/organizations/UYM9gTWj8o2HgEcOFpsG/
├── players/           ✅ KEEP (real data)
├── training_sessions/ ✅ KEEP (real data)
├── users/            ✅ KEEP (real users)
├── payments/         ✅ KEEP (payment data)
├── teams/            ✅ KEEP (team data)
└── reports/          ✅ KEEP (analytics)
```

### **MnEe1BZMU2KOPallucHP** (Test Organization):
```
/organizations/MnEe1BZMU2KOPallucHP/
├── payments/         ⚠️ OPTIONAL (test data)
├── players/          ⚠️ OPTIONAL (test data)
├── reports/          ⚠️ OPTIONAL (test data)
├── teams/            ⚠️ OPTIONAL (test data)
├── training_sessions/⚠️ OPTIONAL (test data)
└── users/            ⚠️ OPTIONAL (test data)
```

## 🎯 **EXECUTION PLAN:**

### **Step 1: Backup Important Data**
Before deleting, ensure `UYM9gTWj8o2HgEcOFpsG` has all needed data

### **Step 2: Delete Global Collections**
```bash
# These are the deprecated collections to remove:
- organization_setup_progress
- players
- training_sessions
- users
```

### **Step 3: Clean Test Organization** (Optional)
- Keep `MnEe1BZMU2KOPallucHP` if you want to test new organization creation
- Delete it if you want to start fresh

### **Step 4: Test New Organization Creation**
After cleanup, test creating a brand new organization to validate the flow

## ⚠️ **SAFETY NOTES:**
- **DO NOT DELETE** the `/organizations/` collection itself
- **KEEP** `UYM9gTWj8o2HgEcOFpsG` - this is your main organization with real data
- **Firestore Rules** will automatically block access to deleted global collections

## 🎉 **Expected Result:**
- Clean database with only organization-scoped data
- Secure multi-tenant architecture
- Ready for thesis demonstration
- Ability to test new organization creation