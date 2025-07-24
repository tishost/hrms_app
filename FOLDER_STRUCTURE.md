# 📁 **HRMS App - New Folder Structure**

## 🏗️ **Clean Architecture + Feature-based Structure**

```
lib/
├── main.dart
├── core/                           # Core functionality
│   ├── constants/
│   │   └── app_constants.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── security_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── widgets/
│   │   ├── loading_widget.dart
│   │   └── loading_widgets.dart
│   ├── providers/
│   │   ├── app_providers.dart
│   │   └── app_providers.g.dart
│   └── utils/
│       ├── api_config.dart
│       ├── app_colors.dart
│       ├── country_helper.dart
│       ├── device_helper.dart
│       ├── permission_helper.dart
│       └── validators.dart
├── features/                       # Feature-based modules
│   ├── auth/                       # Authentication feature
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── signup_screen.dart
│   │   │   │   ├── phone_entry_screen.dart
│   │   │   │   └── owner_registration_screen.dart
│   │   │   └── widgets/
│   │   └── data/
│   │       └── services/
│   │           ├── auth_service.dart
│   │           ├── global_otp_settings.dart
│   │           └── otp_settings_service.dart
│   ├── owner/                      # Owner feature
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── property_list_screen.dart
│   │   │   │   ├── property_entry_screen.dart
│   │   │   │   ├── unit_list_screen.dart
│   │   │   │   ├── unit_entry_screen.dart
│   │   │   │   ├── invoice_list_screen.dart
│   │   │   │   ├── invoice_pdf_screen.dart
│   │   │   │   ├── invoice_payment_screen.dart
│   │   │   │   ├── reports_screen.dart
│   │   │   │   └── profile_screen.dart
│   │   │   └── widgets/
│   │   │       ├── custom_bottom_nav.dart
│   │   │       └── custom_drawer.dart
│   │   └── data/
│   │       └── services/
│   │           ├── dashboard_service.dart
│   │           ├── property_service.dart
│   │           ├── unit_service.dart
│   │           └── report_service.dart
│   ├── tenant/                     # Tenant feature
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── tenant_list_screen.dart
│   │   │   │   ├── tenant_entry_screen.dart
│   │   │   │   ├── tenant_details_screen.dart
│   │   │   │   ├── tenant_dashboard_screen.dart
│   │   │   │   ├── tenant_registration_screen.dart
│   │   │   │   ├── tenant_profile_screen.dart
│   │   │   │   └── tenant_billing_screen.dart
│   │   │   └── widgets/
│   │   │       └── tenant_bottom_nav.dart
│   │   └── data/
│   │       └── services/
│   ├── admin/                      # Admin feature
│   │   ├── presentation/
│   │   │   └── screens/
│   │   └── data/
│   │       └── services/
│   └── common/                     # Common/shared features
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── universal_pdf_screen.dart
│       │   │   ├── pdf_viewer_screen.dart
│       │   │   ├── invoice_pdf_viewer_screen.dart
│       │   │   └── debug_screen.dart
│       │   └── widgets/
│       │       └── otp_settings_widget.dart
│       └── data/
│           └── services/
├── screens/                        # Old structure (to be removed)
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── tenant_list_screen.dart
│   └── ... (other old files)
├── services/                       # Old structure (to be removed)
│   ├── auth_service.dart
│   ├── dashboard_service.dart
│   └── ... (other old files)
├── widgets/                        # Old structure (to be removed)
│   ├── custom_bottom_nav.dart
│   ├── custom_drawer.dart
│   └── ... (other old files)
├── utils/                          # Old structure (to be removed)
│   ├── api_config.dart
│   ├── app_colors.dart
│   └── ... (other old files)
└── helpers/                        # Old structure (to be removed)
    └── country_helper.dart
```

## 🎯 **Benefits of New Structure**

### **1. Feature-based Organization**
- ✅ **Auth Feature**: All authentication-related code in one place
- ✅ **Owner Feature**: All owner-specific functionality grouped
- ✅ **Tenant Feature**: All tenant-related screens and services
- ✅ **Common Feature**: Shared components and utilities

### **2. Clean Architecture**
- ✅ **Presentation Layer**: UI components (screens, widgets)
- ✅ **Data Layer**: Services, repositories, data sources
- ✅ **Domain Layer**: Business logic, entities, use cases (future)

### **3. Maintainability**
- ✅ **Easy to Find**: Related code is grouped together
- ✅ **Scalable**: Easy to add new features
- ✅ **Testable**: Clear separation of concerns
- ✅ **Reusable**: Common components can be shared

## 🔄 **Migration Status**

### **✅ Completed:**
- ✅ Created new folder structure
- ✅ Moved auth files to `features/auth/`
- ✅ Moved owner files to `features/owner/`
- ✅ Moved tenant files to `features/tenant/`
- ✅ Moved common files to `features/common/`
- ✅ Moved utils to `core/utils/`

### **🔄 Next Steps:**
1. **Update Imports**: Fix all import statements in moved files
2. **Remove Old Folders**: Delete old `screens/`, `services/`, `widgets/`, `utils/`, `helpers/` folders
3. **Update main.dart**: Ensure all imports point to new locations
4. **Test Navigation**: Verify all routes work correctly
5. **Update Documentation**: Update any documentation references

## 📝 **Import Examples**

### **Old Imports:**
```dart
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'widgets/custom_bottom_nav.dart';
import 'utils/api_config.dart';
```

### **New Imports:**
```dart
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'core/utils/api_config.dart';
```

## 🚀 **Benefits Achieved**

### **Organization:**
- 🧹 **Clean Structure**: Logical grouping of related code
- 🧹 **Easy Navigation**: Find files quickly
- 🧹 **Scalable**: Easy to add new features

### **Development:**
- ⚡ **Faster Development**: Related code is together
- ⚡ **Better Testing**: Clear separation for unit tests
- ⚡ **Code Reuse**: Common components are shared

### **Maintenance:**
- 🔧 **Easy Updates**: Change one feature without affecting others
- 🔧 **Clear Dependencies**: Easy to understand relationships
- 🔧 **Better Documentation**: Structure is self-documenting

---

**🎉 The app now follows modern Flutter architecture patterns with clean, maintainable, and scalable code organization!** 