# Session Timeout Handling Guide

## Overview
This guide explains how the automatic session timeout handling works in the HRMS Flutter app.

## How It Works

### 1. Automatic Token Validation
- When the app starts, it checks if a stored token exists
- If token exists, it validates it against the server
- If token is invalid/expired, user is redirected to login screen

### 2. Session Timeout Detection
- All API calls use `AuthService.authenticatedRequest()` method
- If server returns 401 (Unauthorized), session is considered expired
- User is automatically redirected to login screen
- Stored token is cleared

## Usage

### For API Calls
Instead of manually handling tokens, use the `authenticatedRequest` method:

```dart
// ❌ Old way (manual token handling)
final token = await AuthService.getToken();
final response = await http.get(
  Uri.parse('${getApiUrl()}/properties'),
  headers: {'Authorization': 'Bearer $token'},
);

// ✅ New way (automatic session handling)
final response = await AuthService.authenticatedRequest('/properties');
```

### Available Methods
```dart
// GET request
final response = await AuthService.authenticatedRequest('/properties');

// POST request with body
final response = await AuthService.authenticatedRequest(
  '/properties',
  method: 'POST',
  body: {'name': 'Property Name'},
);

// PUT request
final response = await AuthService.authenticatedRequest(
  '/properties/1',
  method: 'PUT',
  body: {'name': 'Updated Name'},
);

// DELETE request
final response = await AuthService.authenticatedRequest(
  '/properties/1',
  method: 'DELETE',
);
```

## Error Handling

### Session Expired
When session expires:
1. Token is automatically cleared from storage
2. User is redirected to login screen
3. All previous routes are removed from navigation stack

### Network Errors
- Network errors are re-thrown for UI handling
- Session timeout errors are handled automatically

## Backend Requirements

### Laravel API
- All protected routes should return 401 for invalid/expired tokens
- The `/api/user` endpoint is used for token validation
- Middleware `auth:sanctum` handles token validation

### Example Response
```json
{
  "message": "Unauthorized"
}
```
Status: 401

## Testing

### Test Session Timeout
1. Login to the app
2. Manually delete the token from server (or wait for expiration)
3. Try to make any API call
4. App should automatically redirect to login screen

### Test Token Validation
1. Clear stored token from app
2. Restart app
3. Should redirect to login screen

## Migration Guide

### Update Existing Services
Replace manual token handling with `authenticatedRequest`:

```dart
// Before
class PropertyService {
  static Future<List<Map<String, dynamic>>> getProperties(String token) async {
    final response = await http.get(
      Uri.parse('${getApiUrl()}/properties'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // ... handle response
  }
}

// After
class PropertyService {
  static Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await AuthService.authenticatedRequest('/properties');
    // ... handle response
  }
}
```

### Update UI Calls
Remove token parameter from service calls:

```dart
// Before
final token = await AuthService.getToken();
final properties = await PropertyService.getProperties(token);

// After
final properties = await PropertyService.getProperties();
```

## Benefits

1. **Automatic Session Management**: No need to manually handle token expiration
2. **Better UX**: Users are automatically redirected when session expires
3. **Consistent Error Handling**: All API calls handle session timeout the same way
4. **Reduced Code**: Less boilerplate code for token management
5. **Security**: Tokens are automatically cleared when invalid

## Troubleshooting

### Common Issues

1. **Not redirecting to login**: Check if `navigatorKey` is properly set in `MaterialApp`
2. **Infinite redirect loop**: Ensure login screen doesn't use `authenticatedRequest`
3. **Token not clearing**: Check if `removeToken()` is working properly

### Debug Mode
Enable debug logging to see session timeout events:

```dart
// Add to your service calls for debugging
print('API Response Status: ${response.statusCode}');
``` 