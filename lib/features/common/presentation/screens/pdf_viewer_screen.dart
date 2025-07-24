import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String token;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.token,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _error;
  String? _pdfPath;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    try {
      print('=== DOWNLOADING PDF ===');
      print('PDF URL: ${widget.pdfUrl}');
      print('Token: ${widget.token.substring(0, 20)}...');

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Download PDF
      final response = await http
          .get(
            Uri.parse(widget.pdfUrl),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Accept': 'application/pdf,application/octet-stream,*/*',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(Duration(seconds: 60));

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Length: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        // Save PDF to temporary file
        final directory = await getTemporaryDirectory();
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = path.join(directory.path, fileName);

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print('PDF saved to: $filePath');

        if (mounted) {
          setState(() {
            _pdfPath = filePath;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('PDF download error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_pdfPath != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _downloadAndLoadPdf,
              tooltip: 'Reload PDF',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we download the invoice',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                'Error Loading PDF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _downloadAndLoadPdf,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfPath != null) {
      return PDFView(
        filePath: _pdfPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (pages) {
          print('PDF rendered with $pages pages');
        },
        onError: (error) {
          print('PDF Error: $error');
          setState(() {
            _error = 'PDF Error: $error';
          });
        },
        onPageError: (page, error) {
          print('PDF Page Error: Page $page - $error');
        },
        onViewCreated: (PDFViewController pdfViewController) {
          _pdfViewController = pdfViewController;
        },
      );
    }

    return Center(child: Text('No PDF to display'));
  }

  @override
  void dispose() {
    _pdfViewController?.dispose();
    super.dispose();
  }
}
