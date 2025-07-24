# Permission Test Guide

## ✅ **Updated App Installed!**

### 🔧 **What Was Done:**
1. ✅ **Flutter Clean**: Build cache cleared
2. ✅ **Android 13+ Support**: Added new permissions for Android 13+
3. ✅ **Multiple Permissions**: Request all possible storage permissions
4. ✅ **Fresh Install**: App reinstalled on real device

### 📱 **Test Steps:**

#### **1. Check App Info:**
1. Go to **Settings** → **Apps** → **hrms_app**
2. Check **Permissions** section
3. Should now show **Storage**, **Photos**, and **Manage files** permissions

#### **2. Test PDF View:**
1. Open **hrms_app**
2. Go to **Invoices** screen
3. Tap any invoice
4. Tap **"View PDF"** button
5. **Permission dialog should appear**
6. Tap **"Allow"**
7. PDF should load

#### **3. Test Download:**
1. In PDF screen, tap **download icon**
2. **Permission dialog should appear** (if not already granted)
3. Tap **"Allow"**
4. PDF should save to Downloads

### 🎯 **Expected Behavior:**

#### **Real Device (SM S938B):**
- ✅ Permission dialog appears
- ✅ User can allow/deny
- ✅ PDF loads after permission granted
- ✅ App info shows storage permissions

#### **Emulator:**
- ✅ Permission dialog appears
- ✅ User can allow/deny
- ✅ PDF loads after permission granted

### 🔍 **Console Logs to Check:**

```
Requesting permissions for PDF download...
Storage permission not granted, requesting...
Storage permission result: PermissionStatus.granted
Photos permission not granted, requesting...
Photos permission result: PermissionStatus.granted
Manage external storage permission not granted, requesting...
Manage external storage permission result: PermissionStatus.granted
All permissions requested
```

### 🚨 **If Still No Permission Dialog:**

#### **Check App Info:**
1. Settings → Apps → hrms_app
2. Permissions section
3. Should show "Storage", "Photos", and "Manage files" permissions

#### **Force Stop & Restart:**
1. Settings → Apps → hrms_app
2. Tap "Force stop"
3. Restart app
4. Try PDF view again

#### **Clear App Data:**
1. Settings → Apps → hrms_app
2. Storage → Clear data
3. Restart app
4. Try PDF view again

### 📋 **Troubleshooting:**

#### **If "No permissions required" still shows:**
1. Uninstall app completely
2. Reinstall from fresh build
3. Check app info again

#### **If permission dialog doesn't appear:**
1. Check console logs
2. Try different invoice
3. Restart app
4. Check device settings

### 🎉 **Success Indicators:**
- ✅ App info shows multiple permissions (Storage, Photos, Manage files)
- ✅ Multiple permission dialogs appear
- ✅ PDF loads successfully
- ✅ Download works
- ✅ Console shows all permission logs

**Test করুন এবং দেখুন permission dialog আসে কিনা!** 📱 