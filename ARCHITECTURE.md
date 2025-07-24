# HRMS App Architecture

## 🏗️ Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App-wide constants
│   ├── routing/            # Navigation & routing
│   ├── utils/              # Utility functions
│   └── widgets/            # Reusable widgets
├── features/               # Feature modules
│   ├── auth/              # Authentication feature
│   ├── common/            # Shared features
│   ├── admin/             # Admin features
│   ├── tenant/            # Tenant features
│   └── owner/             # Owner features
├── services/              # Business logic services
├── utils/                 # Legacy utils (to be moved)
├── widgets/               # Legacy widgets (to be moved)
└── main.dart              # App entry point
```

## 🎯 Architecture Principles

### 1. Clean Architecture
- **Separation of Concerns**: UI, Business Logic, Data layers separated
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Single Responsibility**: Each class has one reason to change

### 2. Feature-Based Structure
- **Auth Feature**: Login, Signup, Registration
- **Owner Feature**: Dashboard, Property Management, Tenant Management
- **Tenant Feature**: Tenant Dashboard, Billing, Profile
- **Admin Feature**: Admin Dashboard, User Management

### 3. Core Module
- **Constants**: App-wide constants and configurations
- **Routing**: Navigation service, route definitions, navigation observer
- **Utils**: Validation, formatting, helper functions
- **Widgets**: Reusable UI components

## 📁 Directory Structure Details

### Core Module
```
core/
├── constants/
│   └── app_constants.dart      # App-wide constants
├── routing/
│   ├── app_routes.dart         # Route definitions
│   ├── navigation_observer.dart # Navigation debugging
│   └── navigation_service.dart # Navigation utilities
├── utils/
│   └── validators.dart         # Form validation
└── widgets/
    └── loading_widget.dart     # Reusable loading widget
```

### Feature Module Structure
```
features/
├── auth/
│   ├── data/                  # Data layer
│   ├── domain/                # Business logic
│   └── presentation/          # UI layer
├── owner/
│   ├── data/
│   ├── domain/
│   └── presentation/
└── tenant/
    ├── data/
    ├── domain/
    └── presentation/
```

## 🔄 Migration Plan

### Phase 1: Core Structure ✅
- [x] Create core directories
- [x] Move routing files to core/routing
- [x] Create app constants
- [x] Create validators utility
- [x] Create reusable widgets

### Phase 2: Feature Migration
- [ ] Move auth screens to features/auth
- [ ] Move owner screens to features/owner
- [ ] Move tenant screens to features/tenant
- [ ] Update all import paths

### Phase 3: Clean Architecture
- [ ] Implement data layer (repositories)
- [ ] Implement domain layer (use cases)
- [ ] Implement presentation layer (controllers/blocs)
- [ ] Add dependency injection

### Phase 4: State Management
- [ ] Implement Provider/Riverpod
- [ ] Create state management for each feature
- [ ] Remove manual state management

## 🎨 Design Patterns

### 1. Repository Pattern
```dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  // Implementation
}
```

### 2. Use Case Pattern
```dart
class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  Future<Result<User>> execute(String email, String password) {
    // Business logic
  }
}
```

### 3. BLoC Pattern (Future)
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  
  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
}
```

## 🚀 Benefits

1. **Maintainability**: Clear separation of concerns
2. **Scalability**: Easy to add new features
3. **Testability**: Each layer can be tested independently
4. **Reusability**: Core components can be reused
5. **Debugging**: Navigation observer helps debug routing issues
6. **Consistency**: Standardized patterns across the app

## 📝 Next Steps

1. **Complete Migration**: Move all screens to feature modules
2. **Add State Management**: Implement Provider/Riverpod
3. **Add Tests**: Unit tests for each layer
4. **Add Documentation**: API documentation and code comments
5. **Performance Optimization**: Implement caching and optimization 