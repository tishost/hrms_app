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

  const InvoicePdfScreen({
    Key? key,
    required this.invoiceId,
    required this.invoiceNumber,
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
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token not found');

      final url = ApiConfig.getApiUrl('/tenant/invoices/${widget.invoiceId}/pdf-file');
      final resp = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/pdf',
      });

      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tenant_invoice_${widget.invoiceId}.pdf');
      await file.writeAsBytes(resp.bodyBytes);

      if (!mounted) return;
      setState(() {
        _pdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
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
          )
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
