import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/owner/presentation/widgets/custom_bottom_nav.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/utils/country_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PropertyEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? property;

  const PropertyEntryScreen({super.key, this.property});

  @override
  _PropertyEntryScreenState createState() => _PropertyEntryScreenState();
}

class _PropertyEntryScreenState extends State<PropertyEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPropertyType = 'Apartment';
  String _selectedCountry = 'Bangladesh';
  int _totalUnits = 1;
  bool _isLoading = false;
  List<String> _countries = [];

  @override
  void initState() {
    super.initState();
    print(
      'DEBUG: PropertyEntryScreen initState - property: ${widget.property}',
    );
    _loadCountries();
    if (widget.property != null) {
      _loadPropertyData();
    }
  }

  void _loadCountries() {
    _countries = CountryHelper.getCountries();
  }

  void _loadPropertyData() {
    final property = widget.property!;
    print('DEBUG: Loading property data: $property');

    _nameController.text = property['name'] ?? '';
    _addressController.text = property['address'] ?? '';
    _cityController.text = property['city'] ?? '';
    _stateController.text = property['state'] ?? '';
    _zipCodeController.text = property['zip_code'] ?? '';
    _descriptionController.text = property['description'] ?? '';
    _selectedPropertyType = property['property_type'] ?? 'Apartment';
    _selectedCountry = property['country'] ?? 'Bangladesh';
    _totalUnits = property['total_units'] ?? 1;

    print(
      'DEBUG: Loaded data - Name: ${_nameController.text}, Address: ${_addressController.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property != null ? 'Edit Property' : 'Add Property'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop(); // যদি পেছনে যাওয়ার পেইজ থাকে, তাহলে pop করো
            } else {
              context.go(
                '/properties',
              ); // যদি কোনো কারণে পেছনে যাওয়ার পেইজ না থাকে, তাহলে fallback হিসেবে properties পেইজে যাও
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Type Selection
              Text(
                'Property Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyType,
                    isExpanded: true,
                    items:
                        ['Apartment', 'House', 'Villa', 'Commercial', 'Office']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyType = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Property Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Property Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Property name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.location_city,
                    color: AppColors.primary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // State
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State/Province',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'State is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // ZIP Code
              TextFormField(
                controller: _zipCodeController,
                decoration: InputDecoration(
                  labelText: 'ZIP/Postal Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_drop, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ZIP code is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Country
              Text(
                'Country',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    items: _countries
                        .map(
                          (country) => DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Total Units
              Text(
                'Total Units: $_totalUnits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Slider(
                value: _totalUnits.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    _totalUnits = value.round();
                  });
                },
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: AppColors.primary),
                ),
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.property != null
                              ? 'Update Property'
                              : 'Add Property',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final propertyData = {
        'name': _nameController.text.trim(),
        'property_type': _selectedPropertyType,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip_code': _zipCodeController.text.trim(),
        'country': _selectedCountry,
        'total_units': _totalUnits,
        'description': _descriptionController.text.trim(),
      };

      final url = widget.property != null
          ? ApiConfig.getApiUrl('/properties/${widget.property!['id']}')
          : ApiConfig.getApiUrl('/properties');

      final method = widget.property != null ? 'PUT' : 'POST';
      final request = http.Request(method, Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
      request.body = json.encode(propertyData);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.property != null
                  ? 'Property updated successfully!'
                  : 'Property added successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/properties');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to save property');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
