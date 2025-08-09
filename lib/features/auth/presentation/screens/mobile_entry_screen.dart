import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hrms_app/core/utils/app_colors.dart';
import 'package:hrms_app/core/services/api_service.dart';

class MobileEntryScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? initialName;
  const MobileEntryScreen({super.key, this.initialEmail, this.initialName});

  @override
  ConsumerState<MobileEntryScreen> createState() => _MobileEntryScreenState();
}

class _MobileEntryScreenState extends ConsumerState<MobileEntryScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String? _normalizeBdMobile(String input) {
    String msisdn = _digitsOnly(input);
    if (msisdn.startsWith('0088')) {
      msisdn = msisdn.substring(4);
    } else if (msisdn.startsWith('88')) {
      msisdn = msisdn.substring(2);
    }
    if (msisdn.length == 10 && msisdn.startsWith('1')) {
      msisdn = '0$msisdn';
    }
    if (msisdn.length != 11 || !msisdn.startsWith('01')) {
      return null;
    }
    return msisdn;
  }

  bool _isValidBdMobile(String input) {
    return _normalizeBdMobile(input) != null;
  }

  Future<void> _onSubmit() async {
    final raw = _mobileController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final normalized = _normalizeBdMobile(raw);
    if (normalized == null) {
      setState(() {
        _mobileError =
            'Please enter a valid Bangladeshi number (11 digits starting with 01). +88 will be removed automatically';
      });
      return;
    }
    _mobileController.text = normalized;

    setState(() => _isLoading = true);
    try {
      // 1) Check in DB by mobile
      final api = ref.read(apiServiceProvider);
      final response = await api.post(
        '/check-mobile-role',
        data: {'mobile': normalized},
      );
      final data = response.data as Map<String, dynamic>;
      final role = data['role'];
      final userData = data['user_data'] as Map<String, dynamic>?;
      final existingEmail =
          (userData != null ? (userData['email'] as String?) : null)?.trim();

      if (role != null) {
        // User exists
        final googleEmail = widget.initialEmail?.trim() ?? '';
        final hasEmailInDb = existingEmail != null && existingEmail.isNotEmpty;

        if (hasEmailInDb || googleEmail.isEmpty) {
          // Already has email OR no google email to update → go to login directly
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account exists. Redirecting to login...'),
                backgroundColor: Colors.green,
              ),
            );
            context.push('/login');
          }
        } else {
          // No email in DB, but we have google email → offer update
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Account Found'),
              content: Text(
                'আপনি আগেই রেজিস্টার করেছেন। আপনি কি আপনার একাউন্টে Google ইমেইল ($googleEmail) আপডেট করতে চান?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await api.post(
                        '/link-google-email',
                        data: {'mobile': normalized, 'email': googleEmail},
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Email updated successfully. Please login.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        context.push('/login');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email update failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        context.push('/login');
                      }
                    }
                  },
                  child: const Text('Update Email'),
                ),
              ],
            ),
          );
        }
      } else {
        // Not found → proceed to owner registration with prefilled params
        final params = <String>[];
        params.add('mobile=${Uri.encodeComponent(normalized)}');
        if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
          params.add('email=${Uri.encodeComponent(widget.initialEmail!)}');
        }
        if (widget.initialName != null && widget.initialName!.isNotEmpty) {
          params.add('name=${Uri.encodeComponent(widget.initialName!)}');
        }
        final url = '/owner-registration?${params.join('&')}';
        if (mounted) context.push(url);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Mobile Number')),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Please provide your mobile number to continue registration',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile number',
                hintText: '01XXXXXXXXX',
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _mobileError,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
