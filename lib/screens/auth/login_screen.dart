import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _loginFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_loginCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (auth.user?.emailVerified == false) {
        Navigator.pushReplacementNamed(context, '/verify-email');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
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

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    final surfaceColor =
        isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSub = isDark ? Colors.white60 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                child: Column(
                  children: [
                    const AppLogoBadge(size: 68),
                    const SizedBox(height: 18),
                    const Text(
                      'ReelScholar',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Learn. Create. Grow.',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable form ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue learning',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error
                    if (_error != null) AuthErrorBanner(message: _error!),

                    // Email / Student ID
                    FieldLabel('Email / Student ID', required: true),
                    TextFormField(
                      controller: _loginCtrl,
                      focusNode: _loginFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: authInputTextStyle(isDark),
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      decoration: authInputDecoration(
                        isDark: isDark,
                        hintText: 'you@university.edu',
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.white38
                              : AppColors.textTertiary,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your email or student ID'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Password
                    FieldLabel('Password', required: true),
                    TextFormField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: !_passwordVisible,
                      textInputAction: TextInputAction.done,
                      style: authInputTextStyle(isDark),
                      onFieldSubmitted: (_) => _login(),
                      decoration: authInputDecoration(
                        isDark: isDark,
                        hintText: '••••••••',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.white38
                              : AppColors.textTertiary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textTertiary,
                          ),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sign In button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: PrimaryButtonChild(
                          label: 'Sign In',
                          isLoading: _isLoading,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New here? ',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            color: textSub,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/register'),
                          child: const Text(
                            'Create account',
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
