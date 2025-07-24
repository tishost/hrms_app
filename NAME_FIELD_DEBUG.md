# Name Field Debug Guide

## 🔍 **Current Issue:**
- **Problem:** "name field a data arsay nah" (Name field data is not coming)
- **Status:** Database has data but Flutter app is not receiving it

## 📊 **Database Data (Confirmed):**
```
ID: 1
First Name: 'Mr'
Last Name: 'Alam'
Mobile: '0118171717'
Gender: 'Male'
```

## 🔧 **Debug Steps:**

### **1. Laravel API Debug:**
Laravel API এ debug logs add করা হয়েছে:
```php
\Log::info('Tenant show response', [
    'tenant_id' => $id,
    'first_name' => $tenant->first_name,
    'last_name' => $tenant->last_name,
    'full_tenant' => $tenant->toArray()
]);
```

### **2. Flutter App Debug:**
Flutter app এ debug logs add করা হয়েছে:
```dart
print('DEBUG: Tenant data from API:');
print('DEBUG: tenant = $tenant');
print('DEBUG: first_name = ${tenant['first_name']}');
print('DEBUG: last_name = ${tenant['last_name']}');
print('DEBUG: first_name type = ${tenant['first_name'].runtimeType}');
print('DEBUG: last_name type = ${tenant['last_name'].runtimeType}');
print('DEBUG: Name set to: ${_nameController.text}');
print('DEBUG: Name controller text: ${_nameController.text}');
print('DEBUG: Name controller text length: ${_nameController.text.length}');
print('DEBUG: Name controller text isEmpty: ${_nameController.text.isEmpty}');
```

## 🎯 **Expected Debug Output:**

### **✅ Success Case:**
```
DEBUG: Tenant data from API:
DEBUG: tenant = {id: 1, first_name: Mr, last_name: Alam, mobile: 0118171717, gender: Male, ...}
DEBUG: first_name = Mr
DEBUG: last_name = Alam
DEBUG: first_name type = String
DEBUG: last_name type = String
DEBUG: Name set to: Mr Alam
DEBUG: Name controller text: Mr Alam
DEBUG: Name controller text length: 7
DEBUG: Name controller text isEmpty: false
```

### **❌ Error Case:**
```
DEBUG: Tenant data from API:
DEBUG: tenant = {id: 1, first_name: null, last_name: null, mobile: 0118171717, gender: Male, ...}
DEBUG: first_name = null
DEBUG: last_name = null
DEBUG: first_name type = Null
DEBUG: last_name type = Null
DEBUG: Name set to: 
DEBUG: Name controller text: 
DEBUG: Name controller text length: 0
DEBUG: Name controller text isEmpty: true
```

## 🔍 **Possible Issues:**

### **1. API Response Issue:**
- Laravel API থেকে data properly আসছে কিনা
- JSON response এ field names ঠিক আছে কিনা
- Data types ঠিক আছে কিনা

### **2. Flutter Parsing Issue:**
- JSON parsing ঠিক হচ্ছে কিনা
- Field names match হচ্ছে কিনা
- Null handling ঠিক আছে কিনা

### **3. Controller Issue:**
- TextEditingController properly initialize হয়েছে কিনা
- setState() call হচ্ছে কিনা
- UI rebuild হচ্ছে কিনা

## 📱 **Test Steps:**

### **1. Run App:**
1. Open **hrms_app**
2. Go to **Tenants** screen
3. Tap **edit button** on tenant ID 1

### **2. Check Debug Logs:**
1. Look for **"DEBUG: Tenant data from API:"**
2. Check **first_name** and **last_name** values
3. Check **data types** (String vs Null)
4. Check **Name controller text**

### **3. Check Laravel Logs:**
1. Check **storage/logs/laravel.log**
2. Look for **"Tenant show response"**
3. Verify **first_name** and **last_name** values

## 🔧 **Quick Fixes:**

### **1. If API Response is Empty:**
```php
// In TenantController.php show method
return response()->json([
    'id' => $tenant->id,
    'first_name' => $tenant->first_name,
    'last_name' => $tenant->last_name,
    'mobile' => $tenant->mobile,
    'gender' => $tenant->gender,
    // ... other fields
]);
```

### **2. If Flutter Parsing Issue:**
```dart
// In _populateForm method
final firstName = tenant['first_name']?.toString() ?? '';
final lastName = tenant['last_name']?.toString() ?? '';
_nameController.text = '$firstName $lastName'.trim();
```

### **3. If Controller Issue:**
```dart
// Ensure controller is properly initialized
final _nameController = TextEditingController();

// In dispose method
@override
void dispose() {
  _nameController.dispose();
  super.dispose();
}
```

## 🎯 **Next Steps:**

### **1. Check Laravel Logs:**
```bash
cd E:\wamp\www\hrms
Get-Content storage/logs/laravel.log -Tail 20
```

### **2. Check Flutter Debug Logs:**
App run করে debug logs check করুন

### **3. Compare Results:**
- Laravel logs vs Flutter logs
- Database data vs API response
- Expected vs Actual values

**এখন app run করুন এবং debug logs check করুন!** 🔍

**Laravel logs এবং Flutter logs compare করুন!** 📊

**Database data vs API response check করুন!** ✅ 