# Core Files to Highlight in Thesis Defense

## 🏗 **Primary Architecture Files**

### **1. Multi-Tenant Security Core**
- `lib/services/organization_context.dart` - Organization context management
- `lib/services/scoped_firestore_service.dart` - Secure data access layer
- `lib/services/organization_setup_service.dart` - Organization initialization
- `firestore.rules` - Database security rules

### **2. Authentication & Authorization**
- `lib/services/auth_service.dart` - Firebase authentication integration
- `lib/views/login/login_page.dart` - User authentication interface
- `lib/models/user_model.dart` - User data structure

### **3. Role-Based Access Control**
- `lib/views/admin/admin_screen.dart` - Administrative interface
- `lib/views/coach/coach_screen.dart` - Coach management interface
- `lib/services/coach_dashboard_service.dart` - Coach-specific operations

## 🌐 **Integration & External Services**

### **4. MLSZ League Integration** ⭐
- `lib/services/mlsz_integration_service.dart` - Web scraping with Hungarian encoding
- `lib/utils/hungarian_text_utils.dart` - Unicode character handling
- `lib/data/models/mlsz_models.dart` - League data models
- `lib/views/mlsz/` - League standings UI

### **5. Payment Management System**
- `lib/services/payment_service.dart` - Financial transaction handling
- `lib/views/receptionist/payment_management_page.dart` - Payment interface
- `lib/models/payment_model.dart` - Payment data structure

## 📱 **User Interface Architecture**

### **6. Responsive Design System**
- `lib/widgets/` - Reusable UI components
- `lib/config/app_theme.dart` - Consistent theming
- `lib/views/` - Screen implementations for different roles

### **7. Core Models & Data Structures**
- `lib/models/player_model.dart` - Player entity
- `lib/models/training_session_model.dart` - Training session data
- `lib/models/organization_model.dart` - Organization structure

## 🔧 **Configuration & Setup**

### **8. Application Configuration**
- `lib/config/firebase_config.dart` - Firebase service configuration
- `lib/main.dart` - Application entry point and initialization
- `pubspec.yaml` - Dependencies and project configuration

## 💡 **Key Technical Demonstrations**

### **During Defense, Focus On:**

1. **Security Architecture** (`lib/services/scoped_firestore_service.dart:45-67`)
   ```dart
   static void _validateOrganizationContext() {
     if (!OrganizationContext.isInitialized) {
       throw const OrganizationContextException(
         'Organization context must be initialized before accessing scoped data.'
       );
     }
   }
   ```

2. **Hungarian Encoding Solution** (`lib/services/mlsz_integration_service.dart:120-135`)
   ```dart
   static String _smartFixEncoding(String text) {
     // Smart corruption detection and Unicode fixing
     bool needsFix = text.contains('Ã') || text.contains('Å');
     if (!needsFix) return text;
     // Character mapping for Hungarian letters...
   }
   ```

3. **Multi-Tenant Data Access** (`lib/services/scoped_firestore_service.dart:25-35`)
   ```dart
   static CollectionReference get players => _firestore
       .collection('organizations')
       .doc(OrganizationContext.currentOrganizationId)
       .collection('players');
   ```

## 📊 **Files Count Summary**

- **Core Architecture**: 15 critical files
- **User Interfaces**: 25+ screen implementations
- **Services**: 20+ business logic services
- **Models**: 15+ data structures
- **Configuration**: 5 setup files

**Total Clean Codebase**: ~80 focused, production-ready files

---

*These files represent the core technical achievements of your thesis project and demonstrate advanced software engineering principles including multi-tenant security, international character handling, and role-based access control.*