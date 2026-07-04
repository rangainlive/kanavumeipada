import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    if (_isLogin) {
      await auth.login(_phoneController.text.trim(), _passwordController.text);
    } else {
      await auth.register(
        _phoneController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        if (next.user?.isProfileComplete == true) {
          context.go('/feed');
        } else {
          context.go('/auth/profile');
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.school_rounded, size: 72,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('KanavuMeipada',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
                Text('Compete. Learn. Win.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 40),

                // Tab toggle
                Row(children: [
                  _tab(context, 'Sign In', _isLogin,
                      () => setState(() => _isLogin = true)),
                  _tab(context, 'Sign Up', !_isLogin,
                      () => setState(() => _isLogin = false)),
                ]),
                const SizedBox(height: 28),

                // Name — sign up only
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Phone number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '9876543210'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your mobile number';
                    if (v.length < 10) return 'Enter a valid mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (!_isLogin && v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Error
                if (authState.error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(authState.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),

                const SizedBox(height: 16),

                // Submit
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isLogin ? 'Sign In' : 'Create Account',
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        Text('or', style: TextStyle(color: Colors.grey[600])),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ]),
                const SizedBox(height: 16),

                // Google Sign-In button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).loginWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata, size: 22, color: Colors.redAccent),
                    label: const Text('Continue with Google',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2))),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey)),
        ),
      ),
    );
  }
}
