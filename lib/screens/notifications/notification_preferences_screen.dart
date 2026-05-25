import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/notification_provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadPreferences();
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final error =
        await context.read<NotificationProvider>().setPreference(key, value);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: const TextStyle(fontFamily: AppFonts.dmSans),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, prov, _) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Notification Preferences',
              style: TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: prov.loadingPreferences && prov.preferences.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _SectionHeader('Social'),
                    _PrefTile(
                      label: 'Followers',
                      subtitle: 'When someone follows you',
                      prefKey: 'followers',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                    _PrefTile(
                      label: 'Likes',
                      subtitle: 'When someone likes your reel',
                      prefKey: 'likes',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                    _PrefTile(
                      label: 'Comments',
                      subtitle: 'When someone comments on your reel',
                      prefKey: 'comments',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _SectionHeader('Messaging'),
                    _PrefTile(
                      label: 'Direct Messages',
                      subtitle: 'Message requests and replies',
                      prefKey: 'direct_messages',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _SectionHeader('Groups & Hackathons'),
                    _PrefTile(
                      label: 'Study Groups',
                      subtitle: 'Invites, join requests, and updates',
                      prefKey: 'study_groups',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                    _PrefTile(
                      label: 'Hackathons',
                      subtitle: 'Hackathon start, voting, and results',
                      prefKey: 'hackathons',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _SectionHeader('System'),
                    _PrefTile(
                      label: 'Announcements',
                      subtitle: 'Important platform announcements',
                      prefKey: 'announcements',
                      prefs: prov.preferences,
                      onToggle: _toggle,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppFonts.dmSans,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String prefKey;
  final Map<String, bool> prefs;
  final Future<void> Function(String key, bool value) onToggle;

  const _PrefTile({
    required this.label,
    required this.subtitle,
    required this.prefKey,
    required this.prefs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final value = prefs[prefKey] ?? true;
    return SwitchListTile(
      value: value,
      onChanged: (v) => onToggle(prefKey, v),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AppFonts.dmSans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: AppFonts.dmSans,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
