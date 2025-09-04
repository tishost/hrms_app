import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/services/permission_service.dart';

class InvoicePdfScreen extends StatefulWidget {
  final int invoiceId;
  final bool forceTenant; // when true, always use tenant endpoint
  final VoidCallback? onBackToBilling;

  const InvoicePdfScreen({
    super.key,
    required this.invoiceId,
    this.forceTenant = false,
    this.onBackToBilling,
  });

  @override
  State<InvoicePdfScreen> createState() => _InvoicePdfScreenState();
}

class _InvoicePdfScreenState extends State<InvoicePdfScreen> {
  bool _isLoading = true;
  String? _error;
  String? _pdfPath;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    print('DEBUG: Initializing PDF Screen');
    _loadPdf();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  // FIXED: Re-introduced a function to get the user role via API call
  Future<String> _getUserRole(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.getApiUrl('/user/profile')),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user'] != null) {
          if (data['user']['owner'] != null) return 'owner';
          if (data['user']['tenant'] != null) return 'tenant';
        }
      }
      // If role is not found, default to owner
      print("Could not determine user role from profile, defaulting to owner");
      return 'owner';
    } catch (e) {
      print("Error detecting user role: $e");
      // Default to owner instead of throwing exception
      print("Defaulting to owner role");
      return 'owner';
    }
  }

  Future<void> _loadPdf() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Get user role first (unless forced tenant)
      final role = widget.forceTenant ? 'tenant' : await _getUserRole(token);

      // Set a timeout for the entire loading process
      _timeoutTimer = Timer(Duration(seconds: 25), () {
        if (mounted && _isLoading) {
          setState(() {
            _error = 'Loading timeout. Please check your connection.';
            _isLoading = false;
          });
        }
      });

      // Construct the correct API endpoint based on the user's role
      final apiEndpoint = (role == 'owner')
          ? ApiConfig.getApiUrl('/owner/invoices/${widget.invoiceId}/pdf-file')
          : ApiConfig.getApiUrl(
              '/tenant/invoices/${widget.invoiceId}/pdf-file',
            );

      print("DEBUG: Fetching PDF from: $apiEndpoint");

      // Download the PDF content
      final response = await http
          .get(
            Uri.parse(apiEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/pdf',
            },
          )
          .timeout(Duration(seconds: 20));

      print('DEBUG: HTTP Response Status: ${response.statusCode}');
      print('DEBUG: HTTP Response Headers: ${response.headers}');
      print('DEBUG: HTTP Response Body Length: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        print('DEBUG: Content Type: $contentType');

        if (contentType.contains('application/pdf') &&
            response.bodyBytes.isNotEmpty) {
          print('DEBUG: PDF content received, saving to file');

          try {
            // Try to get temporary directory without permission first
            final directory = await getTemporaryDirectory();
            final file = File(
              '${directory.path}/invoice_${widget.invoiceId}.pdf',
            );

            // Write PDF content to file
            await file.writeAsBytes(response.bodyBytes);
            print('DEBUG: PDF saved to: ${file.path}');

            if (mounted) {
              setState(() {
                _pdfPath = file.path;
                _isLoading = false;
              });
            }
          } catch (e) {
            print('DEBUG: Error saving to temp directory: $e');

            // If temp directory fails, try with storage permission
            var status = await Permission.storage.status;
            if (!status.isGranted) {
              print('DEBUG: Requesting storage permission');
              status = await Permission.storage.request();
              print('DEBUG: Storage permission status: $status');
            }

            if (status.isGranted) {
              // Try external storage directory
              final directory = await getExternalStorageDirectory();
              if (directory != null) {
                final file = File(
                  '${directory.path}/invoice_${widget.invoiceId}.pdf',
                );
                await file.writeAsBytes(response.bodyBytes);
                print('DEBUG: PDF saved to external storage: ${file.path}');

                if (mounted) {
                  setState(() {
                    _pdfPath = file.path;
                    _isLoading = false;
                  });
                }
              } else {
                throw Exception('External storage directory not available');
              }
            } else {
              throw Exception(
                'Storage permission denied. Please allow storage access in app settings.',
              );
            }
          }
        } else {
          throw Exception(
            'Server did not return a valid PDF file. Content-Type: $contentType',
          );
        }
      } else {
        print('DEBUG: HTTP request failed with status: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');

        String errorMessage =
            'Failed to download PDF: HTTP ${response.statusCode}';

        if (response.statusCode == 302) {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Access denied. Please check your permissions.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Invoice not found. Please check the invoice ID.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error downloading PDF: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load PDF: $e';
        });
      }
    }
  }

  void _downloadPDF() async {
    try {
      if (_pdfPath == null) return;

      final hasPermission = await PermissionService.requestStoragePermission(
        context,
      );
      if (!hasPermission) {
        await PermissionService.showPermissionDeniedSnackBar(context);
        return;
      }

      Directory? downloadsDir;
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          downloadsDir = dirs.first;
        }
      } catch (_) {}

      // Fallback: try public Downloads on Android
      if (downloadsDir == null && Platform.isAndroid) {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        if (await publicDownloads.exists()) {
          downloadsDir = publicDownloads;
        }
      }

      // Final fallback: app-specific external dir
      downloadsDir ??= await getExternalStorageDirectory();
      if (downloadsDir == null) {
        throw Exception('Downloads directory not available');
      }

      // Ensure folder exists
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final sourceFile = File(_pdfPath!);
      final safeInvoiceNo = widget.invoiceId.toString().padLeft(4, '0');
      final destPath =
          '${downloadsDir.path}/Invoice_INV-2025-$safeInvoiceNo.pdf';
      await sourceFile.copy(destPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice saved to Downloads: Invoice_INV-2025-$safeInvoiceNo.pdf',
          ),
          backgroundColor: AppColors.green,
        ),
      );

      // Attempt to open the saved file
      try {
        await OpenFile.open(destPath);
      } catch (_) {}
    } catch (e) {
      print('DEBUG: Download error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sharePDF() async {
    try {
      if (_pdfPath != null) {
        // Use open_file package to share PDF
        final result = await OpenFile.open(_pdfPath!);
        if (result.type != ResultType.done) {
          throw Exception('Failed to open PDF for sharing');
        }
      }
    } catch (e) {
      print('DEBUG: Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.onBackToBilling != null) {
          try {
            widget.onBackToBilling!();
          } catch (_) {}
        }
        return true;
      },
      child: Scaffold(
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
                    // Back Button
                    GestureDetector(
                      onTap: () {
                        // If onBackToBilling callback is provided, use it
                        if (widget.onBackToBilling != null) {
                          widget.onBackToBilling!();
                        } else {
                          // Default back navigation
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/properties');
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice PDF',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'INV-2025-${widget.invoiceId.toString().padLeft(4, '0')}',
                            style: TextStyle(
                              fontSize: 12,
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
                            setState(() {
                              _error = null;
                              _isLoading = true;
                            });
                            _loadPdf();
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
                          onTap: _downloadPDF,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.download,
                              color: AppColors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sharePDF,
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
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Generating Invoice PDF...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we prepare your invoice with detailed breakdown',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _loadPdf();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfPath != null) {
      return SizedBox.expand(
        child: PDFView(
          filePath: _pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            print('DEBUG: PDF rendered with $pages pages');
          },
          onError: (error) {
            print('DEBUG: PDF Error: $error');
            setState(() {
              _error = 'Failed to display PDF: $error';
            });
          },
          onPageError: (page, error) {
            print('DEBUG: PDF Page Error: Page $page - $error');
          },
        ),
      );
    }

    return Center(child: Text('No PDF available'));
  }
}
