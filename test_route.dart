import 'package:flutter/material.dart';
import 'lib/features/owner/presentation/screens/tenant_entry_screen.dart';

void main() {
  print('Testing TenantEntryScreen import...');

  try {
    // Test if we can create the widget
    final widget = TenantEntryScreen();
    print('✅ TenantEntryScreen created successfully');

    // Test if we can create with tenant data
    final editWidget = TenantEntryScreen(tenant: {'id': 1, 'name': 'Test'});
    print('✅ TenantEntryScreen with tenant data created successfully');

    print('✅ All tests passed!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
