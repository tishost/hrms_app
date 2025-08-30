import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/app_colors.dart';

class InvoicePdfScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final VoidCallback? onBackToBilling;

  const InvoicePdfScreen({
    Key? key,
    required this.invoiceId,
    required this.invoiceNumber,
    this.onBackToBilling,
  }) : super(key: key);

  @override
  State<InvoicePdfScreen> createState() => _InvoicePdfScreenState();
}

class _InvoicePdfScreenState extends State<InvoicePdfScreen> {
  bool _isLoading = true;
  String? _error;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      print('🔍 Loading tenant invoice PDF - ID: ${widget.invoiceId}');

      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token not found');

      final url = ApiConfig.getApiUrl(
        '/tenant/invoices/${widget.invoiceId}/pdf-file',
      );
      print('🌐 Tenant PDF Request URL: $url');

      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      print(
        '📄 Tenant PDF Response - Status: ${resp.statusCode}, Content-Length: ${resp.bodyBytes.length}',
      );

      if (resp.statusCode == 404) {
        throw Exception('Invoice not found (404)');
      } else if (resp.statusCode == 403) {
        throw Exception('Access denied to this invoice (403)');
      } else if (resp.statusCode != 200) {
        throw Exception(
          'Server error (${resp.statusCode}): ${resp.reasonPhrase}',
        );
      }

      if (resp.bodyBytes.isEmpty) {
        throw Exception('PDF file is empty');
      }

      // Check if response is actually a PDF
      final contentType = resp.headers['content-type'] ?? '';
      if (!contentType.contains('pdf')) {
        print('⚠️ Unexpected content type: $contentType');
        // Try to parse as JSON to see if it's an error response
        try {
          final responseText = String.fromCharCodes(resp.bodyBytes);
          print('📝 Response text: $responseText');
          throw Exception('Expected PDF but got: $contentType');
        } catch (_) {
          throw Exception('Invalid response format');
        }
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tenant_invoice_${widget.invoiceId}.pdf');
      await file.writeAsBytes(resp.bodyBytes);

      print('✅ Tenant PDF saved to: ${file.path}');

      if (!mounted) return;
      setState(() {
        _pdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Tenant PDF Load Error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoiceNumber}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // If onBackToBilling callback is provided, use it
            if (widget.onBackToBilling != null) {
              widget.onBackToBilling!();
            } else {
              // Default back navigation
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadPdf();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : (_error != null)
          ? Center(child: Text(_error!))
          : PDFView(
              filePath: _pdfPath!,
              enableSwipe: true,
              swipeHorizontal: false,
            ),
    );
  }
}
