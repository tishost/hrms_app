import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _apiUrl = '';
  String _testResult = '';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _apiUrl = getApiUrl();
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing API connection...\n';
    });

    try {
      _testResult += 'API URL: $_apiUrl\n\n';

      // Test 1: Basic connection
      _testResult += 'Test 1: Basic Connection\n';
      final response = await http
          .get(Uri.parse('$_apiUrl/health'))
          .timeout(Duration(seconds: 10));
      _testResult += 'Status: ${response.statusCode}\n';
      _testResult += 'Response: ${response.body}\n\n';

      // Test 2: Authentication
      _testResult += 'Test 2: Authentication\n';
      final token = await AuthService.getToken();
      if (token != null) {
        _testResult += 'Token: ${token.substring(0, 20)}...\n';

        // Test tenant test endpoint
        _testResult += '\nTest 2.1: Tenant Test Endpoint\n';
        final testResponse = await http
            .get(
              Uri.parse('$_apiUrl/tenant/test'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(Duration(seconds: 10));

        _testResult += 'Test Status: ${testResponse.statusCode}\n';
        if (testResponse.statusCode == 200) {
          final testData = json.decode(testResponse.body);
          _testResult += 'Test Success: ${testData['success']}\n';
          _testResult += 'Message: ${testData['message']}\n';
          if (testData['tenant'] != null) {
            _testResult += 'Tenant ID: ${testData['tenant']['id']}\n';
            _testResult +=
                'Tenant Name: ${testData['tenant']['first_name']} ${testData['tenant']['last_name']}\n';
          }
          if (testData['invoices'] != null) {
            _testResult += 'Invoices Count: ${testData['invoices']['count']}\n';
          }
        } else {
          _testResult += 'Test Error: ${testResponse.body}\n';
        }

        // Test tenant dashboard
        _testResult += '\nTest 2.2: Tenant Dashboard\n';
        final dashboardResponse = await http
            .get(
              Uri.parse('$_apiUrl/tenant/dashboard'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(Duration(seconds: 10));

        _testResult += 'Dashboard Status: ${dashboardResponse.statusCode}\n';
        if (dashboardResponse.statusCode == 200) {
          final data = json.decode(dashboardResponse.body);
          _testResult += 'Dashboard Data: ${data.keys.join(', ')}\n';
        } else {
          _testResult += 'Dashboard Error: ${dashboardResponse.body}\n';
        }
      } else {
        _testResult += 'No token found\n';
      }

      // Test 3: Get tenant invoices first
      _testResult += '\nTest 3: Get Tenant Invoices\n';
      if (token != null) {
        final invoicesResponse = await http
            .get(
              Uri.parse('$_apiUrl/tenant/invoices'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(Duration(seconds: 10));

        _testResult += 'Invoices Status: ${invoicesResponse.statusCode}\n';
        if (invoicesResponse.statusCode == 200) {
          final invoicesData = json.decode(invoicesResponse.body);
          final invoices = invoicesData['invoices'] ?? [];
          _testResult += 'Invoices Count: ${invoices.length}\n';

          if (invoices.isNotEmpty) {
            final firstInvoice = invoices.first;
            _testResult += 'First Invoice ID: ${firstInvoice['id']}\n';
            _testResult +=
                'First Invoice Number: ${firstInvoice['invoice_number']}\n';

            // Test 4: PDF endpoint with actual invoice ID
            _testResult += '\nTest 4: PDF Endpoint\n';
            _testResult += 'Testing Invoice ID: ${firstInvoice['id']}\n';
            _testResult +=
                'Testing Invoice Number: ${firstInvoice['invoice_number']}\n';

            final pdfResponse = await http
                .get(
                  Uri.parse(
                    '$_apiUrl/tenant/invoices/${firstInvoice['id']}/pdf-file',
                  ),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/pdf',
                  },
                )
                .timeout(Duration(seconds: 10));

            _testResult += 'PDF Status: ${pdfResponse.statusCode}\n';
            _testResult +=
                'PDF Content-Type: ${pdfResponse.headers['content-type']}\n';
            _testResult += 'PDF Size: ${pdfResponse.bodyBytes.length} bytes\n';

            if (pdfResponse.statusCode != 200) {
              _testResult += 'PDF Error: ${pdfResponse.body}\n';
            }

            // Test 4.1: PDF URL endpoint
            _testResult += '\nTest 4.1: PDF URL Endpoint\n';
            final pdfUrlResponse = await http
                .get(
                  Uri.parse(
                    '$_apiUrl/tenant/invoices/${firstInvoice['id']}/pdf',
                  ),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                  },
                )
                .timeout(Duration(seconds: 10));

            _testResult += 'PDF URL Status: ${pdfUrlResponse.statusCode}\n';
            if (pdfUrlResponse.statusCode == 200) {
              final pdfUrlData = json.decode(pdfUrlResponse.body);
              _testResult += 'PDF URL Success: ${pdfUrlData['success']}\n';
              _testResult += 'PDF URL: ${pdfUrlData['pdf_url']}\n';
            } else {
              _testResult += 'PDF URL Error: ${pdfUrlResponse.body}\n';
            }
          } else {
            _testResult += 'No invoices found for tenant\n';
          }
        } else {
          _testResult += 'Invoices Error: ${invoicesResponse.body}\n';
        }
      }
    } catch (e) {
      _testResult += 'Error: $e\n';
    }

    setState(() {
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Screen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('API URL: $_apiUrl'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _testApiConnection,
                      child: Text(
                        _isTesting ? 'Testing...' : 'Test Connection',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResult.isEmpty
                            ? 'No test results yet'
                            : _testResult,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Check if WAMP server is running'),
                    Text('2. Verify API URL is correct'),
                    Text('3. Check network security configuration'),
                    Text('4. Ensure Laravel server is accessible'),
                    Text('5. Check authentication token'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
