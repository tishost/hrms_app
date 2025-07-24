import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../core/utils/country_helper.dart';
import '../../../../core/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TenantEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? tenant;

  const TenantEntryScreen({Key? key, this.tenant}) : super(key: key);

  @override
  State<TenantEntryScreen> createState() => _TenantEntryScreenState();
}

class _TenantEntryScreenState extends State<TenantEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Information Controllers
  final _nameController =
      TextEditingController(); // Will be parsed to first_name and last_name
  final _genderController = TextEditingController();
  final _phoneController = TextEditingController(); // mobile
  final _altPhoneController = TextEditingController(); // alt_mobile
  final _emailController = TextEditingController();
  final _nidController = TextEditingController(); // nid_number

  // Address Controllers
  final _streetAddressController = TextEditingController(); // address
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();

  // Work Information Controllers
  final _occupationController = TextEditingController();
  String _companyName = '';
  String _collegeUniversity = '';
  String _businessName = '';

  // Driver Information
  bool _isDriver = false;
  final _driverNameController = TextEditingController();

  // Family Information Controllers
  final _familyMemberController =
      TextEditingController(); // total_family_member
  List<String> _familyTypes = []; // Will be joined with comma
  int _childQty = 0;

  // Property & Lease Controllers
  String? _selectedPropertyId; // property_id
  String? _selectedUnitId; // unit_id
  String? _selectedStatus = 'Active'; // status
  final _advanceAmountController = TextEditingController(); // advance_amount
  DateTime? _startMonth; // start_month
  String? _selectedFrequency; // frequency
  final _remarksController = TextEditingController();

  // API Data Lists
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _units = [];
  bool _isLoadingProperties = false;
  bool _isLoadingUnits = false;

  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      _populateForm();
    }
    // Set default values
    _selectedStatus = 'Active';
    _familyMemberController.text = '1';
    _countryController.text = 'Bangladesh';

    // Load properties on init
    _loadProperties();
  }

  void _populateForm() {
    final tenant = widget.tenant!;

    // Basic Information
    String firstName = tenant['first_name']?.toString() ?? '';
    String lastName = tenant['last_name']?.toString() ?? '';
    _nameController.text = '$firstName $lastName'.trim();

    _genderController.text = tenant['gender']?.toString() ?? '';
    _phoneController.text = tenant['mobile']?.toString() ?? '';
    _altPhoneController.text = tenant['alt_mobile']?.toString() ?? '';
    _emailController.text = tenant['email']?.toString() ?? '';
    _nidController.text = tenant['nid_number']?.toString() ?? '';

    // Address
    _streetAddressController.text = tenant['address']?.toString() ?? '';
    _cityController.text = tenant['city']?.toString() ?? '';
    _stateController.text = tenant['state']?.toString() ?? '';
    _zipController.text = tenant['zip']?.toString() ?? '';
    _countryController.text = tenant['country']?.toString() ?? 'Bangladesh';

    // Work Information
    _occupationController.text = tenant['occupation']?.toString() ?? '';
    _companyName = tenant['company_name']?.toString() ?? '';
    _collegeUniversity = tenant['college_university']?.toString() ?? '';
    _businessName = tenant['business_name']?.toString() ?? '';

    // Driver Information
    _isDriver = tenant['is_driver'] == true || tenant['is_driver'] == 'true';
    _driverNameController.text = tenant['driver_name']?.toString() ?? '';

    // Family Information
    _familyMemberController.text =
        tenant['total_family_member']?.toString() ?? '1';
    String familyTypesStr = tenant['family_types']?.toString() ?? '';
    _familyTypes = familyTypesStr.isNotEmpty ? familyTypesStr.split(',') : [];
    _childQty = int.tryParse(tenant['child_qty']?.toString() ?? '0') ?? 0;

    // Property & Lease
    _selectedPropertyId = tenant['property_id']?.toString();
    _selectedUnitId = tenant['unit_id']?.toString();
    _selectedStatus = tenant['status']?.toString() ?? 'Active';
    _advanceAmountController.text = tenant['advance_amount']?.toString() ?? '';
    if (tenant['start_month'] != null) {
      _startMonth = DateTime.tryParse(tenant['start_month'].toString());
    }
    _selectedFrequency = tenant['frequency']?.toString();
    _remarksController.text = tenant['remarks']?.toString() ?? '';
  }

  // API Methods
  Future<void> _loadProperties() async {
    setState(() {
      _isLoadingProperties = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/properties')),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _properties = List<Map<String, dynamic>>.from(
            data['properties'] ?? [],
          );
        });
      } else {
        print('Error loading properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception loading properties: $e');
    } finally {
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  Future<void> _loadUnits(String propertyId) async {
    setState(() {
      _isLoadingUnits = true;
      _units = [];
      _selectedUnitId = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getApiUrl('/properties/$propertyId/units')),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _units = List<Map<String, dynamic>>.from(data['units'] ?? []);
        });
      } else {
        print('Error loading units: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception loading units: $e');
    } finally {
      setState(() {
        _isLoadingUnits = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _nidController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _occupationController.dispose();
    _driverNameController.dispose();
    _familyMemberController.dispose();
    _advanceAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    switch (_currentStep) {
                      0 => _buildPersonalInfoForm(),
                      1 => _buildWorkFamilyForm(),
                      2 => _buildAddressDriverForm(),
                      3 => _buildPropertyLeaseForm(),
                      _ => _buildPersonalInfoForm(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Text(
        widget.tenant != null ? 'Edit Tenant' : 'Add New Tenant',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Draft saved'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          child: Text('Save Draft', style: TextStyle(color: Colors.blue[600])),
        ),
      ],
    );
  }

  Widget _buildStepHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step Indicators
          Row(
            children: List.generate(_totalSteps, (index) {
              bool isActive = index <= _currentStep;
              bool isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue[600] : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: Colors.blue[800]!, width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: isActive
                            ? Icon(
                                index < _currentStep
                                    ? Icons.check
                                    : Icons.circle,
                                color: Colors.white,
                                size: 12,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                      ),
                    ),
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isActive ? Colors.blue[600] : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          SizedBox(height: 10),

          Text(
            _getStepTitle(_currentStep),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 2),

          Text(
            _getStepSubtitle(_currentStep),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(child: _getCurrentStepForm()),
      ),
    );
  }

  Widget _getCurrentStepForm() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoForm();
      case 1:
        return _buildWorkFamilyForm();
      case 2:
        return _buildAddressDriverForm();
      case 3:
        return _buildPropertyLeaseForm();
      default:
        return _buildPersonalInfoForm();
    }
  }

  Widget _buildPersonalInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information', Icons.person),
        SizedBox(height: 20),

        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 20),

        _buildDropdownField(
          value: _genderController.text.isEmpty ? null : _genderController.text,
          label: 'Gender',
          hint: 'Select your gender',
          icon: Icons.wc_outlined,
          items: ['Male', 'Female', 'Other'],
          onChanged: (value) => _genderController.text = value ?? '',
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 20),

        _buildTextField(
          controller: _phoneController,
          label: 'Mobile Number',
          hint: 'Enter your mobile number',
          icon: Icons.phone_outlined,
          isRequired: true,
          keyboardType: TextInputType.phone,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 20),

        _buildTextField(
          controller: _altPhoneController,
          label: 'Alternative Mobile',
          hint: 'Enter alternative mobile number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 20),

        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 20),

        _buildTextField(
          controller: _nidController,
          label: 'NID Number',
          hint: 'Enter your National ID number',
          icon: Icons.credit_card_outlined,
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ],
    );
  }

  Widget _buildWorkFamilyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Work Information', Icons.work),
        SizedBox(height: 20),

        _buildDropdownField(
          value: _occupationController.text.isEmpty
              ? null
              : _occupationController.text,
          label: 'Occupation',
          hint: 'Select your occupation',
          icon: Icons.work_outline,
          items: ['Service', 'Student', 'Business'],
          onChanged: (value) {
            setState(() {
              _occupationController.text = value ?? '';
              // Clear previous values when occupation changes
              _companyName = '';
              _collegeUniversity = '';
              _businessName = '';
            });
          },
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        // Conditional fields based on occupation
        if (_occupationController.text == 'Service') ...[
          SizedBox(height: 16),
          _buildCustomTextField(
            label: 'Company Name',
            hint: 'Enter your company name',
            icon: Icons.business_outlined,
            value: _companyName,
            onChanged: (value) => setState(() => _companyName = value),
            isRequired: true,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ],

        if (_occupationController.text == 'Student') ...[
          SizedBox(height: 16),
          _buildCustomTextField(
            label: 'University/School',
            hint: 'Enter your university or school name',
            icon: Icons.school_outlined,
            value: _collegeUniversity,
            onChanged: (value) => setState(() => _collegeUniversity = value),
            isRequired: true,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ],

        if (_occupationController.text == 'Business') ...[
          SizedBox(height: 16),
          _buildCustomTextField(
            label: 'Business Name',
            hint: 'Enter your business name',
            icon: Icons.store_outlined,
            value: _businessName,
            onChanged: (value) => setState(() => _businessName = value),
            isRequired: true,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ],

        SizedBox(height: 32),

        _buildSectionTitle('Family Information', Icons.family_restroom),
        SizedBox(height: 20),

        _buildTextField(
          controller: _familyMemberController,
          label: 'Total Family Members',
          hint: 'Enter total number of family members',
          icon: Icons.people_outline,
          keyboardType: TextInputType.number,
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildFamilyTypesField(),
      ],
    );
  }

  Widget _buildAddressDriverForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Address Information', Icons.location_on),
        SizedBox(height: 20),

        _buildTextField(
          controller: _streetAddressController,
          label: 'Street Address',
          hint: 'Enter your complete street address',
          icon: Icons.location_on_outlined,
          maxLines: 3,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _cityController,
          label: 'City',
          hint: 'Enter your city',
          icon: Icons.location_city_outlined,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _stateController,
          label: 'State/Division',
          hint: 'Enter your state or division',
          icon: Icons.map_outlined,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _zipController,
          label: 'ZIP/Postal Code',
          hint: 'Enter ZIP or postal code',
          icon: Icons.local_post_office_outlined,
          keyboardType: TextInputType.number,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildSearchableCountryField(),

        SizedBox(height: 32),

        _buildSectionTitle('Driver Information', Icons.directions_car),
        SizedBox(height: 20),

        _buildBooleanField(
          label: 'Do you have a driver?',
          hint: 'Select if you have a driver',
          icon: Icons.person_pin_outlined,
          value: _isDriver,
          onChanged: (value) => setState(() => _isDriver = value),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        if (_isDriver) ...[
          _buildTextField(
            controller: _driverNameController,
            label: 'Driver Name',
            hint: 'Enter driver\'s name',
            icon: Icons.person_outline,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ],
      ],
    );
  }

  Widget _buildPropertyLeaseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Property Assignment', Icons.home),
        SizedBox(height: 20),

        _buildDropdownField(
          value: _selectedPropertyId,
          label: 'Select Property',
          hint: 'Choose a property',
          icon: Icons.apartment_outlined,
          items: _properties
              .map((property) => '${property['id']} - ${property['name']}')
              .toList(),
          onChanged: (value) {
            setState(() => _selectedPropertyId = value);
            if (value != null) {
              String propertyId = value.split(' - ')[0];
              _loadUnits(propertyId);
            }
          },
          isLoading: _isLoadingProperties,
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedUnitId,
          label: 'Select Unit',
          hint: 'Choose a unit',
          icon: Icons.door_front_door_outlined,
          items: _units
              .map(
                (unit) =>
                    '${unit['id']} - ${unit['name']} (Floor ${unit['floor']})',
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedUnitId = value),
          isLoading: _isLoadingUnits,
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedStatus,
          label: 'Tenant Status',
          hint: 'Select tenant status',
          icon: Icons.person_pin_outlined,
          items: ['Active', 'Inactive', 'Checked Out'],
          onChanged: (value) => setState(() => _selectedStatus = value),
          isRequired: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _advanceAmountController,
          label: 'Advance Amount',
          hint: 'Enter advance amount',
          icon: Icons.attach_money_outlined,
          keyboardType: TextInputType.number,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildDateField(
          label: 'Start Month',
          hint: 'Select start month',
          icon: Icons.calendar_today_outlined,
          value: _startMonth,
          onChanged: (date) => setState(() => _startMonth = date),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedFrequency,
          label: 'Payment Frequency',
          hint: 'Select payment frequency',
          icon: Icons.schedule_outlined,
          items: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'],
          onChanged: (value) => setState(() => _selectedFrequency = value),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _remarksController,
          label: 'Remarks',
          hint: 'Enter any additional notes',
          icon: Icons.note_outlined,
          maxLines: 3,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[600], size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floatingLabelBehavior == null) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: floatingLabelBehavior != null
                ? (isRequired ? '$label *' : label)
                : null,
            labelStyle: floatingLabelBehavior != null
                ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required IconData icon,
    required String value,
    required Function(String) onChanged,
    bool isRequired = false,
    TextInputType? keyboardType,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floatingLabelBehavior == null) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
        ],
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          onChanged: (newValue) {
            onChanged(newValue);
          },
          decoration: InputDecoration(
            labelText: floatingLabelBehavior != null
                ? (isRequired ? '$label *' : label)
                : null,
            labelStyle: floatingLabelBehavior != null
                ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
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
    bool isLoading = false,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floatingLabelBehavior == null) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
        ],
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: floatingLabelBehavior != null
                ? (isRequired ? '$label *' : label)
                : null,
            labelStyle: floatingLabelBehavior != null
                ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                : null,
            hintText: hint,
            prefixIcon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required IconData icon,
    required String value,
    required Function(String) onChanged,
    bool isRequired = false,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floatingLabelBehavior == null) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
        ],
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: floatingLabelBehavior != null
                ? (isRequired ? '$label *' : label)
                : null,
            labelStyle: floatingLabelBehavior != null
                ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildBooleanField({
    required String label,
    required String hint,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    bool isRequired = false,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floatingLabelBehavior == null) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
        ],
        DropdownButtonFormField<bool>(
          value: value,
          decoration: InputDecoration(
            labelText: floatingLabelBehavior != null
                ? (isRequired ? '$label *' : label)
                : null,
            labelStyle: floatingLabelBehavior != null
                ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            DropdownMenuItem<bool>(value: true, child: Text('Yes')),
            DropdownMenuItem<bool>(value: false, child: Text('No')),
          ],
          onChanged: (val) => onChanged(val ?? false),
        ),
      ],
    );
  }

  Widget _buildFamilyTypesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Types',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Child',
                      'Parents',
                      'Spouse',
                      'Siblings',
                      'Sister',
                      'Brother',
                      'Others',
                    ].map((type) {
                      bool isSelected = _familyTypes.contains(type);
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _familyTypes.add(type);
                            } else {
                              _familyTypes.remove(type);
                              // Reset child quantity if Child is deselected
                              if (type == 'Child') {
                                _childQty = 0;
                              }
                            }
                          });
                        },
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue[600],
                      );
                    }).toList(),
              ),
              if (_familyTypes.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Selected: ${_familyTypes.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],

              // Show child quantity field if "Child" is selected
              if (_familyTypes.contains('Child')) ...[
                SizedBox(height: 16),
                Divider(color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'Child Quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decrease button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _childQty > 0
                            ? Colors.blue[600]
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: _childQty > 0
                            ? () {
                                setState(() {
                                  _childQty--;
                                });
                              }
                            : null,
                        icon: Icon(Icons.remove, color: Colors.white, size: 14),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Quantity display
                    Container(
                      width: 45,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue[600]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          _childQty.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Increase button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _childQty < 10
                            ? Colors.blue[600]
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: _childQty < 10
                            ? () {
                                setState(() {
                                  _childQty++;
                                });
                              }
                            : null,
                        icon: Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Text(
                  'Maximum 10 children allowed',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6),
        DropdownSearch<String>(
          items: CountryHelper.getCountries(),
          selectedItem: _countryController.text.isEmpty
              ? null
              : _countryController.text,
          onChanged: (value) =>
              setState(() => _countryController.text = value ?? ''),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Country *',
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              hintText: 'Search and select your country',
              prefixIcon: Icon(Icons.flag_outlined, color: Colors.grey[600]),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search country...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            menuProps: MenuProps(
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
            ),
            itemBuilder: (context, item, isSelected) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              );
            },
          ),
          validator: (value) =>
              value?.isEmpty == true ? 'Country is required' : null,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? value,
    required Function(DateTime?) onChanged,
    bool isRequired = false,
    FloatingLabelBehavior? floatingLabelBehavior,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floatingLabelBehavior == null) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
        ],
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: floatingLabelBehavior != null
                ? (isRequired ? '$label *' : label)
                : null,
            labelStyle: floatingLabelBehavior != null
                ? TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  )
                : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          controller: TextEditingController(
            text: value != null
                ? "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}"
                : '',
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            onChanged(pickedDate);
          },
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side - Previous Button or Spacer
          SizedBox(
            width: 100,
            child: _currentStep > 0
                ? TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(), // Empty space when no previous button
          ),

          // Center - Step Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentStep + 1} / $_totalSteps',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ),

          // Right Side - Next/Submit Button
          SizedBox(
            width: 100,
            child: TextButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentStep == _totalSteps - 1 ? 'Submit' : 'Next',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        if (_currentStep < _totalSteps - 1) ...[
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Work & Family Details';
      case 2:
        return 'Address & Driver';
      case 3:
        return 'Property & Lease';
      default:
        return 'Personal Information';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Basic personal information and contact details';
      case 1:
        return 'Work information and family composition';
      case 2:
        return 'Complete address and driver information';
      case 3:
        return 'Property assignment and lease details';
      default:
        return 'Basic personal information';
    }
  }

  void _handleNextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      _submitForm();
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty ||
          _genderController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _nidController.text.isEmpty) {
        _showErrorMessage('Please fill all required fields');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_occupationController.text.isEmpty) {
        _showErrorMessage('Please select an occupation');
        return false;
      }
      if (_occupationController.text == 'Service' && _companyName.isEmpty) {
        _showErrorMessage('Company name is required for Service occupation');
        return false;
      }
      if (_occupationController.text == 'Student' &&
          _collegeUniversity.isEmpty) {
        _showErrorMessage(
          'College/University is required for Student occupation',
        );
        return false;
      }
      if (_occupationController.text == 'Business' && _businessName.isEmpty) {
        _showErrorMessage('Business name is required for Business occupation');
        return false;
      }
      if (_familyMemberController.text.isEmpty) {
        _showErrorMessage('Please fill total family members');
        return false;
      }
      if (_familyTypes.contains('Child') && _childQty == 0) {
        _showErrorMessage(
          'Please specify number of children when Child is selected in family types',
        );
        return false;
      }
    } else if (_currentStep == 3) {
      if (_selectedPropertyId == null ||
          _selectedUnitId == null ||
          _selectedStatus == null) {
        _showErrorMessage('Please fill property assignment information');
        return false;
      }
    }
    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submitForm() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse name into first_name and last_name
      List<String> nameParts = _nameController.text.trim().split(' ');

      // Prepare data exactly as specified by user
      Map<String, dynamic> tenantData = {
        'first_name': nameParts.isNotEmpty ? nameParts.first : '',
        'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'gender': _genderController.text,
        'mobile': _phoneController.text,
        'alt_mobile': _altPhoneController.text,
        'email': _emailController.text,
        'nid_number': _nidController.text,
        'address': _streetAddressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip': _zipController.text,
        'country': _countryController.text,
        'occupation': _occupationController.text,
        'company_name': _companyName,
        'college_university': _collegeUniversity,
        'business_name': _businessName,
        'is_driver': _isDriver.toString(),
        'driver_name': _driverNameController.text,
        'total_family_member': _familyMemberController.text,
        'family_types': _familyTypes.join(','),
        'child_qty': _childQty.toString(),
        'property_id': _selectedPropertyId?.split(' - ')[0] ?? '',
        'unit_id': _selectedUnitId?.split(' - ')[0] ?? '',
        'status': _selectedStatus ?? 'Active',
        'advance_amount': _advanceAmountController.text,
        'start_month': _startMonth?.toIso8601String() ?? '',
        'frequency': _selectedFrequency ?? '',
        'remarks': _remarksController.text,
      };

      // Call actual API
      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('/tenants')),
        headers: ApiConfig.getHeaders(),
        body: json.encode(tenantData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Tenant saved successfully');
      } else {
        print('Error saving tenant: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to save tenant');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.tenant != null
                  ? 'Tenant updated successfully!'
                  : 'Tenant added successfully!',
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
