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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Consumer<ProfileProvider>(
        builder: (context, p, _) {
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
                SliverToBoxAdapter(child: _ProfileBody(p: p, isDark: isDark)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final ProfileProvider p;
  final bool isDark;
  const _ProfileBody({required this.p, required this.isDark});

  static String _subtitle(ProfileProvider p) {
    final parts = <String>[];
    if (p.studentId?.isNotEmpty == true) parts.add(p.studentId!);
    if (p.faculty?.isNotEmpty == true) {
      var f = p.faculty!
          .replaceAll('School of ', '')
          .replaceAll('Institute of ', '');
      parts.add(f);
    }
    parts.add('Year ${p.yearLevel}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner + avatar overlap via Stack
        _BannerWithAvatar(p: p, isDark: isDark),

        // Name + subtitle + pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.displayName.isEmpty ? 'Student' : p.displayName,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                _subtitle(p),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (p.currentStreak > 0) _FlamePill(streak: p.currentStreak),
                  _Pill(
                    label: p.isLecturer ? 'Lecturer' : 'Top Student',
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
              const SizedBox(height: 20),
            ],
          ),
        ),

        // XP card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SurfaceCard(isDark: isDark, child: _XpStrip(p: p, isDark: isDark)),
        ),
        const SizedBox(height: 12),

        // Stats card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SurfaceCard(isDark: isDark, child: _StatsRow(p: p, isDark: isDark)),
        ),
        const SizedBox(height: 20),

        // Quick Access
        _SectionLabel(
          title: 'Quick Access',
          hint: 'Create & connect',
          isDark: isDark,
        ),
        _TileGroup(
          isDark: isDark,
          children: [
            _Tile(
              icon: Icons.add_box_outlined,
              label: 'Add New Content',
              subtitle: 'Upload a fresh learning reel',
              iconBg: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF0369A1),
              isDark: isDark,
              onTap: () => _push(context, const UploadReelScreen()),
            ),
            _Tile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chats',
              subtitle: 'Catch up on conversations',
              iconBg: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF6D28D9),
              isDark: isDark,
              onTap: () => _push(context, const ChatsScreen()),
            ),
            _Tile(
              icon: Icons.groups_outlined,
              label: 'Study Groups',
              subtitle: 'Jump back into your communities',
              iconBg: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF047857),
              isDark: isDark,
              onTap: () => _push(context, const StudyGroupsScreen()),
            ),
            _Tile(
              icon: Icons.menu_book_outlined,
              label: 'Learning Hub',
              subtitle: 'Pick up where your modules left off',
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFEA580C),
              isDark: isDark,
              isLast: true,
              onTap: () => _push(context, const ModulesScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // My Content
        _SectionLabel(
          title: 'My Content',
          hint: 'Your uploaded reels',
          isDark: isDark,
        ),
        _MyContentGrid(p: p, isDark: isDark),
        const SizedBox(height: 48),
      ],
    );
  }

  void _push(BuildContext ctx, Widget screen) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Banner + avatar in a Stack ────────────────────────────────────────────────

class _BannerWithAvatar extends StatelessWidget {
  final ProfileProvider p;
  final bool isDark;
  const _BannerWithAvatar({required this.p, required this.isDark});

  List<Color> get _avatarGrad {
    final hue = p.displayName.codeUnits.fold(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.4).toColor(),
      HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.7, 0.3).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const avatarSize = 82.0;
    const overlap = 36.0;

    return Column(
      children: [
        // Banner
        Stack(
          children: [
            Container(
              height: 170,
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
                    // decorative circles
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
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18)),
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
                                      builder: (_) => const SettingsScreen()),
                                ),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.14)),
                                  ),
                                  child: const Icon(Icons.settings_rounded,
                                      size: 17, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            p.displayName.isEmpty ? 'Student Profile' : p.displayName,
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Streak · XP · Rank — your learning identity',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Avatar row — sits below banner, avatar overlaps via negative margin
        Transform.translate(
          offset: const Offset(0, -overlap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _avatarGrad),
                    border: Border.all(
                      color: isDark ? const Color(0xFF020617) : Colors.white,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220F172A),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: p.profilePicUrl != null
                      ? ClipOval(
                          child: Image.network(
                            p.profilePicUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                Center(child: _InitText(p.initials)),
                          ),
                        )
                      : Center(child: _InitText(p.initials)),
                ),
                const Spacer(),
                // Edit button
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
              ],
            ),
          ),
        ),

        // Pull the content up to close the gap left by the negative translate
        Transform.translate(
          offset: const Offset(0, -overlap),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── XP strip ──────────────────────────────────────────────────────────────────

class _XpStrip extends StatelessWidget {
  final ProfileProvider p;
  final bool isDark;
  const _XpStrip({required this.p, required this.isDark});

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

  static String _fmt(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  @override
  Widget build(BuildContext context) {
    final xpInLevel = p.totalXp % 500;
    final xpLeft = 500 - xpInLevel;
    final nextLevel = p.xpLevel + 1;
    final textSec = isDark ? Colors.white60 : AppColors.textSecondary;
    final textTer = isDark ? Colors.white38 : AppColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Level ${p.xpLevel} · ${_name(p.xpLevel)}',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSec,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_fmt(xpInLevel)} / 500 XP',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.xpProgress,
              minHeight: 8,
              backgroundColor:
                  isDark ? Colors.white12 : const Color(0xFFDDE7F1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_fmt(xpLeft)} XP to Level $nextLevel · ${_name(nextLevel)}',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: textTer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ProfileProvider p;
  final bool isDark;
  const _StatsRow({required this.p, required this.isDark});

  static String _fmt(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  @override
  Widget build(BuildContext context) {
    final uid = p.me?['uid'] as String? ?? '';
    final divColor =
        isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          _StatBox(value: '${p.videoCount}', label: 'Reels', isDark: isDark),
          Container(width: 1, height: 36, color: divColor),
          _StatBox(
            value: _fmt(p.followersCount),
            label: 'Followers',
            isDark: isDark,
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
          Container(width: 1, height: 36, color: divColor),
          _StatBox(
            value: _fmt(p.followingCount),
            label: 'Following',
            isDark: isDark,
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
          Container(width: 1, height: 36, color: divColor),
          _StatBox(value: '#${p.xpLevel}', label: 'Rank', isDark: isDark),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  const _StatBox(
      {required this.value,
      required this.label,
      required this.isDark,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: isDark ? Colors.white38 : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String hint;
  final bool isDark;
  const _SectionLabel(
      {required this.title, required this.hint, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: isDark ? Colors.white38 : AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile group + tile ─────────────────────────────────────────────────────────

class _TileGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _TileGroup({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _SurfaceCard(
        isDark: isDark,
        child: Column(children: children),
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
  final bool isDark;
  final bool isLast;

  const _Tile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    required this.isDark,
    this.iconBg = const Color(0xFFF8FAFC),
    this.iconColor = AppColors.textSecondary,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: divColor, width: 1)),
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
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white30 : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Surface card ──────────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SurfaceCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border.withValues(alpha: 0.9),
        ),
        boxShadow: isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

// ── My content grid ───────────────────────────────────────────────────────────

class _MyContentGrid extends StatelessWidget {
  final ProfileProvider p;
  final bool isDark;
  const _MyContentGrid({required this.p, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final uid = p.me?['uid'] as String? ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return Consumer<ReelProvider>(
      builder: (context, rp, _) {
        final reels = rp.userReels(uid);

        if (reels.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SurfaceCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 40,
                        color: isDark
                            ? Colors.white24
                            : AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No content yet',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share your knowledge by uploading your first reel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UploadReelScreen()),
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
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.68,
            ),
            itemCount: reels.length,
            itemBuilder: (context, i) =>
                _ContentTile(reel: reels[i], reels: reels, index: i),
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
  const _ContentTile(
      {required this.reel, required this.reels, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _ProfileReelViewer(reels: reels, initialIndex: index),
        ),
      ),
      onLongPress: () => _showOptions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: AppColors.border.withValues(alpha: 0.3),
          decoration: reel.thumbnailUrl != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(reel.thumbnailUrl!),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (reel.thumbnailUrl == null)
                const Icon(Icons.play_circle_outline,
                    color: AppColors.textTertiary),
              Positioned(
                bottom: 5,
                left: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        size: 12, color: Colors.white),
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
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: const Text('Delete Reel',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Reel?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
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

// ── Reel viewer ───────────────────────────────────────────────────────────────

class _ProfileReelViewer extends StatefulWidget {
  final List<Reel> reels;
  final int initialIndex;
  const _ProfileReelViewer(
      {required this.reels, required this.initialIndex});

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
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
          onProfileTap: () => Navigator.pushNamed(
            context,
            '/public-profile',
            arguments: widget.reels[i].uploader.uid,
          ),
          onHashtagTap: () {},
        ),
      ),
    );
  }
}

// ── Pill widgets ──────────────────────────────────────────────────────────────

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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
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

// ── Initials text ─────────────────────────────────────────────────────────────

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

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.error),
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
      ),
    );
  }
}
