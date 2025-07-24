import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/features/owner/data/services/unit_service.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/owner/data/services/property_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';

class UnitEntryScreen extends StatefulWidget {
  final int? unitId;
  const UnitEntryScreen({super.key, this.unitId});

  @override
  _UnitEntryScreenState createState() => _UnitEntryScreenState();
}

class _UnitEntryScreenState extends State<UnitEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rentController = TextEditingController();
  List<Map<String, dynamic>> _charges = [];
  bool _isLoading = false;
  String? _selectedPropertyId;
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _availableCharges = [];
  List<String> _selectedChargeLabels = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadAvailableCharges();
    if (widget.unitId != null) {
      _loadUnitData(widget.unitId!);
    }
  }

  Future<void> _loadProperties() async {
    String? token = await AuthService.getToken();
    if (token == null) return;
    final properties = await PropertyService.getProperties();
    setState(() {
      _properties = properties;
    });
  }

  Future<void> _loadAvailableCharges() async {
    String? token = await AuthService.getToken();
    if (token == null) return;
    final charges = await UnitService.getCharges();
    setState(() {
      _availableCharges = charges;
    });
  }

  Future<void> _loadUnitData(int id) async {
    setState(() {
      _isLoading = true;
    });
    try {
      String? token = await AuthService.getToken();
      if (token == null) return;
      final unit = await UnitService.getUnitById(id);
      setState(() {
        _nameController.text = unit['name'] ?? '';
        _rentController.text = unit['rent']?.toString() ?? '';
        _charges = List<Map<String, dynamic>>.from(unit['charges'] ?? []);
        _selectedPropertyId = unit['property_id']?.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Optionally show error
    }
  }

  void _addCharge() {
    setState(() {
      _charges.add({'label': '', 'amount': ''});
    });
  }

  void _removeCharge(int index) {
    setState(() {
      _charges.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.unitId != null ? 'Edit Unit' : 'Add Unit',
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (context.canPop()) {
              context.pop(); // যদি পেছনে যাওয়ার পেইজ থাকে, তাহলে pop করো
            } else {
              context.go(
                '/units',
              ); // যদি কোনো কারণে পেছনে যাওয়ার পেইজ না থাকে, তাহলে fallback হিসেবে properties পেইজে যাও
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownSearch<String>(
                items: _properties.map((p) => p['name'] as String).toList(),
                selectedItem: _selectedPropertyId != null
                    ? _properties.firstWhere(
                        (p) => p['id'].toString() == _selectedPropertyId,
                        orElse: () => {},
                      )['name']
                    : null,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Property',
                    prefixIcon: Icon(Icons.home_work, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                popupProps: PopupProps.menu(showSearchBox: true),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = _properties
                        .firstWhere((p) => p['name'] == value)['id']
                        .toString();
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Property is required'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Unit Name',
                  prefixIcon: Icon(Icons.home, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Unit name is required'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Rent',
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Rent is required';
                  if (double.tryParse(value) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text('Charges', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              // Charges selection
              DropdownSearch<String>.multiSelection(
                items: _availableCharges
                    .map((c) => c['label'] as String)
                    .toList(),
                selectedItems: _selectedChargeLabels,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Select Charges',
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                popupProps: PopupPropsMultiSelection.menu(showSearchBox: true),
                onChanged: (selectedLabels) {
                  setState(() {
                    _selectedChargeLabels = selectedLabels;
                    // Update _charges to match selected
                    _charges = _availableCharges
                        .where((c) => selectedLabels.contains(c['label']))
                        .map(
                          (c) => {
                            'label': c['label'],
                            'amount': c['amount'].toString(),
                          },
                        )
                        .toList();
                  });
                },
                // Removed required validator for charges
                // validator: (value) => value == null || value.isEmpty ? 'At least one charge is required' : null,
              ),
              SizedBox(height: 12),
              // Custom charge add section (optional, keep previous _charges logic for custom charges)
              ..._charges.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> charge = entry.value;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: charge['label'],
                            decoration: InputDecoration(
                              labelText: 'Label',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) => _charges[idx]['label'] = val,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Label required'
                                : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: charge['amount'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) => _charges[idx]['amount'] = val,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Amount required';
                              if (double.tryParse(val) == null)
                                return 'Enter valid number';
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _removeCharge(idx),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                  ],
                );
              }).toList(),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCharge,
                  icon: Icon(Icons.add, color: AppColors.primary),
                  label: Text('Add Charge'),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _saveUnit,
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.unitId != null ? 'Update' : 'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      String? token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final unitData = {
        'name': _nameController.text.trim(),
        'rent': double.parse(_rentController.text.trim()),
        'charges': _charges,
        'property_id': _selectedPropertyId,
      };

      if (widget.unitId != null) {
        await UnitService.updateUnit(widget.unitId!, unitData);
      } else {
        await UnitService.addUnit(unitData);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unit saved successfully!')));
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rentController.dispose();
    super.dispose();
  }
}
