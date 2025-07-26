import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TenantEntrySimple extends StatefulWidget {
  final Map<String, dynamic>? tenant;

  const TenantEntrySimple({super.key, this.tenant});

  @override
  State<TenantEntrySimple> createState() => _TenantEntrySimpleState();
}

class _TenantEntrySimpleState extends State<TenantEntrySimple> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenant != null ? 'Edit Tenant' : 'Add New Tenant'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tenants');
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.tenant != null ? 'Edit Mode' : 'Create Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (widget.tenant != null) ...[
              Text('Tenant ID: ${widget.tenant!['id']}'),
              Text('Name: ${widget.tenant!['name'] ?? 'Unknown'}'),
            ],
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop(true);
                } else {
                  context.go('/tenants');
                }
              },
              child: Text('Save & Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
