import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/services/api_service.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/presentation/screens/invoice_pdf_screen.dart';
import 'package:hrms_app/features/tenant/presentation/screens/invoice_payment_screen.dart';
import 'package:hrms_app/features/tenant/presentation/widgets/tenant_bottom_nav.dart';

class TenantBillingScreen extends ConsumerStatefulWidget {
  const TenantBillingScreen({super.key});

  @override
  _TenantBillingScreenState createState() => _TenantBillingScreenState();
}

class _TenantBillingScreenState extends ConsumerState<TenantBillingScreen> {
  bool _isLoading = true;
  List<dynamic> _invoices = [];
  List<dynamic> _visibleInvoices = [];
  final StringBuffer _debugLog = StringBuffer();

  // Filters
  String _statusFilter = 'all'; // all, paid, unpaid
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchText = '';
  double? _minAmount;
  double? _maxAmount;

  void _dbg(String msg) {
    final line = 'DEBUG[TenantBilling]: ' + msg;
    if (kDebugMode) {
      // ignore: avoid_print
      print(line);
    }
    _debugLog.writeln(line);
  }

  @override
  void initState() {
    super.initState();
    _dbg('initState → loading invoices');
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final api = ref.read(apiServiceProvider);
      final url = ApiConfig.getApiUrl('/tenant/invoices');
      final token = await AuthService.getToken();
      _dbg('Calling: ' + url);
      _dbg('Token length: ' + (token?.length.toString() ?? 'null'));
      final resp = await api.get('/tenant/invoices');
      _dbg('Status: ' + (resp.statusCode?.toString() ?? 'null'));
      _dbg('Data type: ' + resp.data.runtimeType.toString());
      _dbg('Raw data: ' + resp.data.toString());
      if (resp.statusCode == 200) {
        final data = resp.data is Map ? resp.data as Map : <String, dynamic>{};
        _dbg('Top-level keys: ' + (data.keys.join(', ')));
        final invoices =
            data['invoices'] ??
            (data['data'] is Map ? data['data']['invoices'] : null) ??
            [];
        _dbg(
          'Parsed invoices length: ' +
              ((invoices is List ? invoices.length : 0).toString()),
        );
        setState(() {
          _invoices = List<dynamic>.from(invoices);
          _visibleInvoices = List<dynamic>.from(invoices);
          _isLoading = false;
        });
        _applyFilters();
      } else {
        throw Exception(
          'HTTP ${resp.statusCode}: ' + (resp.statusMessage ?? ''),
        );
      }
    } catch (e) {
      _dbg('Exception: ' + e.toString());
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load invoices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bills'),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Debug Log'),
                  content: SingleChildScrollView(
                    child: Text(_debugLog.toString()),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadInvoices),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatusFilterBar(),
          ),
          SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadInvoices,
                    child: _visibleInvoices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No invoices found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Your bills will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: _visibleInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = _visibleInvoices[index];
                              return _buildInvoiceCard(invoice);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    Widget chip(String value, String label) {
      final bool selected = _statusFilter == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _statusFilter = value);
            _applyFilters();
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.black12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('all', 'All'),
        SizedBox(width: 8),
        chip('unpaid', 'Unpaid'),
        SizedBox(width: 8),
        chip('paid', 'Paid'),
      ],
    );
  }

  void _applyFilters() {
    List<dynamic> list = List<dynamic>.from(_invoices);
    bool matchesStatus(Map<String, dynamic> inv) {
      final s = (inv['status'] ?? '').toString().toLowerCase();
      if (_statusFilter == 'all') return true;
      if (_statusFilter == 'paid') return s == 'paid' || s == 'complete';
      if (_statusFilter == 'unpaid') return s == 'unpaid' || s == 'pending';
      return true;
    }

    bool matchesSearch(Map<String, dynamic> inv) {
      if (_searchText.trim().isEmpty) return true;
      final q = _searchText.toLowerCase();
      final id = inv['id']?.toString().toLowerCase() ?? '';
      final num = inv['invoice_number']?.toString().toLowerCase() ?? '';
      return id.contains(q) || num.contains(q);
    }

    bool matchesAmount(Map<String, dynamic> inv) {
      final amt = double.tryParse(inv['amount']?.toString() ?? '');
      if (amt == null) return _minAmount == null && _maxAmount == null;
      if (_minAmount != null && amt < _minAmount!) return false;
      if (_maxAmount != null && amt > _maxAmount!) return false;
      return true;
    }

    bool matchesDate(Map<String, dynamic> inv) {
      final raw = inv['issue_date'] ?? inv['created_at'] ?? inv['date'];
      final dt = DateTime.tryParse(raw?.toString() ?? '');
      if (dt == null) return _fromDate == null && _toDate == null;
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt.isAfter(_toDate!)) return false;
      return true;
    }

    list = list
        .whereType<Map<String, dynamic>>()
        .where(matchesStatus)
        .where(matchesSearch)
        .where(matchesAmount)
        .where(matchesDate)
        .toList();

    // Sort: unpaid first, then newest by date
    bool isUnpaid(Map<String, dynamic> inv) {
      final s = (inv['status'] ?? '').toString().toLowerCase();
      return s == 'unpaid' || s == 'pending' || s == 'due' || s == 'partial';
    }

    DateTime parseDate(Map<String, dynamic> inv) {
      final raw = inv['issue_date'] ?? inv['created_at'] ?? inv['date'];
      return DateTime.tryParse(raw?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    list.sort((a, b) {
      if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) return 0;
      final ra = isUnpaid(a) ? 0 : 1;
      final rb = isUnpaid(b) ? 0 : 1;
      if (ra != rb) return ra - rb; // unpaid first
      final dta = parseDate(a);
      final dtb = parseDate(b);
      return dtb.compareTo(dta); // newest first
    });

    setState(() => _visibleInvoices = list);
    _dbg('Filter applied → ${_visibleInvoices.length} items');
  }

  void _showQuickStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget chip(String value, String label) {
          final bool selected = _statusFilter == value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _statusFilter = value);
                _applyFilters();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  chip('all', 'All'),
                  SizedBox(width: 8),
                  chip('unpaid', 'Unpaid'),
                  SizedBox(width: 8),
                  chip('paid', 'Paid'),
                ],
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Full advanced filter kept for future use
  void _showFilterSheet() {
    final statusOptions = const [
      DropdownMenuItem(value: 'all', child: Text('All')),
      DropdownMenuItem(value: 'paid', child: Text('Paid')),
      DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
    ];
    String tempStatus = _statusFilter;
    String tempSearch = _searchText;
    final fromCtrl = TextEditingController(
      text: _fromDate != null
          ? _fromDate!.toIso8601String().split('T').first
          : '',
    );
    final toCtrl = TextEditingController(
      text: _toDate != null ? _toDate!.toIso8601String().split('T').first : '',
    );
    final minCtrl = TextEditingController(text: _minAmount?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxAmount?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              Future<void> pickDate(
                TextEditingController ctrl,
                bool isFrom,
              ) async {
                final now = DateTime.now();
                final initial = ctrl.text.isNotEmpty
                    ? DateTime.tryParse(ctrl.text) ?? now
                    : now;
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: initial,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  ctrl.text = picked.toIso8601String().split('T').first;
                  setLocal(() {});
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Invoices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    decoration: InputDecoration(labelText: 'Status'),
                    items: statusOptions,
                    onChanged: (v) => setLocal(() => tempStatus = v ?? 'all'),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Search (ID or Invoice No.)',
                    ),
                    initialValue: tempSearch,
                    onChanged: (v) => tempSearch = v,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fromCtrl,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'From date',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.date_range),
                              onPressed: () => pickDate(fromCtrl, true),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: toCtrl,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'To date',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.date_range),
                              onPressed: () => pickDate(toCtrl, false),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Min amount'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Max amount'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _statusFilter = 'all';
                            _searchText = '';
                            _fromDate = null;
                            _toDate = null;
                            _minAmount = null;
                            _maxAmount = null;
                          });
                          _applyFilters();
                        },
                        child: Text('Clear'),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _statusFilter = tempStatus;
                            _searchText = tempSearch;
                            _fromDate = fromCtrl.text.isNotEmpty
                                ? DateTime.tryParse(fromCtrl.text)
                                : null;
                            _toDate = toCtrl.text.isNotEmpty
                                ? DateTime.tryParse(toCtrl.text)
                                : null;
                            _minAmount = minCtrl.text.isNotEmpty
                                ? double.tryParse(minCtrl.text)
                                : null;
                            _maxAmount = maxCtrl.text.isNotEmpty
                                ? double.tryParse(maxCtrl.text)
                                : null;
                          });
                          _applyFilters();
                        },
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    print(
      'DEBUG: Building invoice card - ID: ${invoice['id']}, Status: ${invoice['status']}',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: invoice['status'] == 'paid'
              ? Colors.green.withOpacity(0.1)
              : Colors.white,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: invoice['status'] == 'paid'
                  ? Colors.green
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long, color: Colors.white, size: 18),
          ),
          title: Text(
            'Invoice #${invoice['invoice_number'] ?? invoice['id']}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                'Amount: \$${invoice['amount']}',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Rent month: ${_getRentMonth(invoice)}',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: invoice['status'] == 'paid' ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              invoice['status'] ?? 'Unknown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            _viewInvoicePDF(invoice);
          },
        ),
      ),
    );
  }

  void _showInvoiceOptions(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Invoice #${invoice['id']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.picture_as_pdf,
                    label: 'View PDF',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _viewInvoicePDF(invoice);
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.download,
                    label: 'Download',
                    color: AppColors.primaryDark,
                    onTap: () {
                      Navigator.pop(context);
                      _downloadInvoice(invoice);
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.share,
                    label: 'Share',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _shareInvoice(invoice);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getRentMonth(Map<String, dynamic> invoice) {
    // Try common fields for month name or y-m
    final candidates = [
      invoice['rent_month'],
      invoice['month'],
      invoice['billing_month'],
      invoice['period'],
      invoice['issue_date'],
      invoice['created_at'],
      invoice['date'],
    ];
    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isEmpty) continue;
      // If it's a full date, format to MMM yyyy
      final dt = DateTime.tryParse(s);
      if (dt != null) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[dt.month - 1] + ' ' + dt.year.toString();
      }
      return s; // already a month label
    }
    return '—';
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewInvoicePDF(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePdfScreen(
          invoiceId: (invoice['id'] as num).toInt(),
          forceTenant: true,
        ),
      ),
    );
  }

  void _makePayment(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePaymentScreen(
          amount: double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0.0,
          invoiceId: invoice['id']?.toString() ?? '',
          invoiceNumber: invoice['invoice_number']?.toString() ?? '',
        ),
      ),
    );
  }

  void _shareInvoice(Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share feature coming soon!')));
  }

  void _downloadInvoice(Map<String, dynamic> invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InvoicePdfScreen(invoiceId: (invoice['id'] as num).toInt()),
      ),
    );
  }
}
