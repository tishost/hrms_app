import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/utils/country_helper.dart';
import '../../../../core/utils/api_config.dart';
import '../../../auth/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TenantEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? tenant;

  const TenantEntryScreen({super.key, this.tenant});

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

  // NID Images
  File? _nidFrontImage;
  File? _nidBackImage;
  String? _existingNidFrontUrl;
  String? _existingNidBackUrl;
  final ImagePicker _imagePicker = ImagePicker();

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
  final _feesController = TextEditingController(); // total fees
  String? _selectedStartMonth; // start_month
  String? _selectedFrequency; // frequency
  final _remarksController = TextEditingController();

  // API Data Lists
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _allUnits = []; // Store all units for filtering
  bool _isLoadingProperties = false;
  bool _isLoadingUnits = false;
  Map<String, String?>?
  _pendingSelections; // Store pending selections for edit mode

  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      _fetchTenantData();
      // Edit mode will start from step 1 (Basic Information)
      _currentStep = 0;
    }
    // Set default values
    _selectedStatus = 'Active';
    _familyMemberController.text = '1';
    if (widget.tenant == null) {
      _countryController.text = 'Bangladesh';
      _selectedFrequency = 'Monthly';
      _genderController.text = 'Male';
    }

    // Load properties and units on init - first properties, then units
    _loadPropertiesAndUnits();

    // Clear unit selection to avoid duplicate value issues
    _selectedUnitId = null;
  }

  Future<void> _loadPropertiesAndUnits() async {
    // First load all properties
    await _loadProperties();

    // Then load all units (rented and vacant)
    await _loadAllUnits();

    // Apply pending selections if any (for edit mode)
    if (_pendingSelections != null) {
      _setPropertyAndUnitSelections(
        _pendingSelections!['propertyId'],
        _pendingSelections!['unitId'],
        _pendingSelections!['startMonth'],
      );
      _pendingSelections = null; // Clear pending selections
    }
  }

  void _setPropertyAndUnitSelections(
    String? propertyId,
    String? unitId,
    String? startMonth,
  ) {
    print('DEBUG: _setPropertyAndUnitSelections called');
    print(
      'DEBUG: propertyId: $propertyId, unitId: $unitId, startMonth: $startMonth',
    );
    print('DEBUG: _properties length: ${_properties.length}');
    print('DEBUG: _allUnits length: ${_allUnits.length}');

    if (propertyId != null && _properties.isNotEmpty) {
      // Find property by ID
      final property = _properties.firstWhere(
        (p) => p['id'].toString() == propertyId,
        orElse: () => _properties.first,
      );
      _selectedPropertyId = property['name'] as String;
      print('DEBUG: Set selected property: $_selectedPropertyId');
    } else {
      _selectedPropertyId = null;
    }

    if (unitId != null && _allUnits.isNotEmpty) {
      // Find unit by ID
      final unit = _allUnits.firstWhere(
        (u) => u['id'].toString() == unitId,
        orElse: () => _allUnits.first,
      );
      _selectedUnitId = unit['name'] as String;
      print('DEBUG: Set selected unit ID: $_selectedUnitId');
      print('DEBUG: Unit data: $unit');

      // Also update _units list to include this unit for fees calculation
      if (!_units.any((u) => u['id'] == unit['id'])) {
        _units.add(unit);
      }
    } else {
      _selectedUnitId = null;
    }

    if (startMonth != null) {
      // Convert "07-2025" format to "July-25" format for dropdown
      _selectedStartMonth = _convertDateToMonthYear(startMonth);
    }

    // Calculate fees for edit mode
    if (_selectedUnitId != null) {
      _calculateFeesForSelectedUnit();
    }

    setState(() {});
  }

  Future<void> _fetchTenantData() async {
    if (widget.tenant == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = ApiConfig.getApiUrl('/tenants/${widget.tenant!['id']}');
      print('DEBUG: Fetching tenant data from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('DEBUG: Tenant fetch response status: ${response.statusCode}');
      print('DEBUG: Tenant fetch response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed tenant data: $data');
        print('DEBUG: Data keys: ${data.keys.toList()}');
        print('DEBUG: Has tenant key: ${data.containsKey('tenant')}');

        if (data['tenant'] != null) {
          final tenantData = data['tenant'];
          print('DEBUG: Tenant data found, calling _populateFormWithData');
          _populateFormWithData(tenantData);
        } else {
          print('DEBUG: No tenant data found in response');
          print('DEBUG: Full response structure: $data');
        }
      } else {
        print('DEBUG: Failed to fetch tenant data: ${response.statusCode}');
        _showErrorMessage('Failed to load tenant data');
      }
    } catch (e) {
      print('DEBUG: Error fetching tenant data: $e');
      _showErrorMessage('Error loading tenant data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormWithData(Map<String, dynamic> tenant) {
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
    _isDriver =
        tenant['is_driver'] == true ||
        tenant['is_driver'] == 'true' ||
        tenant['is_driver'] == 1 ||
        tenant['is_driver'] == '1';
    _driverNameController.text = tenant['driver_name']?.toString() ?? '';

    print('DEBUG: Driver Information from API:');
    print('DEBUG: is_driver from API: ${tenant['is_driver']}');
    print('DEBUG: driver_name from API: ${tenant['driver_name']}');
    print('DEBUG: _isDriver set to: $_isDriver');
    print(
      'DEBUG: _driverNameController.text set to: ${_driverNameController.text}',
    );

    // Family Information
    _familyMemberController.text =
        tenant['total_family_member']?.toString() ?? '1';
    String familyTypesStr = tenant['family_types']?.toString() ?? '';
    _familyTypes = familyTypesStr.isNotEmpty ? familyTypesStr.split(',') : [];
    _childQty = int.tryParse(tenant['child_qty']?.toString() ?? '0') ?? 0;

    // Property & Lease - Set to null initially to avoid dropdown errors
    // We'll set these after properties and units are loaded
    _selectedPropertyId = null;
    _selectedUnitId = null;
    _selectedStartMonth = null; // Set to null to avoid dropdown errors

    // Store original property and unit IDs for later selection
    final originalPropertyId = tenant['property_id']?.toString();
    final originalUnitId = tenant['unit_id']?.toString();
    final originalStartMonth = tenant['start_month']?.toString();

    // Wait for properties and units to load before setting values
    // We'll call this after data is loaded
    _pendingSelections = {
      'propertyId': originalPropertyId,
      'unitId': originalUnitId,
      'startMonth': originalStartMonth,
    };
    _selectedStatus = tenant['status']?.toString() ?? 'Active';
    _advanceAmountController.text = tenant['advance_amount']?.toString() ?? '';
    if (tenant['start_month'] != null) {
      _selectedStartMonth = tenant['start_month'].toString();
    }
    _selectedFrequency = tenant['frequency']?.toString();
    _remarksController.text = tenant['remarks']?.toString() ?? '';

    // NID Images - Note: These will be loaded from URLs, not local files
    // For edit mode, we'll show existing images if available
    if (tenant['nid_front_picture'] != null) {
      _existingNidFrontUrl = tenant['nid_front_picture'];
      print('DEBUG: NID front picture exists: ${tenant['nid_front_picture']}');
    }
    if (tenant['nid_back_picture'] != null) {
      _existingNidBackUrl = tenant['nid_back_picture'];
      print('DEBUG: NID back picture exists: ${tenant['nid_back_picture']}');
    }

    // Don't set property and unit IDs here - they will be set in _setPropertyAndUnitSelections
    // _selectedPropertyId = tenant['property_id']?.toString();
    // _selectedUnitId = tenant['unit_id']?.toString();
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
    _isDriver =
        tenant['is_driver'] == true ||
        tenant['is_driver'] == 'true' ||
        tenant['is_driver'] == 1 ||
        tenant['is_driver'] == '1';
    _driverNameController.text = tenant['driver_name']?.toString() ?? '';

    // Family Information
    _familyMemberController.text =
        tenant['total_family_member']?.toString() ?? '1';
    String familyTypesStr = tenant['family_types']?.toString() ?? '';
    _familyTypes = familyTypesStr.isNotEmpty ? familyTypesStr.split(',') : [];
    _childQty = int.tryParse(tenant['child_qty']?.toString() ?? '0') ?? 0;

    // Property & Lease - Don't set these here, they will be set properly later
    // _selectedPropertyId = tenant['property_id']?.toString();
    // _selectedUnitId = tenant['unit_id']?.toString();
    _selectedStatus = tenant['status']?.toString() ?? 'Active';
    _advanceAmountController.text = tenant['advance_amount']?.toString() ?? '';
    if (tenant['start_month'] != null) {
      _selectedStartMonth = tenant['start_month'].toString();
    }
    _selectedFrequency = tenant['frequency']?.toString();
    _remarksController.text = tenant['remarks']?.toString() ?? '';

    // NID Images - Note: These will be loaded from URLs, not local files
    // For edit mode, we'll show existing images if available
    if (tenant['nid_front_picture'] != null) {
      _existingNidFrontUrl = tenant['nid_front_picture'];
      print('DEBUG: NID front picture exists: ${tenant['nid_front_picture']}');
    }
    if (tenant['nid_back_picture'] != null) {
      _existingNidBackUrl = tenant['nid_back_picture'];
      print('DEBUG: NID back picture exists: ${tenant['nid_back_picture']}');
    }
  }

  // API Methods
  Future<void> _loadProperties() async {
    setState(() {
      _isLoadingProperties = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = ApiConfig.getApiUrl('/properties');
      print('DEBUG: Loading properties from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('DEBUG: Properties response status: ${response.statusCode}');
      print('DEBUG: Properties response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed data: $data');

        List<Map<String, dynamic>> properties = [];
        if (data['properties'] != null) {
          properties = List<Map<String, dynamic>>.from(data['properties']);
        } else if (data['data'] != null) {
          properties = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          properties = List<Map<String, dynamic>>.from(data);
        }

        print('DEBUG: Final properties list: $properties');

        setState(() {
          _properties = properties;
        });

        // Add test data if no properties found
        if (properties.isEmpty) {
          print('DEBUG: No properties found, adding test data');
          setState(() {
            _properties = [
              {'id': 1, 'name': 'Test Property 1'},
              {'id': 2, 'name': 'Test Property 2'},
            ];
          });
        }
      } else {
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading properties: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading properties: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProperties = false;
        });
      }
    }
  }

  Future<void> _loadAllUnits() async {
    setState(() {
      _isLoadingUnits = true;
      _units = [];
      _selectedUnitId = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = ApiConfig.getApiUrl('/units');
      print('DEBUG: Loading all units from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('DEBUG: All units response status: ${response.statusCode}');
      print('DEBUG: All units response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed all units data: $data');

        List<Map<String, dynamic>> units = [];
        if (data['units'] != null) {
          units = List<Map<String, dynamic>>.from(data['units']);
        } else if (data['data'] != null) {
          units = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          units = List<Map<String, dynamic>>.from(data);
        }

        print('DEBUG: Final all units list: $units');

        // Debug: Print status values of first few units
        if (units.isNotEmpty) {
          print('DEBUG: First unit status: ${units.first['status']}');
          print(
            'DEBUG: Available status values: ${units.map((u) => u['status']).toSet()}',
          );
        }

        setState(() {
          _allUnits = units; // Store all units
          // Show all units initially for both new entry and edit mode
          _units = units;
          print('DEBUG: Loaded ${_units.length} units');
        });

        // Add test data if no units found
        if (units.isEmpty) {
          print('DEBUG: No units found, adding test data');
          setState(() {
            _units = [
              {'id': 1, 'name': 'Unit A1'},
              {'id': 2, 'name': 'Unit A2'},
              {'id': 3, 'name': 'Unit B1'},
              {'id': 4, 'name': 'Unit B2'},
              {'id': 5, 'name': 'Unit C1'},
            ];
          });
        }
      } else {
        throw Exception('Failed to load units: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading all units: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading units: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUnits = false;
        });
      }
    }
  }

  Future<void> _loadUnits(String propertyId) async {
    setState(() {
      _isLoadingUnits = true;
      _units = [];
      _selectedUnitId = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = ApiConfig.getApiUrl('/units?property_id=$propertyId');
      print('DEBUG: Loading units from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('DEBUG: Units response status: ${response.statusCode}');
      print('DEBUG: Units response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed units data: $data');

        List<Map<String, dynamic>> units = [];
        if (data['units'] != null) {
          units = List<Map<String, dynamic>>.from(data['units']);
        } else if (data['data'] != null) {
          units = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          units = List<Map<String, dynamic>>.from(data);
        }

        print('DEBUG: Final units list: $units');

        setState(() {
          _units = units;
        });

        // Add test data if no units found
        if (units.isEmpty) {
          print('DEBUG: No units found, adding test data');
          setState(() {
            _units = [
              {'id': 1, 'name': 'Unit A1'},
              {'id': 2, 'name': 'Unit A2'},
              {'id': 3, 'name': 'Unit B1'},
            ];
          });
        }
      } else {
        throw Exception('Failed to load units: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading units: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading units: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUnits = false;
        });
      }
    }
  }

  List<Widget> _buildChargesList() {
    print('DEBUG: _buildChargesList called');
    print('DEBUG: _selectedUnitId: $_selectedUnitId');
    print('DEBUG: widget.tenant != null: ${widget.tenant != null}');

    if (_selectedUnitId == null) {
      print('DEBUG: _selectedUnitId is null, returning empty list');
      return [];
    }

    // Use _allUnits for edit mode, _units for create mode
    final unitList = widget.tenant != null ? _allUnits : _units;
    print('DEBUG: Using unitList length: ${unitList.length}');

    final selectedUnit = unitList.firstWhere(
      (unit) => unit['name'] == _selectedUnitId,
      orElse: () => {},
    );

    print('DEBUG: Selected unit in _buildChargesList: $selectedUnit');
    if (selectedUnit.isEmpty) {
      print(
        'DEBUG: Selected unit is empty in _buildChargesList, returning empty list',
      );
      return [];
    }

    List<Widget> widgets = [];

    // Add Rent
    widgets.add(
      Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Rent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '৳${(selectedUnit['rent'] is double) ? selectedUnit['rent'].toStringAsFixed(2) : double.tryParse(selectedUnit['rent'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Add Charges
    if (selectedUnit['charges'] != null) {
      for (var charge in selectedUnit['charges']) {
        widgets.add(
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      charge['label'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '৳${(charge['amount'] is double) ? charge['amount'].toStringAsFixed(2) : double.tryParse(charge['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<String> _generateMonthYearOptions() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final currentYear = DateTime.now().year;
    List<String> options = [];

    // Generate options for current year and next year
    for (int year = currentYear; year <= currentYear + 1; year++) {
      for (int month = 0; month < months.length; month++) {
        // Skip past months for current year
        if (year == currentYear && month < DateTime.now().month - 1) {
          continue;
        }
        options.add('${months[month]}-${year.toString().substring(2)}');
      }
    }

    return options;
  }

  String _getPropertyIdByName(String? propertyName) {
    if (propertyName == null) return '';
    try {
      final property = _properties.firstWhere((p) => p['name'] == propertyName);
      return property['id'].toString();
    } catch (e) {
      print('DEBUG: Property not found: $propertyName');
      return '';
    }
  }

  String _getUnitIdByName(String? unitName) {
    if (unitName == null) return '';
    try {
      // Use _allUnits for edit mode, _units for create mode
      final unitList = widget.tenant != null ? _allUnits : _units;
      final unit = unitList.firstWhere((u) => u['name'] == unitName);
      return unit['id'].toString();
    } catch (e) {
      print('DEBUG: Unit not found: $unitName');
      final unitList = widget.tenant != null ? _allUnits : _units;
      print(
        'DEBUG: Available units: ${unitList.map((u) => u['name']).toList()}',
      );
      return '';
    }
  }

  String _convertMonthYearToDate(String? monthYear) {
    if (monthYear == null || monthYear.isEmpty) return '';

    try {
      // Parse "January-25" format to "01-2025" format
      final parts = monthYear.split('-');
      if (parts.length != 2) return '';

      final monthName = parts[0];
      final year = parts[1];

      // Convert month name to number
      final months = {
        'January': '01',
        'February': '02',
        'March': '03',
        'April': '04',
        'May': '05',
        'June': '06',
        'July': '07',
        'August': '08',
        'September': '09',
        'October': '10',
        'November': '11',
        'December': '12',
      };

      final monthNumber = months[monthName];
      if (monthNumber == null) return '';

      // Convert 2-digit year to 4-digit year
      final fullYear = year.length == 2 ? '20$year' : year;

      return '$monthNumber-$fullYear';
    } catch (e) {
      print('DEBUG: Error converting month year: $e');
      return '';
    }
  }

  String _convertDateToMonthYear(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      // Parse "07-2025" format to "July-25" format
      final parts = date.split('-');
      if (parts.length != 2) return '';

      final monthNumber = parts[0];
      final year = parts[1];

      // Convert month number to name
      final months = {
        '01': 'January',
        '02': 'February',
        '03': 'March',
        '04': 'April',
        '05': 'May',
        '06': 'June',
        '07': 'July',
        '08': 'August',
        '09': 'September',
        '10': 'October',
        '11': 'November',
        '12': 'December',
      };

      final monthName = months[monthNumber];
      if (monthName == null) return '';

      // Convert 4-digit year to 2-digit year
      final shortYear = year.length == 4 ? year.substring(2) : year;

      return '$monthName-$shortYear';
    } catch (e) {
      print('DEBUG: Error converting date to month year: $e');
      return '';
    }
  }

  void _calculateFeesForSelectedUnit() {
    print('DEBUG: _calculateFeesForSelectedUnit called');
    print('DEBUG: _selectedUnitId: $_selectedUnitId');
    print('DEBUG: widget.tenant != null: ${widget.tenant != null}');
    print('DEBUG: _allUnits length: ${_allUnits.length}');
    print('DEBUG: _units length: ${_units.length}');

    if (_selectedUnitId == null) {
      print('DEBUG: _selectedUnitId is null, returning');
      return;
    }

    // Use _allUnits for edit mode, _units for create mode
    final unitList = widget.tenant != null ? _allUnits : _units;
    print('DEBUG: Using unitList length: ${unitList.length}');

    final selectedUnit = unitList.firstWhere(
      (unit) => unit['name'] == _selectedUnitId,
      orElse: () => {},
    );

    print('DEBUG: Selected unit: $selectedUnit');
    if (selectedUnit.isEmpty) {
      print('DEBUG: Selected unit is empty, returning');
      return;
    }

    double totalFees = 0.0;

    // Add rent
    if (selectedUnit['rent'] != null) {
      totalFees += (selectedUnit['rent'] is double)
          ? selectedUnit['rent']
          : double.tryParse(selectedUnit['rent'].toString()) ?? 0.0;
    }

    // Add charges
    if (selectedUnit['charges'] != null) {
      for (var charge in selectedUnit['charges']) {
        if (charge['amount'] != null) {
          double chargeAmount = (charge['amount'] is double)
              ? charge['amount']
              : double.tryParse(charge['amount'].toString()) ?? 0.0;
          totalFees += chargeAmount;
        }
      }
    }

    setState(() {
      _feesController.text = totalFees.toStringAsFixed(2);
    });
  }

  // NID Image Picker Methods
  Future<void> _pickNidImage(ImageSource source, bool isFront) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _nidFrontImage = File(image.path);
          } else {
            _nidBackImage = File(image.path);
          }
        });
        print(
          'DEBUG: NID ${isFront ? 'front' : 'back'} image selected: ${image.path}',
        );
      }
    } catch (e) {
      print('DEBUG: Error picking NID image: $e');
      _showErrorMessage('Error picking image: $e');
    }
  }

  void _showImageSourceDialog(bool isFront) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _captureAndValidateImage(isFront);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.green),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndValidateImage(isFront);
                },
              ),
            ],
          ),
        );
      },
    );
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
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildBottomNavigation(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Text(widget.tenant != null ? 'Edit Tenant' : 'Add New Tenant'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/properties');
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
        // Removed Personal Information section title
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
          isRequired: false,
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

        SizedBox(height: 20),

        // NID Front Side
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NID Front Side',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _nidFrontImage != null
                      ? Colors.green
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: _nidFrontImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _nidFrontImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _nidFrontImage = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _existingNidFrontUrl != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _existingNidFrontUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _existingNidFrontUrl = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: () => _showImageSourceDialog(true),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add NID front side',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Camera or Gallery',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (_nidFrontImage != null || _existingNidFrontUrl != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    _nidFrontImage != null
                        ? 'Front side selected'
                        : 'Front side exists',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => _showImageSourceDialog(true),
                    child: Text(
                      'Change',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),

        SizedBox(height: 20),

        // NID Back Side
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NID Back Side',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _nidBackImage != null
                      ? Colors.green
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: _nidBackImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _nidBackImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _nidBackImage = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _existingNidBackUrl != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _existingNidBackUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _existingNidBackUrl = null;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: () => _showImageSourceDialog(false),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add NID back side',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Camera or Gallery',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (_nidBackImage != null || _existingNidBackUrl != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    _nidBackImage != null
                        ? 'Back side selected'
                        : 'Back side exists',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => _showImageSourceDialog(false),
                    child: Text(
                      'Change',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
          isRequired: false,
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
            isRequired: false,
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
            isRequired: false,
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
            isRequired: false,
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
          isRequired: false,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          onChanged: (value) => setState(() {}),
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
          onChanged: (value) => setState(() {}),
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _cityController,
          label: 'City',
          hint: 'Enter your city',
          icon: Icons.location_city_outlined,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          onChanged: (value) => setState(() {}),
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _stateController,
          label: 'State/Division',
          hint: 'Enter your state or division',
          icon: Icons.map_outlined,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          onChanged: (value) => setState(() {}),
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _zipController,
          label: 'ZIP/Postal Code',
          hint: 'Enter your ZIP or postal code',
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          onChanged: (value) => setState(() {}),
        ),

        SizedBox(height: 16),

        _buildTextField(
          controller: _countryController,
          label: 'Country',
          hint: 'Enter your country',
          icon: Icons.public_outlined,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          onChanged: (value) => setState(() {}),
        ),

        SizedBox(height: 32),

        _buildSectionTitle('Driver Information', Icons.directions_car),
        SizedBox(height: 20),

        _buildBooleanField(
          label: 'Do you have a driver?',
          hint: 'Select if you have a driver',
          icon: Icons.person_pin_outlined,
          value: _isDriver,
          onChanged: (value) => _updateIsDriver(value),
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
            onChanged: (value) => setState(() {}),
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
          hint: widget.tenant != null
              ? 'Property (Read Only)'
              : 'Choose a property',
          icon: Icons.apartment_outlined,
          items: _properties
              .map((property) => property['name'] as String)
              .toList(),
          onChanged: widget.tenant != null
              ? (value) {} // Read-only in edit mode
              : (value) {
                  setState(() => _selectedPropertyId = value);
                  if (value != null) {
                    // Filter units for selected property
                    final selectedProperty = _properties.firstWhere(
                      (p) => p['name'] == value,
                    );

                    print(
                      'DEBUG: Selected property: ${selectedProperty['name']} (ID: ${selectedProperty['id']})',
                    );
                    print('DEBUG: _allUnits length: ${_allUnits.length}');
                    print(
                      'DEBUG: _allUnits property IDs: ${_allUnits.map((u) => u['property_id']).toSet()}',
                    );
                    print(
                      'DEBUG: _allUnits statuses: ${_allUnits.map((u) => u['status']).toSet()}',
                    );

                    // For new entry: filter by property AND status (vacant)
                    // For edit mode: filter by property only
                    final filteredUnits = _allUnits
                        .where(
                          (unit) =>
                              unit['property_id'] == selectedProperty['id'] &&
                              (widget.tenant != null ||
                                  unit['status'] == 'vacant'),
                        )
                        .toList();

                    print(
                      'DEBUG: Filtered ${filteredUnits.length} units for property $value',
                    );
                    print(
                      'DEBUG: Unit statuses: ${filteredUnits.map((u) => u['status']).toList()}',
                    );

                    setState(() {
                      _units = filteredUnits;
                      _selectedUnitId = null;
                    });
                  }
                },
          isLoading: _isLoadingProperties,
          isRequired: true,
          isReadOnly: widget.tenant != null,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedUnitId,
          label: 'Select Unit',
          hint: widget.tenant != null ? 'Unit (Read Only)' : 'Choose a unit',
          icon: Icons.door_front_door_outlined,
          items: _units.map((unit) => unit['name'] as String).toList(),
          onChanged: widget.tenant != null
              ? (value) {} // Read-only in edit mode
              : (value) {
                  setState(() => _selectedUnitId = value);
                  if (value != null) {
                    // Find the selected unit by name
                    final selectedUnit = _units.firstWhere(
                      (unit) => unit['name'] == value,
                    );

                    // Auto-fill fees based on unit charges
                    print('DEBUG: Selected unit: ${selectedUnit['name']}');
                    print(
                      'DEBUG: Unit rent: ${selectedUnit['rent']} (type: ${selectedUnit['rent'].runtimeType})',
                    );
                    print('DEBUG: Unit charges: ${selectedUnit['charges']}');

                    if (selectedUnit['charges'] != null) {
                      double totalFees = (selectedUnit['rent'] is double)
                          ? selectedUnit['rent']
                          : double.tryParse(selectedUnit['rent'].toString()) ??
                                0.0;

                      print('DEBUG: Initial total fees: $totalFees');

                      for (var charge in selectedUnit['charges']) {
                        print(
                          'DEBUG: Processing charge: ${charge['label']} = ${charge['amount']} (type: ${charge['amount'].runtimeType})',
                        );

                        double chargeAmount = (charge['amount'] is double)
                            ? charge['amount']
                            : double.tryParse(charge['amount'].toString()) ??
                                  0.0;

                        print('DEBUG: Parsed charge amount: $chargeAmount');
                        totalFees += chargeAmount;
                      }

                      print('DEBUG: Final total fees: $totalFees');
                      setState(() {
                        _feesController.text = totalFees.toStringAsFixed(2);
                      });
                      print('DEBUG: Set fees to: ${_feesController.text}');
                    }
                  } else {
                    _advanceAmountController.clear();
                  }
                },
          isLoading: _isLoadingUnits,
          isRequired: true,
          isReadOnly: widget.tenant != null, // Read-only in edit mode
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

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unit Charges & Fees',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),

            // Charges List
            if (_selectedUnitId != null) ...[
              ..._buildChargesList(),
              SizedBox(height: 16),

              // Total Fees
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Fees',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      '৳${_feesController.text.isEmpty ? '0.00' : _feesController.text}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Select a unit to see charges and fees',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 16),

        _buildDropdownField(
          value: _selectedStartMonth,
          label: 'Start Month',
          hint: 'Select start month',
          icon: Icons.calendar_today_outlined,
          items: _generateMonthYearOptions(),
          onChanged: (value) => setState(() => _selectedStartMonth = value),
          isRequired: true,
          isReadOnly: false,
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
    Function(String)? onChanged,
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
    bool isReadOnly = false,
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
                : Icon(
                    icon,
                    color: isReadOnly ? Colors.grey[400] : Colors.grey[600],
                  ),
            floatingLabelBehavior: floatingLabelBehavior,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isReadOnly ? Colors.grey[400]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isReadOnly ? Colors.grey[400]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isReadOnly ? Colors.grey[400]! : Colors.blue[600]!,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isReadOnly ? Colors.grey[100] : Colors.grey[50],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: isReadOnly ? null : onChanged,
          validator: isRequired
              ? (value) => value?.isEmpty == true ? '$label is required' : null
              : null,
          menuMaxHeight: 300,
          isExpanded: true,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + (bottomInset > 0 ? 8 : 0)),
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

          // Right Side - Next/Submit/Skip Button
          SizedBox(width: 100, child: _buildSmartNextOrSkipButton()),
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
    print('DEBUG: _handleNextStep called');
    print('DEBUG: _currentStep: $_currentStep');
    print('DEBUG: _totalSteps: $_totalSteps');
    print('DEBUG: widget.tenant != null: ${widget.tenant != null}');

    if (_currentStep < _totalSteps - 1) {
      print('DEBUG: Moving to next step');
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      print('DEBUG: Calling _submitForm');
      _submitForm();
    }
  }

  bool _validateCurrentStep() {
    // Validate all steps properly for both create and edit modes
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty ||
          _genderController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _nidController.text.isEmpty) {
        _showErrorMessage('Please fill all required fields');
        return false;
      }
    } else if (_currentStep == 1) {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _submitForm() async {
    print('DEBUG: _submitForm called');
    print('DEBUG: widget.tenant != null: ${widget.tenant != null}');

    if (!_validateCurrentStep()) {
      print('DEBUG: Validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build tenant data using helper method
      final tenantData = _buildTenantData();
      print('DEBUG: Built tenant data: $tenantData');

      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Prepare API request
      final isEditMode = widget.tenant != null;
      final url = isEditMode
          ? ApiConfig.getApiUrl('/tenants/${widget.tenant!['id']}')
          : ApiConfig.getApiUrl('/tenants');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add _method field for Laravel to treat as PUT in edit mode
      if (isEditMode) {
        request.fields['_method'] = 'PUT';
      }

      // Add all form fields from tenantData
      tenantData.forEach((key, value) {
        request.fields[key] = value?.toString() ?? '';
        print('DEBUG: Added field $key = ${value?.toString() ?? 'empty'}');
      });

      // Add NID images with error handling
      await _addNidImagesToRequest(request);

      print('DEBUG: Sending request to: $url');
      print('DEBUG: Request method: ${request.method}');
      print('DEBUG: Request fields count: ${request.fields.length}');
      print('DEBUG: Request files count: ${request.files.length}');

      final response = await request.send().timeout(Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: $responseBody');

      await _handleApiResponse(response, responseBody, isEditMode);
    } catch (e) {
      print('DEBUG: Error in _submitForm: $e');
      _showErrorMessage('Error saving tenant: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNidImagesToRequest(http.MultipartRequest request) async {
    // Add NID front image if selected
    if (_nidFrontImage != null) {
      try {
        final stream = http.ByteStream(_nidFrontImage!.openRead());
        final length = await _nidFrontImage!.length();
        final multipartFile = http.MultipartFile(
          'nid_front_picture',
          stream,
          length,
          filename: 'nid_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
        print('DEBUG: NID front image added to request');
      } catch (e) {
        print('DEBUG: Error adding NID front image to request: $e');
        _showErrorMessage('Error uploading NID front image: $e');
      }
    }

    // Add NID back image if selected
    if (_nidBackImage != null) {
      try {
        final stream = http.ByteStream(_nidBackImage!.openRead());
        final length = await _nidBackImage!.length();
        final multipartFile = http.MultipartFile(
          'nid_back_picture',
          stream,
          length,
          filename: 'nid_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
        print('DEBUG: NID back image added to request');
      } catch (e) {
        print('DEBUG: Error adding NID back image to request: $e');
        _showErrorMessage('Error uploading NID back image: $e');
      }
    }
  }

  Future<void> _handleApiResponse(
    http.StreamedResponse response,
    String responseBody,
    bool isEditMode,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(responseBody);

        if (data['success'] == true) {
          // Show success message
          _showSuccessMessage(
            isEditMode
                ? 'Tenant updated successfully!'
                : 'Tenant added successfully!',
          );

          // Wait a bit for user to see the message
          await Future.delayed(Duration(milliseconds: 500));

          // Navigate back to tenant list with refresh flag
          if (context.canPop()) {
            context.pop(true); // Pass true to indicate successful save
          } else {
            context.go('/properties');
          }
        } else {
          _showErrorMessage(data['message'] ?? 'Failed to save tenant');
        }
      } catch (e) {
        _showErrorMessage('Error parsing response: $e');
      }
    } else {
      print('DEBUG: Error response: $responseBody');
      try {
        final data = json.decode(responseBody);
        final details = data['details'] as Map<String, dynamic>?;
        if (details != null && details.isNotEmpty) {
          final firstKey = details.keys.first;
          final firstMsg = (details[firstKey] as List).first.toString();
          _showErrorMessage(firstMsg);
        } else if (data['error'] != null) {
          _showErrorMessage(data['error'].toString());
        } else {
          _showErrorMessage(
            'Failed to save tenant. Status: ${response.statusCode}',
          );
        }
      } catch (_) {
        _showErrorMessage(
          'Failed to save tenant. Status: ${response.statusCode}',
        );
      }
    }
  }

  // Helper method to build tenant data from form inputs
  Map<String, dynamic> _buildTenantData() {
    // Parse name into first_name and last_name
    String fullName = _nameController.text.trim();
    List<String> nameParts = fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    return {
      'first_name': firstName.isNotEmpty ? firstName : 'Not Specified',
      'last_name': lastName.isNotEmpty ? lastName : null,
      'gender': _genderController.text.isNotEmpty
          ? _genderController.text
          : 'Not Specified',
      'mobile': _phoneController.text.isNotEmpty
          ? _phoneController.text
          : 'Not Specified',
      'alt_mobile': _altPhoneController.text.isNotEmpty
          ? _altPhoneController.text
          : null,
      'email': _emailController.text.isNotEmpty ? _emailController.text : null,
      'nid_number': _nidController.text.isNotEmpty ? _nidController.text : null,
      'address': _streetAddressController.text.isNotEmpty
          ? _streetAddressController.text
          : 'Not Specified',
      'city': _cityController.text.isNotEmpty
          ? _cityController.text
          : 'Not Specified',
      'state': _stateController.text.isNotEmpty
          ? _stateController.text
          : 'Not Specified',
      'zip': _zipController.text.isNotEmpty
          ? _zipController.text
          : 'Not Specified',
      'country': _countryController.text.isNotEmpty
          ? _countryController.text
          : 'Bangladesh',
      'occupation': _occupationController.text.isNotEmpty
          ? _occupationController.text
          : 'Not Specified',
      'company_name': _companyName.isNotEmpty ? _companyName : null,
      'college_university': _collegeUniversity.isNotEmpty
          ? _collegeUniversity
          : null,
      'business_name': _businessName.isNotEmpty ? _businessName : null,
      'is_driver': _isDriver,
      'driver_name': _driverNameController.text.isNotEmpty
          ? _driverNameController.text
          : null,
      'family_types': _familyTypes.isNotEmpty
          ? _familyTypes.join(',')
          : 'Not Specified',
      'child_qty': _childQty,
      'total_family_member': int.tryParse(_familyMemberController.text) ?? 1,
      'building_id': _getPropertyIdByName(_selectedPropertyId) ?? '1',
      'property_id': _getPropertyIdByName(_selectedPropertyId) ?? '1',
      'unit_id': _getUnitIdByName(_selectedUnitId) ?? '1',
      'security_deposit': _advanceAmountController.text.isNotEmpty
          ? double.tryParse(_advanceAmountController.text) ?? 7000
          : 7000,
      'advance_amount': _advanceAmountController.text.isNotEmpty
          ? double.tryParse(_advanceAmountController.text) ?? 0
          : 0,
      'start_month': _convertMonthYearToDate(_selectedStartMonth),
      'check_in_date': _selectedStartMonth != null
          ? _convertMonthYearToDateToFirstDay(_selectedStartMonth)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'frequency': _selectedFrequency ?? '',
      'remarks': _remarksController.text.isNotEmpty
          ? _remarksController.text
          : null,
    };
  }

  // Image validation and handling methods
  static const int _maxImageSizeInMB = 2;
  static const int _maxImageSizeInBytes = _maxImageSizeInMB * 1024 * 1024;

  Future<bool> _validateImage(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      if (fileSize > _maxImageSizeInBytes) {
        _showErrorMessage('Image size must be less than $_maxImageSizeInMB MB');
        return false;
      }
      return true;
    } catch (e) {
      _showErrorMessage('Error validating image: $e');
      return false;
    }
  }

  Future<void> _pickAndValidateImage(bool isFront) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        if (await _validateImage(imageFile)) {
          setState(() {
            if (isFront) {
              _nidFrontImage = imageFile;
            } else {
              _nidBackImage = imageFile;
            }
          });
        }
      }
    } catch (e) {
      _showErrorMessage('Error picking image: $e');
    }
  }

  Future<void> _captureAndValidateImage(bool isFront) async {
    try {
      final XFile? capturedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (capturedFile != null) {
        final File imageFile = File(capturedFile.path);

        if (await _validateImage(imageFile)) {
          setState(() {
            if (isFront) {
              _nidFrontImage = imageFile;
            } else {
              _nidBackImage = imageFile;
            }
          });
        }
      }
    } catch (e) {
      _showErrorMessage('Error capturing image: $e');
    }
  }

  String _convertMonthYearToDateToFirstDay(String? monthYear) {
    print('DEBUG: _convertMonthYearToDateToFirstDay called with: $monthYear');
    // monthYear: "07-2025" or "July-25"
    if (monthYear == null || monthYear.isEmpty) {
      print('DEBUG: monthYear is null or empty, returning empty string');
      return '';
    }
    // If format is "07-2025"
    if (RegExp(r'^\d{2}-\d{4}').hasMatch(monthYear)) {
      print('DEBUG: Matched MM-YYYY format');
      final parts = monthYear.split('-');
      final month = parts[0];
      final year = parts[1];
      final result = '$year-$month-01';
      print('DEBUG: Converted to: $result');
      return result;
    }
    // If format is "July-25"
    try {
      print('DEBUG: Trying MMMM-YY format');
      final parts = monthYear.split('-');
      final monthName = parts[0];
      final yearShort = parts[1];
      final month = DateFormat(
        'MMMM',
      ).parse(monthName).month.toString().padLeft(2, '0');
      final year =
          '20${yearShort.length == 2 ? yearShort : yearShort.substring(yearShort.length - 2)}';
      final result = '$year-$month-01';
      print('DEBUG: Converted to: $result');
      return result;
    } catch (e) {
      print('DEBUG: Error in conversion: $e');
      return '';
    }
  }

  // State management helper methods
  void _updateState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  void _updateCompanyName(String value) {
    _updateState(() {
      _companyName = value;
    });
  }

  void _updateCollegeUniversity(String value) {
    _updateState(() {
      _collegeUniversity = value;
    });
  }

  void _updateBusinessName(String value) {
    _updateState(() {
      _businessName = value;
    });
  }

  void _updateIsDriver(bool value) {
    _updateState(() {
      _isDriver = value;
    });
  }

  void _updateChildQty(int value) {
    _updateState(() {
      _childQty = value;
    });
  }

  void _updateFamilyTypes(List<String> types) {
    _updateState(() {
      _familyTypes = types;
    });
  }

  void _updateSelectedProperty(String? propertyId) {
    _updateState(() {
      _selectedPropertyId = propertyId;
      // Clear unit selection when property changes
      _selectedUnitId = null;
    });
    if (propertyId != null) {
      _loadUnitsByProperty(propertyId);
    }
  }

  void _updateSelectedUnit(String? unitId) {
    _updateState(() {
      _selectedUnitId = unitId;
    });
    _calculateFeesForSelectedUnit();
  }

  void _updateSelectedStartMonth(String? month) {
    _updateState(() {
      _selectedStartMonth = month;
    });
  }

  void _updateSelectedFrequency(String? frequency) {
    _updateState(() {
      _selectedFrequency = frequency;
    });
  }

  Future<void> _loadUnitsByProperty(String? propertyId) async {
    if (propertyId == null) return;

    _updateState(() {
      _isLoadingUnits = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = ApiConfig.getApiUrl('/properties/$propertyId/units');
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _updateState(() {
          _units = List<Map<String, dynamic>>.from(data['units'] ?? []);
          _isLoadingUnits = false;
        });
      } else {
        throw Exception('Failed to load units');
      }
    } catch (e) {
      print('DEBUG: Error loading units: $e');
      _updateState(() {
        _isLoadingUnits = false;
      });
      _showErrorMessage('Error loading units: $e');
    }
  }

  Widget _buildSmartNextOrSkipButton() {
    // Only for step 1 and 2 (index 1 and 2)
    if (_currentStep == 1) {
      // Step 2: Work & Family
      // Exclude default value: _familyMemberController.text = '1'
      bool isEmpty =
          _occupationController.text.isEmpty &&
          _companyName.isEmpty &&
          _collegeUniversity.isEmpty &&
          _businessName.isEmpty &&
          (_familyMemberController.text.isEmpty ||
              _familyMemberController.text == '1') &&
          (_familyTypes.isEmpty ||
              (_familyTypes.contains('Child') && _childQty == 0));

      return TextButton(
        onPressed: _isLoading
            ? null
            : () {
                if (isEmpty) {
                  // Skip validation, go next
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  // Validate as Next
                  if (_validateCurrentStep()) {
                    setState(() {
                      _currentStep++;
                    });
                  }
                }
              },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: Colors.blue[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    isEmpty ? 'Skip' : 'Next',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                ],
              ),
      );
    } else if (_currentStep == 2) {
      // Step 3: Address & Driver
      // Exclude default value: _countryController.text = 'Bangladesh'
      bool isEmpty =
          _streetAddressController.text.isEmpty &&
          _cityController.text.isEmpty &&
          _stateController.text.isEmpty &&
          _zipController.text.isEmpty &&
          !_isDriver &&
          _driverNameController.text.isEmpty;

      return TextButton(
        onPressed: _isLoading
            ? null
            : () {
                if (isEmpty) {
                  // Skip validation, go next
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  // Validate as Next
                  if (_validateCurrentStep()) {
                    setState(() {
                      _currentStep++;
                    });
                  }
                }
              },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: Colors.blue[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    isEmpty ? 'Skip' : 'Next',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                ],
              ),
      );
    } else {
      // Default: use existing Next/Submit logic
      return TextButton(
        onPressed: _isLoading ? null : _handleNextStep,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: Colors.blue[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    _currentStep == _totalSteps - 1
                        ? (widget.tenant != null ? 'Update' : 'Submit')
                        : 'Next',
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
      );
    }
  }

  Future<void> _loadVacantUnitsForProperty(String propertyName) async {
    setState(() {
      _isLoadingUnits = true;
      _units = [];
      _selectedUnitId = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Find property ID by name
      final selectedProperty = _properties.firstWhere(
        (p) => p['name'] == propertyName,
      );
      final propertyId = selectedProperty['id'];

      // Fetch only vacant units for this property
      final url = ApiConfig.getApiUrl(
        '/units?property_id=$propertyId&status=Vacant',
      );
      print('DEBUG: Loading vacant units from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 10));

      print('DEBUG: Vacant units response status: ${response.statusCode}');
      print('DEBUG: Vacant units response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed vacant units data: $data');

        List<Map<String, dynamic>> units = [];
        if (data['units'] != null) {
          units = List<Map<String, dynamic>>.from(data['units']);
        } else if (data['data'] != null) {
          units = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          units = List<Map<String, dynamic>>.from(data);
        }

        print(
          'DEBUG: Loaded ${units.length} vacant units for property $propertyName',
        );

        setState(() {
          _units = units;
        });
      } else {
        throw Exception('Failed to load vacant units: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading vacant units: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vacant units: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUnits = false;
        });
      }
    }
  }
}
