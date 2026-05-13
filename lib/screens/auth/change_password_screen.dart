import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'widgets/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
            newPasswordConfirmation: _confirmCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
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
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

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

                const SizedBox(height: 20),

                const Text(
                  'Update Your Password',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Enter your current password, then choose a new one.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                if (_error != null) AuthErrorBanner(message: _error!),

                // Current password
                const FieldLabel('Current Password', required: true),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: !_currentVisible,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20),
                    suffixIcon: _visibilityIcon(
                      _currentVisible,
                      () => setState(
                          () => _currentVisible = !_currentVisible),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter your current password'
                      : null,
                ),

                const SizedBox(height: 16),

                // New password
                const FieldLabel('New Password', required: true),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_newVisible,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    prefixIcon:
                        const Icon(Icons.lock_rounded, size: 20),
                    suffixIcon: _visibilityIcon(
                      _newVisible,
                      () =>
                          setState(() => _newVisible = !_newVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter a new password';
                    }
                    if (v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Password strength hint
                Row(
                  children: [
                    Icon(
                      _newCtrl.text.length >= 8
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: _newCtrl.text.length >= 8
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'At least 8 characters',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: _newCtrl.text.length >= 8
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Confirm password
                const FieldLabel('Confirm New Password', required: true),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_confirmVisible,
                  decoration: InputDecoration(
                    hintText: 'Repeat new password',
                    prefixIcon:
                        const Icon(Icons.lock_rounded, size: 20),
                    suffixIcon: _visibilityIcon(
                      _confirmVisible,
                      () => setState(
                          () => _confirmVisible = !_confirmVisible),
                    ),
                  ),
                  validator: (v) =>
                      v != _newCtrl.text ? 'Passwords do not match' : null,
                ),

                const SizedBox(height: 36),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: PrimaryButtonChild(
                      label: 'Update Password',
                      isLoading: _isLoading,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _visibilityIcon(bool visible, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: AppColors.textTertiary,
      ),
      onPressed: onTap,
    );
  }
}
