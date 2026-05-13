import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'widgets/auth_widgets.dart';

/// Accessed via deep link: reelscholar://reset-password?token=XXX&email=YYY
/// Route args: {'token': String, 'email': String}
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _pwVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;
  bool _success = false;
  String? _error;

  // Extracted from route arguments or deep link
  String _token = '';
  String _email = '';
  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _token = args?['token'] as String? ?? '';
      _email = args?['email'] as String? ?? '';
      _argsLoaded = true;
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_token.isEmpty || _email.isEmpty) {
      setState(() => _error =
          'Invalid reset link. Please request a new one.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().resetPassword(
            token: _token,
            email: _email,
            password: _passwordCtrl.text,
            passwordConfirmation: _confirmCtrl.text,
          );
      if (!mounted) return;
      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _success
                ? _SuccessView(
                    onGoToLogin: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                  )
                : _FormBody(
                    formKey: _formKey,
                    passwordCtrl: _passwordCtrl,
                    confirmCtrl: _confirmCtrl,
                    pwVisible: _pwVisible,
                    confirmVisible: _confirmVisible,
                    isLoading: _isLoading,
                    error: _error,
                    onTogglePw: () =>
                        setState(() => _pwVisible = !_pwVisible),
                    onToggleConfirm: () =>
                        setState(() => _confirmVisible = !_confirmVisible),
                    onSubmit: _resetPassword,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool pwVisible;
  final bool confirmVisible;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePw;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  const _FormBody({
    required this.formKey,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.pwVisible,
    required this.confirmVisible,
    required this.isLoading,
    required this.error,
    required this.onTogglePw,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Set New Password',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose a strong password for your account.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 32),

          if (error != null) AuthErrorBanner(message: error!),

          const FieldLabel('New Password', required: true),
          TextFormField(
            controller: passwordCtrl,
            obscureText: !pwVisible,
            decoration: InputDecoration(
              hintText: 'At least 8 characters',
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded, size: 20),
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
              if (v == null || v.isEmpty) return 'Enter a new password';
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
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded, size: 20),
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

          const SizedBox(height: 32),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: PrimaryButtonChild(
                label: 'Update Password',
                isLoading: isLoading,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onGoToLogin;
  const _SuccessView({required this.onGoToLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 44,
              color: AppColors.success,
            ),
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Password Updated!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Your password has been changed successfully.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),

        const SizedBox(height: 40),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onGoToLogin,
            child: const Text(
              'Back to Login',
              style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
