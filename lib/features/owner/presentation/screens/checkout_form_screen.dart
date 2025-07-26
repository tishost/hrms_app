import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/utils/api_config.dart';
import '../../../auth/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/payment_dialog.dart';

class CheckoutFormScreen extends StatefulWidget {
  final Map<String, dynamic>? tenant;
  final Map<String, dynamic>? unit;
  final Map<String, dynamic>? property;

  const CheckoutFormScreen({super.key, this.tenant, this.unit, this.property});

  @override
  State<CheckoutFormScreen> createState() => _CheckoutFormScreenState();
}

class _CheckoutFormScreenState extends State<CheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _checkoutDateController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _outstandingDuesController = TextEditingController();
  final _cleaningChargesController = TextEditingController();
  final _damageChargesController = TextEditingController();
  final _handoverDateController = TextEditingController();
  final _propertyConditionController = TextEditingController();
  final _additionalNoteController = TextEditingController();

  // Dropdown Values
  String? _selectedCheckoutReason;

  // Images
  File? _propertyImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Data for display
  Map<String, dynamic>? _tenantData;
  Map<String, dynamic>? _unitData;
  Map<String, dynamic>? _propertyData;
  String _totalOutstanding = '0';
  List<Map<String, dynamic>> _dueBills = [];

  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadTenantData();
  }

  void _initializeForm() {
    // Set default values
    _checkoutDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now());
    _handoverDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now());

    // Set default values for charge fields
    _cleaningChargesController.text = '0';
    _damageChargesController.text = '0';

    // Pre-fill advance amount if available
    if (widget.tenant != null) {
      _advanceAmountController.text =
          widget.tenant!['security_deposit']?.toString() ?? '0';
    }
  }

  Future<void> _loadTenantData() async {
    if (widget.tenant == null) {
      setState(() {
        _isDataLoading = false;
      });
      return;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Load tenant details with unit and property information
      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenants/${widget.tenant!['id']}')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tenant = data['tenant'];

        // Update advance amount if available
        if (tenant['security_deposit'] != null) {
          _advanceAmountController.text = tenant['security_deposit'].toString();
        }

        // Calculate and set total outstanding (only once)
        if (tenant['unit'] != null && tenant['unit']['id'] != null) {
          await _loadOutstandingAmount(tenant['id'], tenant['unit']['id']);
        }

        setState(() {
          _tenantData = tenant;
          _unitData = tenant['unit'];
          _propertyData = tenant['property'];
          _isDataLoading = false;
        });
      } else {
        // If API call fails, use the passed data
        setState(() {
          _tenantData = widget.tenant;
          _unitData = widget.unit;
          _propertyData = widget.property;
          _isDataLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tenant data: $e');
      // Use the passed data if API call fails
      setState(() {
        _tenantData = widget.tenant;
        _unitData = widget.unit;
        _propertyData = widget.property;
        _isDataLoading = false;
      });
    }
  }

  String _getTotalOutstandingWithCharges() {
    final originalOutstanding = double.tryParse(_totalOutstanding) ?? 0;
    final cleaningCharges =
        double.tryParse(_cleaningChargesController.text) ?? 0;
    final damageCharges = double.tryParse(_damageChargesController.text) ?? 0;

    final totalCharges = cleaningCharges + damageCharges;
    final totalOutstandingWithCharges = originalOutstanding + totalCharges;

    if (totalOutstandingWithCharges > 0) {
      return '৳${totalOutstandingWithCharges.toStringAsFixed(2)}';
    } else {
      return '৳0 (No outstanding)';
    }
  }

  String _getOutstandingDuesLabel() {
    final outstandingDues =
        double.tryParse(_outstandingDuesController.text) ?? 0;
    if (outstandingDues < 0) {
      return 'Refund Amount';
    } else if (outstandingDues > 0) {
      return 'Outstanding Dues';
    } else {
      return 'Settlement';
    }
  }

  String _getOutstandingDuesValue() {
    final outstandingDues =
        double.tryParse(_outstandingDuesController.text) ?? 0;
    if (outstandingDues < 0) {
      return '৳${outstandingDues.abs().toStringAsFixed(2)} (Refund to Tenant)';
    } else if (outstandingDues > 0) {
      return '৳${outstandingDues.toStringAsFixed(2)} (Due from Tenant)';
    } else {
      return '৳0 (Settled)';
    }
  }

  IconData _getOutstandingDuesIcon() {
    final outstandingDues =
        double.tryParse(_outstandingDuesController.text) ?? 0;
    if (outstandingDues < 0) {
      return Icons.money; // Green money icon for refund
    } else if (outstandingDues > 0) {
      return Icons.money_off; // Red money icon for dues
    } else {
      return Icons.check_circle; // Green check for settled
    }
  }

  Color? _getOutstandingDuesBackgroundColor() {
    final outstandingDues =
        double.tryParse(_outstandingDuesController.text) ?? 0;
    if (outstandingDues < 0) {
      return Colors.green[50]; // Light green for refund
    } else if (outstandingDues > 0) {
      return Colors.red[50]; // Light red for dues
    } else {
      return Colors.blue[50]; // Light blue for settled
    }
  }

  Color? _getOutstandingDuesTextColor() {
    final outstandingDues =
        double.tryParse(_outstandingDuesController.text) ?? 0;
    if (outstandingDues < 0) {
      return Colors.green[700]; // Dark green for refund
    } else if (outstandingDues > 0) {
      return Colors.red[700]; // Dark red for dues
    } else {
      return Colors.blue[700]; // Dark blue for settled
    }
  }

  void _updateOutstandingDues() {
    // Calculate Total Outstanding with charges
    final originalOutstanding = double.tryParse(_totalOutstanding) ?? 0;
    final cleaningCharges =
        double.tryParse(_cleaningChargesController.text) ?? 0;
    final damageCharges = double.tryParse(_damageChargesController.text) ?? 0;

    final totalCharges = cleaningCharges + damageCharges;
    final totalOutstandingWithCharges = originalOutstanding + totalCharges;

    // Calculate Outstanding Dues = Total Outstanding with charges - Advance Amount
    final advanceAmount = double.tryParse(_advanceAmountController.text) ?? 0;
    final outstandingDues = totalOutstandingWithCharges - advanceAmount;

    setState(() {
      _outstandingDuesController.text = outstandingDues.toString();
    });
  }

  Future<void> _loadOutstandingAmount(int tenantId, int unitId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return;
      }

      print(
        'DEBUG: Loading outstanding amount for tenant: $tenantId, unit: $unitId',
      );

      // Get outstanding amount from API
      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/tenants/$tenantId/outstanding')),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('DEBUG: API Response status: ${response.statusCode}');
      print('DEBUG: API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final outstandingAmount = data['outstanding_amount'] ?? 0;
        final dueBills = List<Map<String, dynamic>>.from(
          data['due_bills'] ?? [],
        );

        print('DEBUG: Outstanding amount calculated: $outstandingAmount');
        print('DEBUG: Due bills count: ${dueBills.length}');
        print('DEBUG: Due bills data: $dueBills');

        setState(() {
          _totalOutstanding = outstandingAmount.toString();
          _dueBills = dueBills;
        });

        // Update Outstanding Dues after loading data
        _updateOutstandingDues();

        print('DEBUG: State updated - _totalOutstanding: $_totalOutstanding');
        print('DEBUG: State updated - _dueBills length: ${_dueBills.length}');
      } else {
        print('DEBUG: API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading outstanding amount: $e');
    }
  }

  Widget _buildDueBillsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Bills Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Description/Invoice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Amount (৳)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Bills List
              ...(_dueBills
                  .map(
                    (bill) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              bill['description'] ??
                                  bill['invoice_number'] ??
                                  'Unknown',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '৳${bill['amount']?.toString() ?? '0'}',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList()),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _checkoutDateController.dispose();
    _advanceAmountController.dispose();
    _outstandingDuesController.dispose();
    _cleaningChargesController.dispose();
    _damageChargesController.dispose();
    _handoverDateController.dispose();
    _propertyConditionController.dispose();
    _additionalNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tenantData != null
              ? 'Checkout: ${_tenantData!['first_name'] ?? ''} ${_tenantData!['last_name'] ?? ''}'
              : 'New Checkout',
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isDataLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[600]!, Colors.blue[50]!],
                ),
              ),
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          'Tenant & Unit Information',
                          Icons.person,
                        ),
                        SizedBox(height: 20),

                        // Tenant Name (Read Only)
                        _buildReadOnlyField(
                          label: 'Tenant Name',
                          value: _tenantData != null
                              ? '${_tenantData!['first_name'] ?? ''} ${_tenantData!['last_name'] ?? ''}'
                              : 'N/A',
                          icon: Icons.person,
                        ),

                        SizedBox(height: 6),

                        // Property & Unit Info (Responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Mobile: Stack vertically
                            if (constraints.maxWidth < 600) {
                              return Column(
                                children: [
                                  _buildReadOnlyField(
                                    label: 'Property',
                                    value: _propertyData != null
                                        ? '${_propertyData!['name'] ?? ''}'
                                        : 'N/A',
                                    icon: Icons.business,
                                  ),
                                  SizedBox(height: 6),
                                  _buildReadOnlyField(
                                    label: 'Unit',
                                    value: _unitData != null
                                        ? (_unitData!['name'] ??
                                              _unitData!['unit_number'] ??
                                              'N/A')
                                        : 'N/A',
                                    icon: Icons.door_front_door,
                                  ),
                                ],
                              );
                            }
                            // Desktop/Tablet: Side by side
                            else {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Property',
                                      value: _propertyData != null
                                          ? '${_propertyData!['name'] ?? ''}'
                                          : 'N/A',
                                      icon: Icons.business,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Unit',
                                      value: _unitData != null
                                          ? (_unitData!['name'] ??
                                                _unitData!['unit_number'] ??
                                                'N/A')
                                          : 'N/A',
                                      icon: Icons.door_front_door,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),

                        SizedBox(height: 10),

                        _buildSectionTitle(
                          'Financial Settlement',
                          Icons.account_balance_wallet,
                        ),
                        SizedBox(height: 10),

                        // Advance Amount (Read Only)
                        _buildReadOnlyField(
                          label: 'Advance Amount',
                          value: _advanceAmountController.text.isNotEmpty
                              ? '৳${_advanceAmountController.text}'
                              : '৳0',
                          icon: Icons.attach_money,
                        ),

                        SizedBox(height: 8),

                        // Total Outstanding (Read Only)
                        _buildReadOnlyField(
                          label: 'Total Outstanding',
                          value: _getTotalOutstandingWithCharges(),
                          icon: Icons.money_off,
                        ),

                        SizedBox(height: 16),

                        // Due Bills List
                        if (_dueBills.isNotEmpty) ...[
                          _buildDueBillsList(),
                          SizedBox(height: 10),
                        ] else ...[
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Text(
                              'No due bills found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        SizedBox(height: 16),

                        // Charge Fields (Responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Mobile: Stack vertically
                              return Column(
                                children: [
                                  _buildTextField(
                                    controller: _cleaningChargesController,
                                    label: 'Cleaning Charges (৳)',
                                    hint: 'Enter cleaning charges',
                                    icon: Icons.cleaning_services,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _updateOutstandingDues();
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _damageChargesController,
                                    label: 'Damage/Others Charge (৳)',
                                    hint: 'Enter damage or other charges',
                                    icon: Icons.build,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _updateOutstandingDues();
                                    },
                                  ),
                                ],
                              );
                            } else {
                              // Desktop/Tablet: Side by side
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _cleaningChargesController,
                                      label: 'Cleaning Charges (৳)',
                                      hint: 'Enter cleaning charges',
                                      icon: Icons.cleaning_services,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updateOutstandingDues();
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _damageChargesController,
                                      label: 'Damage/Others Charge (৳)',
                                      hint: 'Enter damage or other charges',
                                      icon: Icons.build,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updateOutstandingDues();
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),

                        SizedBox(height: 16),

                        // Outstanding Dues (Read Only - Auto Calculated)
                        _buildReadOnlyField(
                          label: _getOutstandingDuesLabel(),
                          value: _getOutstandingDuesValue(),
                          icon: _getOutstandingDuesIcon(),
                          backgroundColor: _getOutstandingDuesBackgroundColor(),
                          textColor: _getOutstandingDuesTextColor(),
                        ),

                        // Formula explanation
                        SizedBox(height: 15),

                        _buildSectionTitle(
                          'Checkout Details',
                          Icons.exit_to_app,
                        ),
                        SizedBox(height: 20),

                        // Checkout Date & Reason (Responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Mobile: Stack vertically
                              return Column(
                                children: [
                                  _buildDateField(
                                    controller: _checkoutDateController,
                                    label: 'Checkout Date *',
                                    hint: 'Select checkout date',
                                    icon: Icons.calendar_today,
                                    isRequired: true,
                                  ),
                                  SizedBox(height: 16),
                                  _buildDropdownField(
                                    value: _selectedCheckoutReason,
                                    label: 'Checkout Reason *',
                                    hint: 'Select checkout reason',
                                    icon: Icons.help_outline,
                                    items: [
                                      'Contract Expired',
                                      'Personal Reasons',
                                      'Job Transfer',
                                      'Family Emergency',
                                      'Property Issues',
                                      'Financial Problems',
                                      'Other',
                                    ],
                                    onChanged: (value) => setState(
                                      () => _selectedCheckoutReason = value,
                                    ),
                                    isRequired: true,
                                  ),
                                ],
                              );
                            } else {
                              // Desktop/Tablet: Side by side
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildDateField(
                                      controller: _checkoutDateController,
                                      label: 'Checkout Date *',
                                      hint: 'Select checkout date',
                                      icon: Icons.calendar_today,
                                      isRequired: true,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDropdownField(
                                      value: _selectedCheckoutReason,
                                      label: 'Checkout Reason *',
                                      hint: 'Select checkout reason',
                                      icon: Icons.help_outline,
                                      items: [
                                        'Contract Expired',
                                        'Personal Reasons',
                                        'Job Transfer',
                                        'Family Emergency',
                                        'Property Issues',
                                        'Financial Problems',
                                        'Other',
                                      ],
                                      onChanged: (value) => setState(
                                        () => _selectedCheckoutReason = value,
                                      ),
                                      isRequired: true,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),

                        SizedBox(height: 32),

                        _buildSectionTitle(
                          'Handover Information',
                          Icons.handshake,
                        ),
                        SizedBox(height: 20),

                        // Handover Date & Condition (Responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Mobile: Stack vertically
                              return Column(
                                children: [
                                  _buildDateField(
                                    controller: _handoverDateController,
                                    label: 'Handover Date *',
                                    hint: 'Select handover date',
                                    icon: Icons.event,
                                    isRequired: true,
                                  ),
                                  SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _propertyConditionController,
                                    label: 'Unit/Property Condition',
                                    hint: 'Describe property condition',
                                    icon: Icons.description,
                                    maxLines: 3,
                                  ),
                                ],
                              );
                            } else {
                              // Desktop/Tablet: Side by side
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildDateField(
                                      controller: _handoverDateController,
                                      label: 'Handover Date *',
                                      hint: 'Select handover date',
                                      icon: Icons.event,
                                      isRequired: true,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _propertyConditionController,
                                      label: 'Unit/Property Condition',
                                      hint: 'Describe property condition',
                                      icon: Icons.description,
                                      maxLines: 3,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),

                        SizedBox(height: 16),

                        // Property Image
                        _buildImageField(
                          label: 'Property Photo',
                          hint: 'Take photo of property condition',
                          icon: Icons.camera_alt,
                          image: _propertyImage,
                          onTap: () => _pickImage(),
                        ),

                        SizedBox(height: 32),

                        _buildSectionTitle(
                          'Additional Information',
                          Icons.note,
                        ),
                        SizedBox(height: 20),

                        // Additional Note
                        _buildTextField(
                          controller: _additionalNoteController,
                          label: 'Additional Note',
                          hint: 'Any additional comments or notes',
                          icon: Icons.note,
                          maxLines: 4,
                        ),

                        SizedBox(height: 40),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Submit Checkout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor ?? Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor ?? Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                controller.text = DateFormat('yyyy-MM-dd').format(date);
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6),
        DropdownSearch<String>(
          items: items,
          selectedItem: value,
          onChanged: onChanged,
          validator: isRequired
              ? (value) => value == null ? '$label is required' : null
              : null,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            menuProps: MenuProps(
              borderRadius: BorderRadius.circular(8),
              elevation: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageField({
    required String label,
    required String hint,
    required IconData icon,
    File? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 40, color: Colors.grey[600]),
                      SizedBox(height: 8),
                      Text(
                        hint,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      try {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _propertyImage = File(pickedFile.path);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show payment dialog before submitting
    final outstandingDues =
        double.tryParse(_outstandingDuesController.text) ?? 0;

    Map<String, String>? paymentResult;

    if (outstandingDues != 0) {
      paymentResult = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentDialog(
          amount: outstandingDues,
          title: outstandingDues > 0 ? 'Payment Collection' : 'Refund Payment',
          onConfirm: (reference, paymentMethod) {
            Navigator.of(
              context,
            ).pop({'reference': reference, 'paymentMethod': paymentMethod});
          },
        ),
      );

      if (paymentResult == null) {
        return; // User cancelled
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Payment data already collected from dialog above
      String? paymentReference;
      String? paymentMethod;

      if (outstandingDues != 0 && paymentResult != null) {
        paymentReference = paymentResult['reference'];
        paymentMethod = paymentResult['paymentMethod'];
      }

      // Prepare checkout data
      final checkoutData = {
        'tenant_id': _tenantData?['id'],
        'unit_id': _unitData?['id'],
        'property_id': _propertyData?['id'],
        'checkout_date': _checkoutDateController.text,
        'checkout_reason': _selectedCheckoutReason,
        'advance_amount': _advanceAmountController.text,
        'outstanding_dues': _outstandingDuesController.text,
        'cleaning_charges': _cleaningChargesController.text,
        'damage_charges': _damageChargesController.text,
        'handover_date': _handoverDateController.text,
        'property_condition': _propertyConditionController.text,
        'additional_note': _additionalNoteController.text,
        'payment_reference': paymentReference,
        'payment_method': paymentMethod,
      };

      // Create multipart request for images
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getApiUrl('/checkouts')),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add fields
      checkoutData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add property image if selected
      if (_propertyImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'property_image',
            _propertyImage!.path,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      } else {
        throw Exception(
          'Failed to submit checkout: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      print('Error submitting checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting checkout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
