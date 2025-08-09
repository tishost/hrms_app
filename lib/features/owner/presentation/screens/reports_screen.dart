import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/features/owner/data/services/report_service.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  List<Map<String, dynamic>> _reportTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadReportTypes();
    });
  }

  Future<void> _loadReportTypes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to load from API first
      try {
        final response = await _reportService.getReportTypes();
        if (response['success']) {
          setState(() {
            _reportTypes = List<Map<String, dynamic>>.from(
              response['report_types'],
            );
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('API Error: $e');
      }

      // Fallback to hardcoded report types
      setState(() {
        _reportTypes = [
          {
            'id': 'financial',
            'name': 'Financial Report',
            'description': 'Revenue, payments, and financial summary',
            'parameters': ['start_date', 'end_date', 'type'],
          },
          {
            'id': 'occupancy',
            'name': 'Occupancy Report',
            'description': 'Property and unit occupancy status',
            'parameters': [],
          },
          {
            'id': 'tenant',
            'name': 'Tenant Report',
            'description': 'Tenant information and payment history',
            'parameters': [],
          },
          {
            'id': 'transaction',
            'name': 'Transaction Report',
            'description': 'Detailed transaction ledger',
            'parameters': ['start_date', 'end_date', 'type'],
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToReport(String reportId, Map<String, dynamic> reportType) {
    try {
      switch (reportId) {
        case 'financial':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FinancialReportScreen(reportType: reportType),
            ),
          );
          break;
        case 'occupancy':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OccupancyReportScreen(reportType: reportType),
            ),
          );
          break;
        case 'tenant':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenantReportScreen(reportType: reportType),
            ),
          );
          break;
        case 'transaction':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionReportScreen(reportType: reportType),
            ),
          );
          break;
      }
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: Text(
          'Reports',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report, color: AppColors.white),
            onPressed: () async {
              print('Debug: Testing API connection...');
              final token = await AuthService.getToken();
              print('Debug: Token: ${token?.substring(0, 20)}...');
              print(
                'API URL: ${ApiConfig.getApiUrl('/reports/rent-collection')}',
              );
              _loadReportTypes();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReportTypes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _reportTypes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reports available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReportTypes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reportTypes.length,
              itemBuilder: (context, index) {
                final reportType = _reportTypes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        _getReportIcon(reportType['id']),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      reportType['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          reportType['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (reportType['parameters'] != null &&
                            (reportType['parameters'] as List).isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: (reportType['parameters'] as List)
                                .map<Widget>(
                                  (param) => Chip(
                                    label: Text(
                                      param,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.blue[50],
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      try {
                        _navigateToReport(reportType['id'], reportType);
                      } catch (e) {
                        print('Error navigating to report: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to open report: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 5, // Reports index
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/properties');
              break;
            case 2:
              context.go('/units');
              break;
            case 3:
              context.go('/tenants');
              break;
            case 4:
              context.go('/billing');
              break;
            case 5:
              // Already on reports screen
              break;
          }
        },
      ),
    );
  }

  IconData _getReportIcon(String reportId) {
    switch (reportId) {
      case 'financial':
        return Icons.attach_money;
      case 'occupancy':
        return Icons.home;
      case 'tenant':
        return Icons.people;
      case 'transaction':
        return Icons.receipt_long;
      default:
        return Icons.assessment;
    }
  }
}

class FinancialReportScreen extends StatefulWidget {
  final Map<String, dynamic> reportType;

  const FinancialReportScreen({super.key, required this.reportType});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final ReportService _reportService = ReportService();
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'all';
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  final List<String> _types = ['all', 'rent', 'charges'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.reportType['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start Date
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Start Date'),
                        subtitle: Text(
                          _startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Select start date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                      ),

                      // End Date
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('End Date'),
                        subtitle: Text(
                          _endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'Select end date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),

                      // Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Report Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Generate Report'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_reportData != null) ...[
              const SizedBox(height: 24),
              _buildReportDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _reportService.generateFinancialReport(
        startDate: _startDate!,
        endDate: _endDate!,
        type: _selectedType,
      );

      if (response['success']) {
        setState(() {
          _reportData = response['report'];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to generate report'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildReportDisplay() {
    final report = _reportData!;
    final summary = report['summary'];
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Total Invoiced',
                  currencyFormat.format(summary['total_invoiced']),
                ),
                _buildSummaryRow(
                  'Total Paid',
                  currencyFormat.format(summary['total_paid']),
                  Colors.green,
                ),
                _buildSummaryRow(
                  'Total Unpaid',
                  currencyFormat.format(summary['total_unpaid']),
                  Colors.red,
                ),
                _buildSummaryRow(
                  'Collection Rate',
                  '${summary['collection_rate']}%',
                ),
                const SizedBox(height: 16),
                Text(
                  'Generated: ${report['generated_at']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        if (report['monthly_breakdown'] != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: () {
                  List<Widget> widgets = [
                    const Text(
                      'Monthly Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ];
                  final monthlyBreakdown = report['monthly_breakdown'];
                  if (monthlyBreakdown is Map) {
                    widgets.addAll(
                      monthlyBreakdown.entries.map((entry) {
                        final month = entry.key;
                        final data = entry.value;
                        return ListTile(
                          title: Text(month),
                          subtitle: Text('${data['count']} invoices'),
                          trailing: Text(
                            currencyFormat.format(data['total']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    );
                  } else if (monthlyBreakdown is List) {
                    widgets.addAll(
                      monthlyBreakdown.asMap().entries.map((entry) {
                        final month = entry.key.toString();
                        final data = entry.value;
                        return ListTile(
                          title: Text(month),
                          subtitle: Text('${data['count']} invoices'),
                          trailing: Text(
                            currencyFormat.format(data['total']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return widgets;
                }(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class OccupancyReportScreen extends StatefulWidget {
  final Map<String, dynamic> reportType;

  const OccupancyReportScreen({super.key, required this.reportType});

  @override
  State<OccupancyReportScreen> createState() => _OccupancyReportScreenState();
}

class _OccupancyReportScreenState extends State<OccupancyReportScreen> {
  final ReportService _reportService = ReportService();
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _reportService.generateOccupancyReport();
      if (response['success']) {
        setState(() {
          _reportData = response['report'];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to generate report'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportType['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildPropertiesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _reportData!['summary'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Total Properties',
              summary['total_properties'].toString(),
            ),
            _buildSummaryRow('Total Units', summary['total_units'].toString()),
            _buildSummaryRow(
              'Occupied Units',
              summary['total_occupied'].toString(),
              Colors.green,
            ),
            _buildSummaryRow(
              'Vacant Units',
              summary['total_vacant'].toString(),
              Colors.red,
            ),
            _buildSummaryRow(
              'Overall Occupancy Rate',
              '${summary['overall_occupancy_rate']}%',
            ),
            const SizedBox(height: 16),
            Text(
              'Generated: ${_reportData!['generated_at']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesList() {
    final properties = _reportData!['properties'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...properties.map(
          (property) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                property['property_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${property['occupied_units']}/${property['total_units']} units occupied (${property['occupancy_rate']}%)',
              ),
              children: [
                ...(property['units'] as List).map(
                  (unit) => ListTile(
                    leading: Icon(
                      unit['status'] == 'rented'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: unit['status'] == 'rented'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(unit['unit_name']),
                    subtitle: Text(unit['tenant_name']),
                    trailing: Text(
                      '\$${unit['rent']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class TenantReportScreen extends StatefulWidget {
  final Map<String, dynamic> reportType;

  const TenantReportScreen({super.key, required this.reportType});

  @override
  State<TenantReportScreen> createState() => _TenantReportScreenState();
}

class _TenantReportScreenState extends State<TenantReportScreen> {
  final ReportService _reportService = ReportService();
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _reportService.generateTenantReport();
      if (response['success']) {
        setState(() {
          _reportData = response['report'];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to generate report'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportType['name']),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildTenantsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _reportData!['summary'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Total Tenants',
              summary['total_tenants'].toString(),
            ),
            _buildSummaryRow(
              'Active Tenants',
              summary['active_tenants'].toString(),
              Colors.green,
            ),
            _buildSummaryRow(
              'Inactive Tenants',
              summary['inactive_tenants'].toString(),
              Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Generated: ${_reportData!['generated_at']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantsList() {
    final tenants = _reportData!['tenants'] as List;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tenants',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...tenants.map(
          (tenant) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                tenant['tenant_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${tenant['property_name']} - ${tenant['unit_name']}',
              ),
              children: [
                ListTile(
                  title: const Text('Contact Information'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${tenant['phone']}'),
                      Text('Email: ${tenant['email']}'),
                      Text('Move-in Date: ${tenant['move_in_date']}'),
                      Text('Status: ${tenant['status']}'),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text('Financial Summary'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent Amount: ${currencyFormat.format(tenant['rent'])}',
                      ),
                      Text(
                        'Total Invoices: ${tenant['invoice_stats']['total_invoices']}',
                      ),
                      Text(
                        'Paid Invoices: ${tenant['invoice_stats']['paid_invoices']}',
                      ),
                      Text(
                        'Unpaid Invoices: ${tenant['invoice_stats']['unpaid_invoices']}',
                      ),
                      Text(
                        'Total Amount: ${currencyFormat.format(tenant['invoice_stats']['total_amount'])}',
                      ),
                      Text(
                        'Paid Amount: ${currencyFormat.format(tenant['invoice_stats']['paid_amount'])}',
                      ),
                      Text(
                        'Outstanding: ${currencyFormat.format(tenant['invoice_stats']['outstanding_amount'])}',
                      ),
                      Text(
                        'Payment Rate: ${tenant['invoice_stats']['payment_rate']}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionReportScreen extends StatefulWidget {
  final Map<String, dynamic> reportType;

  const TransactionReportScreen({super.key, required this.reportType});

  @override
  State<TransactionReportScreen> createState() =>
      _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen> {
  final ReportService _reportService = ReportService();
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'all';
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  final List<String> _types = ['all', 'rent', 'charges', 'payment'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportType['name']),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start Date
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Start Date'),
                        subtitle: Text(
                          _startDate != null
                              ? DateFormat('yyyy-MM-dd').format(_startDate!)
                              : 'Select start date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                      ),

                      // End Date
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('End Date'),
                        subtitle: Text(
                          _endDate != null
                              ? DateFormat('yyyy-MM-dd').format(_endDate!)
                              : 'Select end date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),

                      // Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Generate Report'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_reportData != null) ...[
              const SizedBox(height: 24),
              _buildReportDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _reportService.generateTransactionReport(
        startDate: _startDate!,
        endDate: _endDate!,
        type: _selectedType,
      );

      if (response['success']) {
        setState(() {
          _reportData = response['report'];
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to generate report'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildReportDisplay() {
    final report = _reportData!;
    final summary = report['summary'];
    final transactions = report['transactions'] as List;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Total Transactions',
                  summary['total_transactions'].toString(),
                ),
                _buildSummaryRow(
                  'Total Debit',
                  currencyFormat.format(summary['total_debit']),
                  Colors.red,
                ),
                _buildSummaryRow(
                  'Total Credit',
                  currencyFormat.format(summary['total_credit']),
                  Colors.green,
                ),
                _buildSummaryRow(
                  'Net Amount',
                  currencyFormat.format(summary['net_amount']),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generated: ${report['generated_at']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...transactions.map(
          (transaction) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(transaction['tenant_name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction['property_name']} - ${transaction['unit_name']}',
                  ),
                  Text(
                    '${transaction['transaction_type']} - ${transaction['description']}',
                  ),
                  Text('Date: ${transaction['date']}'),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transaction['debit_amount'] > 0)
                    Text(
                      '-${currencyFormat.format(transaction['debit_amount'])}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (transaction['credit_amount'] > 0)
                    Text(
                      '+${currencyFormat.format(transaction['credit_amount'])}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    transaction['payment_status'],
                    style: TextStyle(
                      fontSize: 12,
                      color: transaction['payment_status'] == 'paid'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
