// lib/features/profile/screens/settings_screen.dart
// Covers: Settings / Notifications + Change Password

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/profile_provider.dart';
import 'package:reelscholar/core/services/profile_service.dart';
import 'edit_profile_screen.dart';
import '../social/blocked_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadNotificationPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── Account section ────────────────────────────────────────────
          _SectionLabel('ACCOUNT'),
          _SettingsCard(
            children: [
              _NavTile(
                icon: Icons.person_outline_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                label: 'Edit Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              _NavTile(
                icon: Icons.lock_outline_rounded,
                iconBg: AppColors.primarySubtle,
                iconColor: AppColors.primary,
                label: 'Change Password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),
              _NavTile(
                icon: Icons.shield_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF64748B),
                label: 'Privacy & Security',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                ),
              ),
            ],
          ),

          // ── Notifications ──────────────────────────────────────────────
          _SectionLabel('NOTIFICATIONS'),
          Consumer<ProfileProvider>(
            builder: (_, p, _) {
              if (p.notifLoading && p.notifPrefs == null) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                );
              }
              final prefs = p.notifPrefs ?? const NotificationPrefs();
              return _SettingsCard(
                children: [
                  _ToggleTile(
                    icon: Icons.person_add_rounded,
                    iconBg: AppColors.primarySubtle,
                    iconColor: AppColors.primary,
                    label: 'New Followers',
                    subtitle: 'When someone follows you',
                    value: prefs.followers,
                    onChanged: (v) =>
                        p.toggleNotifPref('followers', v),
                  ),
                  _ToggleTile(
                    icon: Icons.favorite_rounded,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: AppColors.error,
                    label: 'Likes',
                    subtitle: 'When someone likes your reel',
                    value: prefs.likes,
                    onChanged: (v) =>
                        p.toggleNotifPref('likes', v),
                  ),
                  _ToggleTile(
                    icon: Icons.comment_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    label: 'Comments',
                    subtitle: 'When someone comments on your reel',
                    value: prefs.comments,
                    onChanged: (v) =>
                        p.toggleNotifPref('comments', v),
                  ),
                  _ToggleTile(
                    icon: Icons.chat_bubble_rounded,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
                    label: 'Direct Messages',
                    subtitle: 'New message requests and chats',
                    value: prefs.directMessages,
                    onChanged: (v) =>
                        p.toggleNotifPref('direct_messages', v),
                  ),
                  _ToggleTile(
                    icon: Icons.group_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    label: 'Study Groups',
                    subtitle: 'Group activity and join requests',
                    value: prefs.studyGroups,
                    onChanged: (v) =>
                        p.toggleNotifPref('study_groups', v),
                  ),
                  _ToggleTile(
                    icon: Icons.code_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF1D4ED8),
                    label: 'Hackathons',
                    subtitle: 'New hackathons and updates',
                    value: prefs.hackathons,
                    onChanged: (v) =>
                        p.toggleNotifPref('hackathons', v),
                  ),
                  _ToggleTile(
                    icon: Icons.campaign_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: AppColors.textSecondary,
                    label: 'Announcements',
                    subtitle: 'Platform-wide announcements',
                    value: prefs.announcements,
                    onChanged: (v) =>
                        p.toggleNotifPref('announcements', v),
                    isLast: true,
                  ),
                ],
              );
            },
          ),

          // ── App preferences ────────────────────────────────────────────
          _SectionLabel('APP'),
          _SettingsCard(
            children: [
              _NavTile(
                icon: Icons.dark_mode_rounded,
                iconBg: const Color(0xFF1E293B),
                iconColor: Colors.white,
                label: 'Appearance',
                subtitle: 'Light / Dark / System',
                onTap: () => _showThemePicker(context),
              ),
              _NavTile(
                icon: Icons.info_outline_rounded,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: AppColors.textSecondary,
                label: 'About ReelScholar',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
              _NavTile(
                icon: Icons.help_outline_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                label: 'Help & Support',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Theme',
                style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...['System', 'Light', 'Dark'].map(
                (t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t == 'Dark'
                        ? Icons.dark_mode_rounded
                        : t == 'Light'
                            ? Icons.light_mode_rounded
                            : Icons.settings_brightness_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(t,
                      style: const TextStyle(fontFamily: 'DM Sans')),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Change password screen ─────────────────────────────────────────────────────

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final p = context.read<ProfileProvider>();
    try {
      await p.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        confirmation: _confirmCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password changed successfully ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        size: 36, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Update Your Password',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Enter your current password, then choose a new one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Current
                _FieldLabel('Current Password', required: true),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: !_currentVisible,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(
                        Icons.lock_outline_rounded, size: 20),
                    suffixIcon: _EyeBtn(
                      visible: _currentVisible,
                      onTap: () => setState(
                          () => _currentVisible = !_currentVisible),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter your current password'
                      : null,
                ),
                const SizedBox(height: 16),

                // New
                _FieldLabel('New Password', required: true),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_newVisible,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    prefixIcon:
                        const Icon(Icons.lock_rounded, size: 20),
                    suffixIcon: _EyeBtn(
                      visible: _newVisible,
                      onTap: () =>
                          setState(() => _newVisible = !_newVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter a new password';
                    }
                    if (v.length < 8) {
                      return 'At least 8 characters required';
                    }
                    return null;
                  },
                ),
                // Strength hint
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _newCtrl.text.length >= 8
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 13,
                      color: _newCtrl.text.length >= 8
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'At least 8 characters',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: _newCtrl.text.length >= 8
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirm
                _FieldLabel('Confirm New Password', required: true),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_confirmVisible,
                  decoration: InputDecoration(
                    hintText: 'Repeat new password',
                    prefixIcon:
                        const Icon(Icons.lock_rounded, size: 20),
                    suffixIcon: _EyeBtn(
                      visible: _confirmVisible,
                      onTap: () => setState(
                          () => _confirmVisible = !_confirmVisible),
                    ),
                  ),
                  validator: (v) => v != _newCtrl.text
                      ? 'Passwords do not match'
                      : null,
                ),

                const SizedBox(height: 36),

                Consumer<ProfileProvider>(
                  builder: (_, p, _) => SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: p.pwChanging ? null : _submit,
                      child: p.pwChanging
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white))
                          : const Text(
                              'Update Password',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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
}

class _EyeBtn extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _EyeBtn({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: 20,
        color: AppColors.textTertiary,
      ),
      onPressed: onTap,
    );
  }
}

// ── Shared settings UI components ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < children.length - 1)
                const Divider(
                    height: 1, indent: 56, color: Color(0xFFF1F5F9)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _NavTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          if (required)
            const Text(' *',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}



