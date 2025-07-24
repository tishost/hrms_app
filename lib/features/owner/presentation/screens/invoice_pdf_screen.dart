import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';

class InvoicePdfScreen extends StatefulWidget {
  final int invoiceId;
  final String invoiceNumber;

  const InvoicePdfScreen({
    Key? key,
    required this.invoiceId,
    required this.invoiceNumber,
  }) : super(key: key);

  @override
  State<InvoicePdfScreen> createState() => _InvoicePdfScreenState();
}

class _InvoicePdfScreenState extends State<InvoicePdfScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeWebView() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _error = 'Authentication token not found';
            _isLoading = false;
          });
        }
        return;
      }

      // Detect user type to call correct endpoint
      String userType = await _detectUserType(token);
      print('=== User Type Detection ===');
      print('Detected User Type: $userType');
      print('Invoice ID: ${widget.invoiceId}');

      // Set timeout for loading (reduced for faster response)
      _timeoutTimer = Timer(Duration(seconds: 30), () {
        if (mounted && _isLoading) {
          setState(() {
            _error =
                'Loading timeout. Please check your connection and try again.';
            _isLoading = false;
          });
        }
      });

      // Call appropriate endpoint based on user type
      String apiEndpoint;
      if (userType == 'owner') {
        apiEndpoint = ApiConfig.getApiUrl(
          '/owner/invoices/${widget.invoiceId}/pdf-file',
        );
        print('Using Owner Endpoint: $apiEndpoint');
      } else {
        apiEndpoint = ApiConfig.getApiUrl(
          '/tenant/invoices/${widget.invoiceId}/pdf-file',
        );
        print('Using Tenant Endpoint: $apiEndpoint');
      }

      _loadPdfInWebView(apiEndpoint, token);
    } catch (e) {
      print('PDF initialization error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize PDF viewer: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Detect user type
  Future<String> _detectUserType(String token) async {
    try {
      print('=== User Type Detection Debug ===');
      print('API URL: ${ApiConfig.getApiUrl('/user/profile')}');
      print('Token: ${token.substring(0, 20)}...');

      // Call user profile API to detect user type
      final response = await http
          .get(
            Uri.parse(ApiConfig.getApiUrl('/user/profile')),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('Parsed User Data: $userData');

        // Check if user has owner or tenant data
        if (userData['user'] != null) {
          final user = userData['user'];

          if (user['owner'] != null) {
            print('✅ User detected as: Owner');
            print('Owner Data: ${user['owner']}');
            return 'owner';
          } else if (user['tenant'] != null) {
            print('✅ User detected as: Tenant');
            print('Tenant Data: ${user['tenant']}');
            return 'tenant';
          } else {
            print('❌ No owner or tenant data found');
          }
        } else {
          print('❌ No user data in response');
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
      }

      // Default to tenant if detection fails
      print('⚠️ User type detection failed, defaulting to: Tenant');
      return 'tenant';
    } catch (e) {
      print('❌ User type detection error: $e');
      // Default to tenant if detection fails
      return 'tenant';
    }
  }

  void _loadPdfInWebView(String pdfUrl, String token) {
    print('=== LOAD PDF DEBUG ===');
    print('PDF URL: $pdfUrl');
    print('Token: ${token.substring(0, 20)}...');
    print('=====================');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView Progress: $progress%');
            // Cancel timeout if progress is good
            if (progress > 30) {
              _timeoutTimer?.cancel();
            }
          },
          onPageStarted: (String url) {
            print('PDF Loading started: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (String url) {
            print('PDF Loading finished: $url');
            _timeoutTimer?.cancel(); // Cancel timeout on success
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('=== WEBVIEW ERROR DEBUG ===');
            print('Error Description: ${error.description}');
            print('Error Code: ${error.errorCode}');
            print('==========================');
            _timeoutTimer?.cancel(); // Cancel timeout on error

            String errorMessage = 'Failed to load PDF: ${error.description}';

            // Handle specific error types
            if (error.description.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
              errorMessage =
                  'Network security error. Please check your API configuration.';
            } else if (error.description.contains('ERR_CONNECTION_REFUSED')) {
              errorMessage =
                  'Connection refused. Please check if the server is running.';
            } else if (error.description.contains('ERR_NAME_NOT_RESOLVED')) {
              errorMessage =
                  'Cannot resolve server address. Please check your API URL.';
            } else if (error.description.contains('404')) {
              errorMessage = 'Invoice not found. Please check the invoice ID.';
            } else if (error.description.contains('403')) {
              errorMessage = 'Access denied. Please check your authentication.';
            } else if (error.description.contains('timeout')) {
              errorMessage =
                  'Loading timeout. Please check your connection and try again.';
            } else if (error.errorCode == -1) {
              errorMessage = 'Unknown error occurred. Please try again.';
            }

            if (mounted) {
              setState(() {
                _error = errorMessage;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(pdfUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf,application/octet-stream,*/*',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
        },
      );
  }

  void _sharePDF() {
    // Share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/dashboard'),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice PDF',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          widget.invoiceNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _controller.reload();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _sharePDF();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.share,
                            color: AppColors.green,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we generate your invoice',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeWebView();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      // Force reload
                      _controller.reload();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Reload'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Loading PDF...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
