# 🚀 Navigation Guidelines for HRMS App

## ⚠️ CRITICAL RULE: Always Use GoRouter

**NEVER use `Navigator.push()`, `Navigator.pop()`, or any Navigator methods for page navigation in this app.**

### ❌ DON'T USE:
```dart
// WRONG - Creates separate navigation stack
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SomePage()),
);

// WRONG - Inconsistent with app routing
Navigator.pop(context);

// WRONG - Direct navigation without route management
Navigator.pushReplacement(context, MaterialPageRoute(...));
```

### ✅ ALWAYS USE:
```dart
// CORRECT - Uses app's routing system
context.go('/route/path');

// CORRECT - Programmatic navigation
context.push('/route/path');

// CORRECT - Go back in route stack
context.pop();

// CORRECT - Replace current route
context.pushReplacement('/route/path');
```

## 🏗️ Why GoRouter Only?

### Problems with Mixed Navigation:
1. **Bottom Navigation Breaks**: Navigator.push() creates separate stack
2. **State Management Issues**: Multiple navigation contexts conflict
3. **Back Button Confusion**: Different back button behaviors
4. **Route Conflicts**: App routing vs manual navigation conflicts
5. **Context Isolation**: Pages lose access to shell navigation

### Benefits of GoRouter Consistency:
1. **Unified Navigation**: All pages use same navigation context
2. **Shell Integration**: Bottom navigation works everywhere
3. **State Persistence**: Navigation state properly managed
4. **Consistent UX**: Same navigation behavior throughout app
5. **Debuggable**: Clear route hierarchy and navigation flow

## 📋 Implementation Rules

### 1. Route Definition
All new pages MUST be added to `main.dart` routes:

```dart
// Add new routes to appropriate shell
GoRoute(
  path: '/section/page-name',
  builder: (context, state) => BackButtonListener(
    onBackButtonPressed: () async {
      // Handle back button if needed
      return true;
    },
    child: AuthWrapper(child: YourPageWidget()),
  ),
),
```

### 2. Navigation Calls
```dart
// Simple navigation
context.go('/tenant/dashboard');

// Navigation with parameters
context.go('/tenant/invoice/${invoiceId}');

// Navigation with query parameters
context.go('/tenant/billing?filter=unpaid');

// Conditional navigation
if (condition) {
  context.go('/tenant/profile');
} else {
  context.go('/tenant/dashboard');
}
```

### 3. Shell Route Structure
```
Main App
├── Owner Shell (/owner/*)
│   ├── Dashboard
│   ├── Properties
│   ├── Tenants
│   └── Billing
└── Tenant Shell (/tenant/*)
    ├── Dashboard
    ├── Billing
    ├── Profile
    ├── More
    └── Invoice (NEW)
```

### 4. Back Button Handling
```dart
// In route definition
BackButtonListener(
  onBackButtonPressed: () async {
    // Custom back behavior if needed
    if (someCondition) {
      context.go('/specific/route');
      return true; // Prevent default
    }
    return false; // Allow default back
  },
  child: YourWidget(),
)
```

## 🚨 Common Mistakes to Avoid

### 1. Modal/Dialog Navigation
```dart
// ❌ DON'T - Opens in separate context
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    // Content
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context); // ❌ WRONG
          Navigator.push(context, MaterialPageRoute(...)); // ❌ WRONG
        }
      )
    ]
  )
);

// ✅ DO - Close dialog first, then navigate
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(dialogContext); // ✅ Close dialog only
          context.go('/target/route'); // ✅ Use GoRouter
        }
      )
    ]
  )
);
```

### 2. Conditional Navigation
```dart
// ❌ DON'T
if (user.isOwner) {
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (context) => OwnerDashboard(),
  ));
} else {
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (context) => TenantDashboard(),
  ));
}

// ✅ DO
if (user.isOwner) {
  context.go('/owner/dashboard');
} else {
  context.go('/tenant/dashboard');
}
```

### 3. Form Submission Navigation
```dart
// ❌ DON'T
void _submitForm() async {
  if (await submitData()) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => SuccessPage(),
    ));
  }
}

// ✅ DO  
void _submitForm() async {
  if (await submitData()) {
    context.go('/success');
  }
}
```

## 📝 Migration Checklist

When converting existing Navigator code to GoRouter:

- [ ] Add route definition in `main.dart`
- [ ] Replace `Navigator.push()` with `context.go()`
- [ ] Replace `Navigator.pop()` with `context.pop()` or route navigation
- [ ] Update back button handling if custom behavior needed
- [ ] Test bottom navigation works on new page
- [ ] Verify state management works correctly
- [ ] Test hardware back button behavior
- [ ] Ensure no route conflicts

## 🎯 Benefits After Full Migration

1. **Consistent UX**: Same navigation behavior everywhere
2. **Reliable Bottom Nav**: Works on all pages
3. **Predictable Back Button**: Consistent back button behavior  
4. **Better State Management**: Single navigation context
5. **Easier Debugging**: Clear route hierarchy
6. **Better Performance**: No multiple navigation stacks

## 🔧 Debugging Navigation Issues

If navigation problems occur:

1. Check if route is defined in `main.dart`
2. Verify route path matches exactly
3. Ensure no Navigator methods are used
4. Check shell route structure
5. Verify BackButtonListener implementation
6. Test on both debug and release builds

---

**Remember: CONSISTENCY IS KEY. Always use GoRouter for ALL navigation in this app.** 🎯
