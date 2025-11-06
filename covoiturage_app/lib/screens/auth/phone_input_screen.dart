import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
// import removed
import 'phone_verification_screen.dart';
import 'personal_info_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  final String role; // CONDUCTEUR or PASSAGER

  const PhoneInputScreen({super.key, required this.role});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  // Minimal country list (can be extended later)
  final List<Map<String, String>> _countries = const [
    {'code': '+216', 'name': 'Tunisia', 'flag': '🇹🇳'},
    {'code': '+213', 'name': 'Algeria', 'flag': '🇩🇿'},
    {'code': '+212', 'name': 'Morocco', 'flag': '🇲🇦'},
    {'code': '+33',  'name': 'France',  'flag': '🇫🇷'},
  ];
  String _selectedDialCode = '+216';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    // Combine dial code and local number for verification
    final fullPhone = "$_selectedDialCode ${_phoneController.text.trim()}";

    // Navigate directly to phone verification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerificationScreen(
          phoneNumber: fullPhone,
                    onVerificationSuccess: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalInfoScreen(
                            role: widget.role,
                            phoneNumber: fullPhone,
                          ),
                        ),
                      );
                    },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _showBackendUrlDialog,
          child: const Text('Your Phone Number'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your phone number',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We will send you a verification code by SMS.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Flexible(
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surface,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDialCode,
                        isDense: true,
                        items: _countries.map((c) {
                          final label = "${c['flag']}  ${c['code']}";
                          return DropdownMenuItem<String>(
                            value: c['code'],
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedDialCode = v ?? '+216'),
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: 'Ex: 20 123 456',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        final v = (value ?? '').replaceAll(' ', '').replaceAll('-', '');
                        if (v.isEmpty) return 'Phone number is required';
                        if (v.length < 6) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _next,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBackendUrlDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('api_base_override') ?? '';
    final controller = TextEditingController(text: current);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Backend URL (Override)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. http://192.168.43.120:8081/api',
              labelText: 'API Base URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  await prefs.remove('api_base_override');
                } else {
                  await prefs.setString('api_base_override', value);
                }
                ApiService.resetBaseUrl();
                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backend URL updated. Will re-detect on next request.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}


