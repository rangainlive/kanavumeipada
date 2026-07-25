import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) return;
    final notifier = ref.read(authProvider.notifier);
    if (_isSignUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;
      await notifier.register(phone, password, name);
    } else {
      await notifier.login(phone, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        if (next.user?.isProfileComplete == true) {
          context.go('/feed');
        } else {
          context.go('/auth/profile');
        }
      }
      if (next.error != null && (prev?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 28),
                // Emerald logo badge
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: AppTheme.brandGradient,
                    boxShadow: AppTheme.glow(),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'KanavuMeipada',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Prepare Smart · Compete Fair · Win Big',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // White form card
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab switcher
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(children: [
                          _tab('Sign In', !_isSignUp),
                          _tab('Sign Up', _isSignUp),
                        ]),
                      ),
                      const SizedBox(height: 22),

                      if (_isSignUp) ...[
                        _label('Full Name'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _nameController,
                          hint: 'Your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                      ],

                      _label('Phone Number'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _phoneController,
                        hint: '10-digit mobile number',
                        icon: Icons.phone_outlined,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      _label('Password'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _passwordController,
                        hint: _isSignUp ? 'Min. 6 characters' : 'Your password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textHint,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 24),

                      GradientButton(
                        label: _isSignUp ? 'Create Account' : 'Sign In',
                        onPressed: authState.isLoading ? null : _submit,
                        isLoading: authState.isLoading,
                        icon: _isSignUp
                            ? Icons.rocket_launch_rounded
                            : Icons.login_rounded,
                      ),

                      const SizedBox(height: 18),
                      Row(children: [
                        const Expanded(child: Divider(color: AppTheme.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                        ),
                        const Expanded(child: Divider(color: AppTheme.border)),
                      ]),
                      const SizedBox(height: 14),

                      // Google button
                      OutlinedButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => ref.read(authProvider.notifier).loginWithGoogle(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.g_mobiledata, size: 24, color: Color(0xFFEA4335)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Continue with Google',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  'By continuing you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isSignUp = label == 'Sign Up'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppTheme.primaryDim : AppTheme.textHint,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}
