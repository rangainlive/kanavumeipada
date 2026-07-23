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
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.surface2),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AuroraBackground(
        dense: true,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Glowing glass logo badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: AppTheme.brandGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.55),
                          blurRadius: 34,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_stories_rounded,
                        color: Color(0xFF04120F), size: 38),
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
                  Text(
                    'Prepare Smart · Compete Fair · Win Big',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Glass form panel
                  GlassPanel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tab switcher
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                          Expanded(
                              child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                          ),
                          Expanded(
                              child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                        ]),
                        const SizedBox(height: 14),

                        // Google button
                        Material(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: authState.isLoading
                                ? null
                                : () => ref.read(authProvider.notifier).loginWithGoogle(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                  ),
                ],
              ),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active ? AppTheme.brandGradient : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
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
              color: active ? const Color(0xFF04120F) : AppTheme.textSecondary,
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
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryGlow, width: 1.5),
        ),
      ),
    );
  }
}
