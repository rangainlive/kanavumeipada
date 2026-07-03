import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _selectedExam;
  String? _selectedState;

  final List<String> examCategories = [
    'UPSC',
    'TNPSC',
    'SSC',
    'Banking (PO/Clerk)',
    'NEET',
    'JEE',
    'Other',
  ];

  final List<String> states = [
    'Tamil Nadu',
    'Andhra Pradesh',
    'Karnataka',
    'Telangana',
    'Maharashtra',
    'Delhi',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _completeProfile() {
    if (_nameController.text.isEmpty ||
        _selectedExam == null ||
        _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    ref.read(authProvider.notifier).updateProfile(
      name: _nameController.text,
      examTarget: _selectedExam!,
      state: _selectedState!,
      email: _emailController.text.isEmpty ? null : _emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate to feed if profile setup complete
    if (authState.user?.isProfileComplete ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/feed');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Tell us about yourself',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us personalize your learning experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Full Name *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email (optional)',
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Exam Target *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedExam,
              hint: const Text('Select exam category'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school),
              ),
              items: examCategories.map((exam) {
                return DropdownMenuItem(
                  value: exam,
                  child: Text(exam),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedExam = value);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'State *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedState,
              hint: const Text('Select your state'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on),
              ),
              items: states.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedState = value);
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: authState.isLoading ? null : _completeProfile,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  authState.error!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
