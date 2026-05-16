import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/core/constants/api_constants.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _role = RoleOptions.student;

  // Academic
  final _studentIdCtrl = TextEditingController();
  String? _faculty;
  String? _programme;
  int _yearLevel = 1;
  int _semester = 1;

  // Security
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _pwVisible = false;
  bool _confirmVisible = false;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadFaculties();
    });
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_faculty == null) {
      setState(() => _error = 'Please select your faculty');
      return;
    }
    if (_programme == null) {
      setState(() => _error = 'Please select your degree programme');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.register(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        passwordConfirmation: _confirmCtrl.text,
        faculty: _faculty!,
        yearLevel: _yearLevel,
        semester: _semester,
        degreeProgramme: _programme!,
        role: _role,
        studentId: _studentIdCtrl.text.trim().isEmpty
            ? null
            : _studentIdCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/verify-email');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSub = isDark ? Colors.white60 : AppColors.textSecondary;
    final iconColor =
        isDark ? Colors.white38 : AppColors.textTertiary;
    final sectionBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final sectionBorder =
        isDark ? Colors.white10 : const Color(0xFFE8EDF2);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration:
                const BoxDecoration(gradient: AppColors.splashGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const AppLogoBadge(size: 42),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ReelScholar',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Create your account',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable form ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join thousands of scholars',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in your details to get started',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error banner
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AuthErrorBanner(message: _error!),
                      ),

                    // ── Section: Personal Info ───────────────────────────
                    _SectionCard(
                      label: 'Personal Info',
                      isDark: isDark,
                      bg: sectionBg,
                      border: sectionBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FieldLabel('Full Name', required: true),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: authInputTextStyle(isDark),
                            decoration: authInputDecoration(
                              isDark: isDark,
                              hintText: 'Tendai Moyo',
                              prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: iconColor),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter your full name'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          FieldLabel('Email Address', required: true),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: authInputTextStyle(isDark),
                            decoration: authInputDecoration(
                              isDark: isDark,
                              hintText: 'student@university.edu',
                              prefixIcon: Icon(Icons.email_outlined,
                                  size: 20, color: iconColor),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your email';
                              }
                              if (!RegExp(
                                r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
                              ).hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          FieldLabel('I am a…', required: true),
                          Row(
                            children: [
                              _RoleCard(
                                icon: Icons.school_rounded,
                                label: 'Student',
                                selected: _role == RoleOptions.student,
                                isDark: isDark,
                                onTap: () => setState(
                                    () => _role = RoleOptions.student),
                              ),
                              const SizedBox(width: 12),
                              _RoleCard(
                                icon: Icons.cast_for_education_rounded,
                                label: 'Lecturer',
                                selected: _role == RoleOptions.lecturer,
                                isDark: isDark,
                                onTap: () => setState(
                                    () => _role = RoleOptions.lecturer),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Section: Academic Details ─────────────────────────
                    _SectionCard(
                      label: 'Academic Details',
                      isDark: isDark,
                      bg: sectionBg,
                      border: sectionBorder,
                      child: Consumer<AuthProvider>(
                        builder: (_, auth, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FieldLabel('Faculty', required: true),
                            DropdownButtonFormField<String>(
                              key: ValueKey(_faculty),
                              initialValue: _faculty,
                              isExpanded: true,
                              dropdownColor: sectionBg,
                              style: authInputTextStyle(isDark),
                              decoration: authInputDecoration(
                                isDark: isDark,
                                hintText: 'Select your faculty',
                                prefixIcon: Icon(Icons.business_outlined,
                                    size: 20, color: iconColor),
                              ),
                              items: auth.faculties
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontFamily: 'DM Sans',
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: auth.isLoadingMetadata
                                  ? null
                                  : (f) {
                                      setState(() {
                                        _faculty = f;
                                        _programme = null;
                                      });
                                      if (f != null) {
                                        context
                                            .read<AuthProvider>()
                                            .loadProgrammes(f);
                                      }
                                    },
                              validator: (v) =>
                                  v == null ? 'Select your faculty' : null,
                            ),
                            const SizedBox(height: 14),
                            FieldLabel('Degree Programme', required: true),
                            DropdownButtonFormField<String>(
                              key: ValueKey('prog_$_faculty'),
                              initialValue: _programme,
                              isExpanded: true,
                              dropdownColor: sectionBg,
                              style: authInputTextStyle(isDark),
                              decoration: authInputDecoration(
                                isDark: isDark,
                                hintText: auth.isLoadingMetadata
                                    ? 'Loading…'
                                    : _faculty == null
                                        ? 'Select faculty first'
                                        : 'Select your programme',
                                prefixIcon: Icon(
                                    Icons.history_edu_outlined,
                                    size: 20,
                                    color: iconColor),
                              ),
                              items: auth.programmes
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontFamily: 'DM Sans',
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (auth.isLoadingMetadata ||
                                      _faculty == null)
                                  ? null
                                  : (p) =>
                                      setState(() => _programme = p),
                              validator: (v) => v == null
                                  ? 'Select your degree programme'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            // Year + Semester side by side
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FieldLabel('Year Level',
                                          required: true),
                                      DropdownButtonFormField<int>(
                                        initialValue: _yearLevel,
                                        dropdownColor: sectionBg,
                                        style: authInputTextStyle(isDark),
                                        decoration: authInputDecoration(
                                          isDark: isDark,
                                          hintText: '',
                                          prefixIcon: Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                              color: iconColor),
                                        ),
                                        items: YearLevelOptions.yearLevels
                                            .map((y) => DropdownMenuItem(
                                                  value: y,
                                                  child: Text('Year $y',
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          fontFamily:
                                                              'DM Sans',
                                                          color: isDark
                                                              ? Colors.white
                                                              : AppColors
                                                                  .textPrimary)),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(
                                                () => _yearLevel = v);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      FieldLabel('Semester', required: true),
                                      DropdownButtonFormField<int>(
                                        initialValue: _semester,
                                        dropdownColor: sectionBg,
                                        style: authInputTextStyle(isDark),
                                        decoration: authInputDecoration(
                                          isDark: isDark,
                                          hintText: '',
                                          prefixIcon: Icon(
                                              Icons.timer_outlined,
                                              size: 18,
                                              color: iconColor),
                                        ),
                                        items: SemesterOptions.semesters
                                            .map((s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text('Sem $s',
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          fontFamily:
                                                              'DM Sans',
                                                          color: isDark
                                                              ? Colors.white
                                                              : AppColors
                                                                  .textPrimary)),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(
                                                () => _semester = v);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FieldLabel('Student ID (optional)'),
                            TextFormField(
                              controller: _studentIdCtrl,
                              style: authInputTextStyle(isDark),
                              decoration: authInputDecoration(
                                isDark: isDark,
                                hintText: 'C22123456X',
                                prefixIcon: Icon(Icons.badge_outlined,
                                    size: 20, color: iconColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Section: Security ────────────────────────────────
                    _SectionCard(
                      label: 'Security',
                      isDark: isDark,
                      bg: sectionBg,
                      border: sectionBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FieldLabel('Password', required: true),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: !_pwVisible,
                            style: authInputTextStyle(isDark),
                            decoration: authInputDecoration(
                              isDark: isDark,
                              hintText: 'At least 8 characters',
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  size: 20, color: iconColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _pwVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: iconColor,
                                ),
                                onPressed: () =>
                                    setState(() => _pwVisible = !_pwVisible),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter a password';
                              }
                              if (v.length < 8) {
                                return 'At least 8 characters required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          FieldLabel('Confirm Password', required: true),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: !_confirmVisible,
                            style: authInputTextStyle(isDark),
                            decoration: authInputDecoration(
                              isDark: isDark,
                              hintText: 'Repeat your password',
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  size: 20, color: iconColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: iconColor,
                                ),
                                onPressed: () => setState(
                                    () => _confirmVisible = !_confirmVisible),
                              ),
                            ),
                            validator: (v) => v != _passwordCtrl.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          // Password strength hint
                          _PasswordHint(
                            label: 'At least 8 characters',
                            met: _passwordCtrl.text.length >= 8,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Create Account button ────────────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: PrimaryButtonChild(
                          label: 'Create Account',
                          isLoading: _isLoading,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Sign in link ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            color: textSub,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/login'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isDark;
  final Color bg;
  final Color border;

  const _SectionCard({
    required this.label,
    required this.child,
    required this.isDark,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                  bottom: BorderSide(color: border)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Role picker card ──────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final unselectedBorder =
        isDark ? Colors.white12 : AppColors.border;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySubtle
                : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : unselectedBorder,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 26,
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white38 : AppColors.textTertiary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white60
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Password hint row ─────────────────────────────────────────────────────────

class _PasswordHint extends StatelessWidget {
  final String label;
  final bool met;
  final bool isDark;
  const _PasswordHint(
      {required this.label, required this.met, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final unmetColor =
        isDark ? Colors.white38 : AppColors.textTertiary;
    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: met ? AppColors.success : unmetColor,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: met ? AppColors.success : unmetColor,
          ),
        ),
      ],
    );
  }
}
