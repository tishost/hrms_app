import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          Expanded(child: _buildFormContent()),
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
      padding: EdgeInsets.all(20),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue[600] : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: Colors.blue[800]!, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isActive
                            ? Icon(
                                index < _currentStep
                                    ? Icons.check
                                    : Icons.circle,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
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

          SizedBox(height: 16),

          Text(
            _getStepTitle(_currentStep),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 4),

          Text(
            _getStepSubtitle(_currentStep),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
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
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _genderController.text.isEmpty ? null : _genderController.text,
          label: 'Gender',
          hint: 'Select your gender',
          icon: Icons.wc_outlined,
          items: ['Male', 'Female', 'Other'],
          onChanged: (value) => _genderController.text = value ?? '',
          isRequired: true,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _phoneController,
          label: 'Mobile Number',
          hint: 'Enter your mobile number',
          icon: Icons.phone_outlined,
          isRequired: true,
          keyboardType: TextInputType.phone,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _altPhoneController,
          label: 'Alternative Mobile',
          hint: 'Enter alternative mobile number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _nidController,
          label: 'NID Number',
          hint: 'Enter your National ID number',
          icon: Icons.credit_card_outlined,
          isRequired: true,
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

        _buildTextField(
          controller: _occupationController,
          label: 'Occupation',
          hint: 'Enter your occupation',
          icon: Icons.work_outline,
          isRequired: true,
        ),

        SizedBox(height: 16),

        _buildCustomTextField(
          label: 'Company Name',
          hint: 'Enter your company name',
          icon: Icons.business_outlined,
          value: _companyName,
          onChanged: (value) => setState(() => _companyName = value),
        ),

        SizedBox(height: 16),

        _buildCustomTextField(
          label: 'College/University',
          hint: 'Enter your educational institution',
          icon: Icons.school_outlined,
          value: _collegeUniversity,
          onChanged: (value) => setState(() => _collegeUniversity = value),
        ),

        SizedBox(height: 16),

        _buildCustomTextField(
          label: 'Business Name',
          hint: 'Enter business name (if applicable)',
          icon: Icons.store_outlined,
          value: _businessName,
          onChanged: (value) => setState(() => _businessName = value),
        ),

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
        ),

        SizedBox(height: 16),

        _buildNumberField(
          label: 'Number of Children',
          hint: 'Enter number of children',
          icon: Icons.child_care_outlined,
          value: _childQty,
          onChanged: (value) => setState(() => _childQty = value),
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
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _cityController,
          label: 'City',
          hint: 'Enter your city',
          icon: Icons.location_city_outlined,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _stateController,
          label: 'State/Division',
          hint: 'Enter your state or division',
          icon: Icons.map_outlined,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _zipController,
          label: 'ZIP/Postal Code',
          hint: 'Enter ZIP or postal code',
          icon: Icons.local_post_office_outlined,
          keyboardType: TextInputType.number,
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _countryController,
          label: 'Country',
          hint: 'Enter your country',
          icon: Icons.flag_outlined,
        ),

        SizedBox(height: 32),

        _buildSectionTitle('Driver Information', Icons.directions_car),
        SizedBox(height: 20),

        _buildBooleanField(
          label: 'Do you have a driver?',
          hint: 'Select if you have a driver',
          icon: Icons.person_pin_outlined,
          value: _isDriver,
          onChanged: (value) => setState(() => _isDriver = value),
        ),

        SizedBox(height: 16),

        if (_isDriver) ...[
          _buildTextField(
            controller: _driverNameController,
            label: 'Driver Name',
            hint: 'Enter driver\'s name',
            icon: Icons.person_outline,
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
          items: ['1', '2', '3', '4'], // These should be loaded from API
          onChanged: (value) => setState(() => _selectedPropertyId = value),
          isRequired: true,
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedUnitId,
          label: 'Select Unit',
          hint: 'Choose a unit',
          icon: Icons.door_front_door_outlined,
          items: [
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
          ], // These should be loaded from API
          onChanged: (value) => setState(() => _selectedUnitId = value),
          isRequired: true,
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
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _advanceAmountController,
          label: 'Advance Amount',
          hint: 'Enter advance amount',
          icon: Icons.attach_money_outlined,
          keyboardType: TextInputType.number,
        ),

        SizedBox(height: 16),

        _buildDateField(
          label: 'Start Month',
          hint: 'Select start month',
          icon: Icons.calendar_today_outlined,
          value: _startMonth,
          onChanged: (date) => setState(() => _startMonth = date),
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedFrequency,
          label: 'Payment Frequency',
          hint: 'Select payment frequency',
          icon: Icons.schedule_outlined,
          items: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'],
          onChanged: (value) => setState(() => _selectedFrequency = value),
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _remarksController,
          label: 'Remarks',
          hint: 'Enter any additional notes',
          icon: Icons.note_outlined,
          maxLines: 3,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    required int value,
    required Function(int) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 8),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            int? numValue = int.tryParse(val);
            if (numValue != null) onChanged(numValue);
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        DropdownButtonFormField<bool>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      'Father',
                      'Mother',
                      'Spouse',
                      'Son',
                      'Daughter',
                      'Brother',
                      'Sister',
                      'Other',
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
            ],
          ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                      _currentStep == _totalSteps - 1 ? 'Submit' : 'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
      if (_occupationController.text.isEmpty ||
          _familyMemberController.text.isEmpty) {
        _showErrorMessage('Please fill occupation and family information');
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
        'property_id': _selectedPropertyId ?? '',
        'unit_id': _selectedUnitId ?? '',
        'status': _selectedStatus ?? 'Active',
        'advance_amount': _advanceAmountController.text,
        'start_month': _startMonth?.toIso8601String() ?? '',
        'frequency': _selectedFrequency ?? '',
        'remarks': _remarksController.text,
      };

      // TODO: Call actual API here
      print('Tenant Data: $tenantData');
      await Future.delayed(Duration(seconds: 2));

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
