# Emulator PDF Test Guide

## Problem
Emulator এ PDF view করার সময় permission request আসছে না।

## Solution Applied

### 1. Simple Permission Handling
- **Android**: সব Android device এ permission request করা হয়
- **iOS**: iOS এ permission skip করা হয়
- **No Emulator Detection**: Simple approach without complex detection

### 2. Debug Features Added
- AppBar এ debug button add করা হয়েছে
- Console এ permission status এবং PDF status logs দেখানো হয়
- PDF status snackbar এ display হয়

## Test Steps

### 1. Run App in Emulator
```bash
cd hrms_app
flutter run
```

### 2. Test PDF View
1. Go to Invoices screen
2. Tap any invoice
3. Tap "View PDF" button
4. Check console logs for permission status

### 3. Debug PDF Status
1. In PDF screen, tap debug button (bug icon)
2. Check console for detailed PDF logs
3. Snackbar will show PDF status

## Expected Behavior

### Android (Both Emulator & Real Device):
- ✅ Permission dialog should appear
- ✅ User can allow/deny permission
- ✅ PDF loads after permission granted
- ✅ Console logs should show permission status

### iOS:
- ✅ No permission dialog should appear
- ✅ PDF should load directly
- ✅ Console logs should show PDF status

## Console Logs to Check

### Android (Both Emulator & Real Device):
```
Requesting storage permission for PDF download...
Permission not granted, requesting...
Permission request result: PermissionStatus.granted
```

OR

```
Requesting storage permission for PDF download...
Permission already granted
```

### iOS:
```
iOS detected, skipping permission check...
```

## Troubleshooting

### If PDF Still Doesn't Load:
1. Check console logs for errors
2. Tap debug button to see PDF status
3. Try refreshing PDF
4. Check if backend PDF endpoint is working

### If Permission Dialog Appears:
1. This should not happen in emulator
2. Permission checks have been removed
3. PDF should load directly

## Notes

- **Android**: Permission dialog shows on all Android devices
- **iOS**: No permission dialog needed
- **Simple Approach**: No complex emulator detection
- **Debug Info**: Shows PDF status and permission information
- **Console Logs**: Permission status and PDF loading information 