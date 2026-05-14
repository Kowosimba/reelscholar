import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/providers/profile_provider.dart';
import 'package:reelscholar/screens/chats/chats_screen.dart';
import 'package:reelscholar/screens/profile/edit_profile_screen.dart';
import 'package:reelscholar/screens/profile/settings_screen.dart';
import 'package:reelscholar/screens/reels/upload_reel_screen.dart';
import 'package:reelscholar/screens/social/blocked_users_screen.dart';
import 'package:reelscholar/screens/social/followers_screen.dart';
import 'package:reelscholar/screens/study_groups/study_groups_screen.dart';
import 'package:reelscholar/screens/tutor/modules_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProfileProvider>(
        builder: (context, p, child) {
          if (p.meLoading && p.me == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (p.meError != null && p.me == null) {
            return _ErrorView(
              message: p.meError!,
              onRetry: () => p.loadMe(refresh: true),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => p.loadMe(refresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Banner(),
                      _AvatarEditRow(p: p),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.displayName.isEmpty ? 'Student' : p.displayName,
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subtitle(p),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (p.currentStreak > 0)
                                  _FlamePill(streak: p.currentStreak),
                                _Pill(
                                  label: p.isLecturer
                                      ? 'Lecturer'
                                      : 'Top Student',
                                  bg: const Color(0xFFDBEAFE),
                                  fg: const Color(0xFF1E40AF),
                                ),
                                const _Pill(
                                  label: 'Verified',
                                  bg: Color(0xFFDCFCE7),
                                  fg: Color(0xFF166534),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      _XpStrip(p: p),
                      _StatsRow(p: p),
                      const SizedBox(height: 8),
                      _SectionLabel(
                        title: 'Quick Access',
                        hint: 'Backend-linked tools and spaces',
                      ),
                      _Tile(
                        icon: Icons.add_box_outlined,
                        label: 'Add New Content',
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0369A1),
                        onTap: () => _push(context, const UploadReelScreen()),
                      ),
                      _Tile(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chats',
                        iconBg: const Color(0xFFEDE9FE),
                        iconColor: const Color(0xFF6D28D9),
                        onTap: () => _push(context, const ChatsScreen()),
                      ),
                      _Tile(
                        icon: Icons.groups_outlined,
                        label: 'Study Groups',
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF047857),
                        onTap: () => _push(context, const StudyGroupsScreen()),
                      ),
                      _Tile(
                        icon: Icons.menu_book_outlined,
                        label: 'Learning Hub',
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFEA580C),
                        onTap: () => _push(context, const ModulesScreen()),
                      ),
                      const SizedBox(height: 8),
                      const _SectionLabel(
                        title: 'Account',
                        hint: 'Profile and preferences',
                      ),
                      _Tile(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        onTap: () => _push(context, const EditProfileScreen()),
                      ),
                      _Tile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: () =>
                            _push(context, const ChangePasswordScreen()),
                      ),
                      _Tile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                      _Tile(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                      _Tile(
                        icon: Icons.shield_outlined,
                        label: 'Privacy',
                        onTap: () => _push(context, const BlockedUsersScreen()),
                      ),
                      _Tile(
                        icon: Icons.people_outline_rounded,
                        label: 'Followers & Following',
                        onTap: () => _push(
                          context,
                          FollowersScreen(
                            userId: p.me?['uid'] as String? ?? '',
                            userName: p.displayName,
                            initialTab: 0,
                            isMine: true,
                          ),
                        ),
                      ),
                      _Tile(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                      _Tile(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        iconBg: const Color(0xFFFEE2E2),
                        iconColor: AppColors.error,
                        labelColor: AppColors.error,
                        showChevron: false,
                        onTap: () => _confirmLogout(context),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _push(BuildContext ctx, Widget screen) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
  }

  static String _subtitle(ProfileProvider p) {
    final parts = <String>[];
    if (p.studentId?.isNotEmpty == true) parts.add(p.studentId!);
    if (p.faculty?.isNotEmpty == true) {
      var faculty = p.faculty!;
      faculty = faculty.replaceAll('School of ', '');
      faculty = faculty.replaceAll('Institute of ', '');
      parts.add(faculty);
    }
    parts.add('Year ${p.yearLevel}');
    return parts.join(' · ');
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'You\'ll need to sign in again to continue.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<AuthProvider>().logout();
              if (ctx.mounted) {
                Navigator.pushReplacementNamed(ctx, '/login');
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarEditRow extends StatelessWidget {
  final ProfileProvider p;
  const _AvatarEditRow({required this.p});

  List<Color> get _grad {
    final hue = p.displayName.codeUnits.fold(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.4).toColor(),
      HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.7, 0.3).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Transform.translate(
            offset: const Offset(0, -36),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _grad),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: p.profilePicUrl != null
                  ? ClipOval(
                      child: Image.network(
                        p.profilePicUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(child: _InitText(p.initials)),
                      ),
                    )
                  : Center(child: _InitText(p.initials)),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitText extends StatelessWidget {
  final String text;
  const _InitText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _FlamePill extends StatelessWidget {
  final int streak;
  const _FlamePill({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$streak streak',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _XpStrip extends StatelessWidget {
  final ProfileProvider p;
  const _XpStrip({required this.p});

  static const _names = [
    '',
    'Novice',
    'Learner',
    'Explorer',
    'Scholar',
    'Expert',
    'Master',
    'Legend',
    'Sage',
    'Guru',
    'Titan',
  ];

  String _name(int level) => _names[level.clamp(1, _names.length - 1)];

  @override
  Widget build(BuildContext context) {
    final xpInLevel = p.totalXp % 500;
    final xpLeft = 500 - xpInLevel;
    final nextLevel = p.xpLevel + 1;
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${p.xpLevel} · ${_name(p.xpLevel)}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_fmt(xpInLevel)} / 500 XP',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.xpProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_fmt(xpLeft)} XP to reach Level $nextLevel · ${_name(nextLevel)}',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int value) {
    return value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
  }
}

class _StatsRow extends StatelessWidget {
  final ProfileProvider p;
  const _StatsRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final uid = p.me?['uid'] as String? ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _StatBox(value: '${p.videoCount}', label: 'Reels'),
          _divider(),
          _StatBox(
            value: _fmt(p.followersCount),
            label: 'Followers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowersScreen(
                  userId: uid,
                  userName: p.displayName,
                  isMine: true,
                  initialTab: 0,
                ),
              ),
            ),
          ),
          _divider(),
          _StatBox(
            value: _fmt(p.followingCount),
            label: 'Following',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FollowersScreen(
                  userId: uid,
                  userName: p.displayName,
                  isMine: true,
                  initialTab: 1,
                ),
              ),
            ),
          ),
          _divider(),
          _StatBox(value: '#${p.xpLevel}', label: 'Rank'),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: const Color(0xFFF1F5F9));
  }

  static String _fmt(int value) {
    return value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatBox({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String hint;
  const _SectionLabel({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            hint,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;
  final Color labelColor;
  final bool showChevron;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBg = const Color(0xFFF8FAFC),
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
