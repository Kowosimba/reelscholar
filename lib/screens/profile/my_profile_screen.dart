import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/providers/profile_provider.dart';
import 'package:reelscholar/screens/chats/chats_screen.dart';
import 'package:reelscholar/screens/profile/edit_profile_screen.dart';
import 'package:reelscholar/screens/profile/settings_screen.dart';
import 'package:reelscholar/screens/reels/upload_reel_screen.dart';
import 'package:reelscholar/screens/social/followers_screen.dart';
import 'package:reelscholar/screens/study_groups/study_groups_screen.dart';
import 'package:reelscholar/screens/tutor/modules_screen.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'package:reelscholar/screens/reels/widgets/reel_player_item.dart';

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
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ReelProvider>().loadUserReels(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      _Banner(p: p),
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
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SurfaceCard(child: _XpStrip(p: p)),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SurfaceCard(child: _StatsRow(p: p)),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(
                        title: 'Quick Access',
                        hint: 'Create, connect, and keep momentum',
                      ),
                      _TileGroup(
                        children: [
                          _Tile(
                            icon: Icons.add_box_outlined,
                            label: 'Add New Content',
                            subtitle: 'Upload a fresh learning reel',
                            iconBg: const Color(0xFFE0F2FE),
                            iconColor: const Color(0xFF0369A1),
                            onTap: () => _push(context, const UploadReelScreen()),
                          ),
                          _Tile(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chats',
                            subtitle: 'Catch up on conversations',
                            iconBg: const Color(0xFFEDE9FE),
                            iconColor: const Color(0xFF6D28D9),
                            onTap: () => _push(context, const ChatsScreen()),
                          ),
                          _Tile(
                            icon: Icons.groups_outlined,
                            label: 'Study Groups',
                            subtitle: 'Jump back into your communities',
                            iconBg: const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF047857),
                            onTap: () => _push(context, const StudyGroupsScreen()),
                          ),
                          _Tile(
                            icon: Icons.menu_book_outlined,
                            label: 'Learning Hub',
                            subtitle: 'Pick up where your modules left off',
                            iconBg: const Color(0xFFFFF7ED),
                            iconColor: const Color(0xFFEA580C),
                            onTap: () => _push(context, const ModulesScreen()),
                            isLast: true,
                          ),
                        ],
                      ),
                      const _SectionLabel(
                        title: 'My Content',
                        hint: 'Manage your uploaded learning reels',
                      ),
                      _MyContentGrid(p: p),
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
}

class _MyContentGrid extends StatelessWidget {
  final ProfileProvider p;
  const _MyContentGrid({required this.p});

  @override
  Widget build(BuildContext context) {
    final uid = p.me?['uid'] as String? ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return Consumer<ReelProvider>(
      builder: (context, rp, _) {
        final reels = rp.userReels(uid);

        if (reels.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: _SurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.video_library_outlined,
                        size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    const Text(
                      'No content yet',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Share your knowledge by uploading your first reel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UploadReelScreen()),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Upload Reel'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              return _ContentTile(reel: reel, reels: reels, index: index);
            },
          ),
        );
      },
    );
  }
}

class _ContentTile extends StatelessWidget {
  final Reel reel;
  final List<Reel> reels;
  final int index;
  const _ContentTile({required this.reel, required this.reels, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ProfileReelViewer(reels: reels, initialIndex: index),
          ),
        );
      },
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.border.withValues(alpha: 0.3),
          image: reel.thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(reel.thumbnailUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (reel.thumbnailUrl == null)
              const Center(child: Icon(Icons.play_circle_outline, color: AppColors.textTertiary)),
            Positioned(
              bottom: 6,
              left: 6,
              child: Row(
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    '${reel.viewCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Delete Reel', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Reel?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<ReelProvider>().deleteReel(reel.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final ProfileProvider p;
  const _Banner({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B7285), AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -22,
              right: -28,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -34,
              left: -16,
              child: Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Text(
                          'My Space',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    p.displayName.isEmpty ? 'Student Profile' : p.displayName,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track your streak, shape your profile, and keep your learning identity sharp.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.86),
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
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _grad),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220F172A),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F172A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
              backgroundColor: const Color(0xFFDDE7F1),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    return Container(width: 1, height: 40, color: const Color(0xFFE2E8F0));
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
  final String? subtitle;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;
  final Color labelColor;
  final Color subtitleColor;
  final bool showChevron;
  final bool isLast;

  const _Tile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.iconBg = const Color(0xFFF8FAFC),
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
    this.subtitleColor = AppColors.textTertiary,
    this.showChevron = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
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

class _TileGroup extends StatelessWidget {
  final List<Widget> children;

  const _TileGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _SurfaceCard(
        child: Column(children: children),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileReelViewer extends StatefulWidget {
  final List<Reel> reels;
  final int initialIndex;

  const _ProfileReelViewer({required this.reels, required this.initialIndex});

  @override
  State<_ProfileReelViewer> createState() => _ProfileReelViewerState();
}

class _ProfileReelViewerState extends State<_ProfileReelViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        scrollDirection: Axis.vertical,
        itemCount: widget.reels.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => ReelPlayerItem(
          reel: widget.reels[i],
          isActive: i == _current,
          onProfileTap: () => Navigator.pop(context),
          onHashtagTap: () {},
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
