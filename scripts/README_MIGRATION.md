# Safe Data Migration Instructions

## 🎯 **Purpose**:
Move your receptionist's payment data and training sessions from global collections to your secure organization scope (`UYM9gTWj8o2HgEcOFpsG`).

## 📋 **What Will Be Migrated:**

### **Players (4 players with payments):**
- **Varga Bence** (`4KO9pBQQIQEncfrtHmXj`) - with payments
- **Valkai Zsolt** (`4xDRyCeQJEQTpDyTYTHp`)
- **Tóth Roland** (`ABpFLvYzZQXBRYAXjnta`)
- **Bognár Máté Zsolt** (`Qrw3ZoLVoVQuFGCt74q6`)

### **Training Sessions (7 sessions):**
- All training sessions with player attendance data
- Coach assignments (like "Salah", "Nincs megadva")
- Player attendance records

## 🚀 **How to Run Migration:**

### **Option 1: Command Line (Recommended)**
```bash
cd /Users/salahbensarar/AndroidStudioProjects/footballtraining
dart run scripts/safe_data_migration.dart
```

### **Option 2: From VS Code**
1. Open `scripts/safe_data_migration.dart`
2. Click "Run" or press `Ctrl+F5`

## ✅ **What the Script Does:**

1. **📊 Analysis**: Shows you exactly what will be migrated
2. **⚠️ Confirmation**: Asks for your permission before proceeding
3. **🏃 Player Migration**:
   - Copies all 4 players to `/organizations/UYM9gTWj8o2HgEcOFpsG/players/`
   - **Preserves all payment subcollections** (your receptionist's work!)
   - Adds migration metadata for tracking
4. **🏃‍♂️ Training Session Migration**:
   - Copies all 7 sessions to `/organizations/UYM9gTWj8o2HgEcOFpsG/training_sessions/`
   - Preserves player attendance data
   - Maintains coach assignments
5. **🔍 Verification**: Confirms all data was migrated correctly

## 🛡 **Safety Features:**

✅ **No Overwrites**: Existing organization data stays untouched
✅ **Payment Preservation**: All payment data is safely copied
✅ **Rollback Possible**: Original data stays until you manually delete
✅ **Verification**: Script confirms everything copied correctly
✅ **Detailed Logging**: See exactly what's happening at each step

## 📊 **Expected Results:**

**Before Migration:**
```
Global players: 4 (with payments)
Global training_sessions: 7
Org players: 25+
Org training_sessions: 0
```

**After Migration:**
```
Global players: 4 (safe to delete after verification)
Global training_sessions: 7 (safe to delete after verification)
Org players: 25+ + 4 new = 29+
Org training_sessions: 7 new
```

## ⚠️ **Important Notes:**

1. **Backup**: The script doesn't delete original data - it copies it
2. **Payments**: All receptionist payment work will be preserved
3. **IDs**: Player IDs stay the same (no conflicts)
4. **Verification**: Only delete global collections AFTER verification passes
5. **Testing**: Test the app after migration to ensure everything works

## 🎉 **After Migration:**

1. ✅ Test your app with both organizations
2. ✅ Verify receptionist can see payment data
3. ✅ Check training sessions display correctly
4. ✅ Only then delete global collections: `players`, `training_sessions`, `organization_setup_progress`

## ❓ **If Something Goes Wrong:**

1. **Don't Panic**: Original data is still in global collections
2. **Check Logs**: The script shows detailed progress
3. **Manual Verification**: Check Firebase Console to see migrated data
4. **Rollback**: Delete migrated data and try again if needed

---

**🚀 Ready to run? Execute: `dart run scripts/safe_data_migration.dart`**