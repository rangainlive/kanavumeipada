import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class _ExamOption {
  final String key;
  final String label;
  final String emoji;
  final bool comingSoon;
  const _ExamOption(this.key, this.label, this.emoji, {this.comingSoon = false});
}

// Only TNPSC is available today; the rest are shown but disabled ("Soon").
const _exams = [
  _ExamOption('TNPSC', 'TNPSC', '🌴'),
  _ExamOption('UPSC', 'UPSC', '🏛️', comingSoon: true),
  _ExamOption('SSC', 'SSC', '⚖️', comingSoon: true),
  _ExamOption('Banking', 'Banking', '🏦', comingSoon: true),
  _ExamOption('NEET', 'NEET', '🩺', comingSoon: true),
  _ExamOption('JEE', 'JEE', '🔬', comingSoon: true),
];

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  // Single-select; TNPSC pre-selected since it's the only available exam.
  String _selectedExam = 'TNPSC';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user?.name != null) _nameController.text = user!.name!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter your name');
      return;
    }
    ref.read(authProvider.notifier).updateProfile(
          name: name,
          examTarget: _selectedExam,
        );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.user?.isProfileComplete == true &&
          !(prev?.user?.isProfileComplete ?? false)) {
        context.go('/feed');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Gradient hero header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 210,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradientDeep,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome! 👋',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set Up Your Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Personalize your exam prep journey',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable content
          Positioned.fill(
            top: 165,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name card
                  AppCard(
                    glow: true,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Exam selection card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Your Exam',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'More exams are on the way — TNPSC is available now',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textHint),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _exams.map((exam) {
                            return _ExamChip(
                              exam: exam,
                              isSelected: _selectedExam == exam.key,
                              onTap: exam.comingSoon
                                  ? () => _showSnack('${exam.label} is coming soon')
                                  : () => setState(() => _selectedExam = exam.key),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Region info
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryGlow, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Currently supporting Tamil Nadu region. More states coming soon!',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.primaryGlow.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (authState.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(authState.error!, style: const TextStyle(color: AppTheme.error)),
                    ),

                  GradientButton(
                    label: 'Start My Journey',
                    onPressed: authState.isLoading ? null : _save,
                    isLoading: authState.isLoading,
                    icon: Icons.rocket_launch_rounded,
                  ),

                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'You can update this later in your profile',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamChip extends StatelessWidget {
  final _ExamOption exam;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExamChip({
    required this.exam,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final soon = exam.comingSoon;
    final Color fill = isSelected
        ? AppTheme.primary
        : (soon ? AppTheme.surface2 : AppTheme.primary.withValues(alpha: 0.1));
    final Color borderCol = isSelected
        ? AppTheme.primary
        : (soon ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.35));
    final Color labelCol = isSelected
        ? const Color(0xFF04120F)
        : (soon ? AppTheme.textHint : AppTheme.primaryGlow);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: soon ? 0.6 : 1,
              child: Text(exam.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 6),
            Text(
              exam.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: labelCol,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: Color(0xFF04120F), size: 14),
            ],
            if (soon) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
