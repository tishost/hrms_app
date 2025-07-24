import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/api_config.dart';

class UniversalPdfScreen extends StatefulWidget {
  final int invoiceId;
  final String invoiceNumber;
  final String? userType; // 'owner' or 'tenant'

  const UniversalPdfScreen({
    Key? key,
    required this.invoiceId,
    required this.invoiceNumber,
    this.userType,
  }) : super(key: key);

  @override
  State<UniversalPdfScreen> createState() => _UniversalPdfScreenState();
}

class _UniversalPdfScreenState extends State<UniversalPdfScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  Timer? _timeoutTimer;
  String? _detectedUserType;

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

      // QUICK FIX: Force owner detection for testing
      _detectedUserType = 'owner';
      print('=== QUICK FIX: Forcing user type to owner ===');

      // Set timeout for loading (increased for PDF loading)
      _timeoutTimer = Timer(Duration(seconds: 180), () {
        if (mounted && _isLoading) {
          setState(() {
            _error =
                'PDF loading timeout (3 minutes). This might be due to:\n\n1. Slow internet connection\n2. Large PDF file\n3. Server processing time\n\nPlease try:\n• Check your internet connection\n• Try again in a few minutes\n• Contact support if problem persists';
            _isLoading = false;
          });
        }
      });

      // FORCE OWNER ENDPOINT - HARDCODED FOR TESTING
      String apiEndpoint = ApiConfig.getApiUrl(
        '/owner/invoices/${widget.invoiceId}/pdf-file',
      );
      print('=== FORCE OWNER ENDPOINT DEBUG ===');
      print('User Type: ${_detectedUserType}');
      print('Invoice ID: ${widget.invoiceId}');
      print('FORCED API Endpoint: $apiEndpoint');
      print('Token: ${token.substring(0, 20)}...');
      print('API Base URL: ${ApiConfig.getBaseUrl()}');
      print('=====================================');

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
            if (progress > 50) {
              _timeoutTimer?.cancel();
            }
            if (progress == 100) {
              Future.delayed(Duration(seconds: 2), () {
                if (mounted && _isLoading) {
                  print('Manually completing PDF loading after 100% progress');
                  setState(() {
                    _isLoading = false;
                  });
                }
              });
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
            _timeoutTimer?.cancel();
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
            _timeoutTimer?.cancel();

            String errorMessage = 'Failed to load PDF: ${error.description}';

            if (error.description.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
              errorMessage =
                  'Network Security Error:\n\nThis error occurs when the app cannot access HTTP URLs. Please:\n\n1. Check if your API uses HTTPS\n2. Verify API configuration\n3. Try again in a few minutes';
            } else if (error.description.contains('ERR_CONNECTION_REFUSED')) {
              errorMessage =
                  'Connection Refused:\n\nThe server is not responding. Please:\n\n1. Check if your server is running\n2. Verify the API URL is correct\n3. Try again in a few minutes';
            } else if (error.description.contains('ERR_NAME_NOT_RESOLVED')) {
              errorMessage =
                  'DNS Resolution Error:\n\nCannot find the server. Please:\n\n1. Check your internet connection\n2. Verify the API URL\n3. Try using a different network';
            } else if (error.description.contains('404')) {
              errorMessage =
                  'Invoice Not Found:\n\nThe requested invoice does not exist. Please check the invoice ID.';
            } else if (error.description.contains('403')) {
              errorMessage =
                  'Access Denied:\n\nYou do not have permission to access this invoice. Please check your authentication.';
            } else if (error.description.contains('timeout')) {
              errorMessage =
                  'Loading Timeout:\n\nThe PDF is taking too long to load. Please:\n\n1. Check your internet connection\n2. Try again in a few minutes\n3. Contact support if problem persists';
            } else if (error.errorCode == -1) {
              errorMessage =
                  'Unknown Error:\n\nAn unexpected error occurred. Please:\n\n1. Try again in a few minutes\n2. Check your internet connection\n3. Contact support if problem persists';
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
          'Cache-Control': 'no-cache',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
        },
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
                        if (_detectedUserType != null)
                          Text(
                            'Viewing as: ${_detectedUserType!.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _detectedUserType == 'owner'
                                  ? AppColors.primary
                                  : AppColors.green,
                              fontWeight: FontWeight.w500,
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
    if (_isLoading && _error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we load the invoice',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (_detectedUserType != null)
              Text(
                'User Type: ${_detectedUserType!.toUpperCase()}',
                style: TextStyle(
                  color: _detectedUserType == 'owner'
                      ? AppColors.primary
                      : AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
            if (_detectedUserType != null)
              Text(
                'User Type: ${_detectedUserType!.toUpperCase()}',
                style: TextStyle(
                  color: _detectedUserType == 'owner'
                      ? AppColors.primary
                      : AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            SizedBox(height: 16),
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

  void _sharePDF() {
    // Share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
