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
  final _pageCtrl = PageController();
  int _step = 0; // 0-based; shown as 1/3, 2/3, 3/3

  // ── Step 1 — Identity ────────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _role = RoleOptions.student; // 'student' | 'lecturer'

  // ── Step 2 — Academic ────────────────────────────────────────────────────
  final _step2Key = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  String? _faculty;
  String? _programme;
  int _yearLevel = 1;
  int _semester = 1;

  // ── Step 3 — Password ────────────────────────────────────────────────────
  final _step3Key = GlobalKey<FormState>();
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      _goTo(1);
    } else if (_step == 1) {
      if (!_step2Key.currentState!.validate()) return;
      if (_faculty == null) {
        setState(() => _error = 'Please select your faculty');
        return;
      }
      if (_programme == null) {
        setState(() => _error = 'Please select your degree programme');
        return;
      }
      _goTo(2);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_step > 0) _goTo(_step - 1);
  }

  Future<void> _submit() async {
    if (!_step3Key.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      // After register, always go to email verification
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (_step > 0) {
              _prevStep();
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_step + 1} / 3',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StepProgressBar(current: _step + 1, total: 3),
            ),

            const SizedBox(height: 8),

            // ── Error banner ─────────────────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AuthErrorBanner(message: _error!),
              ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    formKey: _step1Key,
                    nameCtrl: _nameCtrl,
                    emailCtrl: _emailCtrl,
                    role: _role,
                    onRoleChanged: (r) => setState(() => _role = r),
                  ),
                  _Step2(
                    formKey: _step2Key,
                    studentIdCtrl: _studentIdCtrl,
                    selectedFaculty: _faculty,
                    selectedProgramme: _programme,
                    yearLevel: _yearLevel,
                    semester: _semester,
                    onFacultyChanged: (f) {
                      setState(() {
                        _faculty = f;
                        _programme = null;
                      });
                      if (f != null) {
                        context.read<AuthProvider>().loadProgrammes(f);
                      }
                    },
                    onProgrammeChanged: (p) => setState(() => _programme = p),
                    onYearChanged: (y) => setState(() => _yearLevel = y),
                    onSemesterChanged: (s) => setState(() => _semester = s),
                  ),
                  _Step3(
                    formKey: _step3Key,
                    passwordCtrl: _passwordCtrl,
                    confirmCtrl: _confirmCtrl,
                    pwVisible: _pwVisible,
                    confirmVisible: _confirmVisible,
                    onTogglePw: () => setState(() => _pwVisible = !_pwVisible),
                    onToggleConfirm: () =>
                        setState(() => _confirmVisible = !_confirmVisible),
                  ),
                ],
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  child: PrimaryButtonChild(
                    label: _step == 2 ? 'Create Account' : 'Continue',
                    isLoading: _isLoading,
                    icon: _step < 2 ? Icons.arrow_forward_rounded : null,
                  ),
                ),
              ),
            ),

            // ── Sign in link ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 1: Personal info + role picker
// ───────────────────────────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final String role;
  final ValueChanged<String> onRoleChanged;

  const _Step1({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            const FieldLabel('Full Name', required: true),
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Tendai Moyo',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your full name'
                  : null,
            ),

            const SizedBox(height: 16),

            const FieldLabel('Email Address', required: true),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'student@university.edu',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!RegExp(
                  r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
                ).hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            const FieldLabel('I am a…', required: true),
            Row(
              children: [
                _RoleCard(
                  icon: Icons.school_rounded,
                  label: 'Student',
                  selected: role == RoleOptions.student,
                  onTap: () => onRoleChanged(RoleOptions.student),
                ),
                const SizedBox(width: 12),
                _RoleCard(
                  icon: Icons.cast_for_education_rounded,
                  label: 'Lecturer',
                  selected: role == RoleOptions.lecturer,
                  onTap: () => onRoleChanged(RoleOptions.lecturer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySubtle : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 2: Academic details
// ───────────────────────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController studentIdCtrl;
  final String? selectedFaculty;
  final String? selectedProgramme;
  final int yearLevel;
  final int semester;
  final ValueChanged<String?> onFacultyChanged;
  final ValueChanged<String?> onProgrammeChanged;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onSemesterChanged;

  const _Step2({
    required this.formKey,
    required this.studentIdCtrl,
    required this.selectedFaculty,
    required this.selectedProgramme,
    required this.yearLevel,
    required this.semester,
    required this.onFacultyChanged,
    required this.onProgrammeChanged,
    required this.onYearChanged,
    required this.onSemesterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Academic details',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Faculty
            const FieldLabel('Faculty', required: true),
            Consumer<AuthProvider>(
              builder: (_, auth, _) => DropdownButtonFormField<String>(
                initialValue: selectedFaculty,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select your faculty',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
                items: auth.faculties
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: auth.isLoadingMetadata ? null : onFacultyChanged,
                validator: (v) => v == null ? 'Select your faculty' : null,
              ),
            ),

            const SizedBox(height: 16),

            // Degree programme
            const FieldLabel('Degree Programme', required: true),
            Consumer<AuthProvider>(
              builder: (_, auth, _) => DropdownButtonFormField<String>(
                initialValue: selectedProgramme,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: auth.isLoadingMetadata
                      ? 'Loading…'
                      : selectedFaculty == null
                      ? 'Select faculty first'
                      : 'Select your programme',
                  prefixIcon: const Icon(Icons.history_edu_outlined, size: 20),
                ),
                items: auth.programmes
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (auth.isLoadingMetadata || selectedFaculty == null)
                    ? null
                    : onProgrammeChanged,
                validator: (v) =>
                    v == null ? 'Select your degree programme' : null,
              ),
            ),

            const SizedBox(height: 16),

            // Year + Semester (side by side)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Year Level', required: true),
                      DropdownButtonFormField<int>(
                        initialValue: yearLevel,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                        ),
                        items: YearLevelOptions.yearLevels
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(
                                  'Year $y',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onYearChanged(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Semester', required: true),
                      DropdownButtonFormField<int>(
                        initialValue: semester,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.timer_outlined, size: 20),
                        ),
                        items: SemesterOptions.semesters
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  'Sem $s',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onSemesterChanged(v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Student ID — optional
            const FieldLabel('Student ID (optional)'),
            TextFormField(
              controller: studentIdCtrl,
              decoration: const InputDecoration(
                hintText: 'C22123456X',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Step 3: Set password
// ───────────────────────────────────────────────────────────────────────────
class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool pwVisible;
  final bool confirmVisible;
  final VoidCallback onTogglePw;
  final VoidCallback onToggleConfirm;

  const _Step3({
    required this.formKey,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.pwVisible,
    required this.confirmVisible,
    required this.onTogglePw,
    required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Secure your account',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            const FieldLabel('Password', required: true),
            TextFormField(
              controller: passwordCtrl,
              obscureText: !pwVisible,
              decoration: InputDecoration(
                hintText: 'At least 8 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    pwVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: onTogglePw,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            const FieldLabel('Confirm Password', required: true),
            TextFormField(
              controller: confirmCtrl,
              obscureText: !confirmVisible,
              decoration: InputDecoration(
                hintText: 'Repeat your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    confirmVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: onToggleConfirm,
                ),
              ),
              validator: (v) =>
                  v != passwordCtrl.text ? 'Passwords do not match' : null,
            ),

            const SizedBox(height: 24),

            // Password hints
            _PasswordHint(
              label: 'At least 8 characters',
              met: passwordCtrl.text.length >= 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  final String label;
  final bool met;
  const _PasswordHint({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: met ? AppColors.success : AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: met ? AppColors.success : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
