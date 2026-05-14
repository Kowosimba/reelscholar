// lib/screens/hackathons/hackathon_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';
import 'package:reelscholar/screens/hackathons/hackathon_detail_screen.dart';

class HackathonListScreen extends StatefulWidget {
  const HackathonListScreen({super.key});

  @override
  State<HackathonListScreen> createState() => _HackathonListScreenState();
}

class _HackathonListScreenState extends State<HackathonListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<HackathonProvider>().loadMoreHackathons();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HackathonProvider>().loadHackathons(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hackathons',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Consumer<HackathonProvider>(
        builder: (_, p, _) {
          if (p.listLoading && p.hackathons.isEmpty) {
            return const _HackShimmer();
          }
          if (p.listError != null && p.hackathons.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 44, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(p.listError!,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () =>
                          p.loadHackathons(refresh: true),
                      child: const Text('Retry')),
                ],
              ),
            );
          }
          if (p.hackathons.isEmpty) {
            return const _EmptyHacks();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => p.loadHackathons(refresh: true),
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount:
                  p.hackathons.length + (p.listLoadingMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == p.hackathons.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary),
                      ),
                    ),
                  );
                }
                return _HackCard(
                  hack: p.hackathons[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HackathonDetailScreen(
                          hackId: p.hackathons[i].id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Hackathon card ────────────────────────────────────────────────────────────

class _HackCard extends StatelessWidget {
  final Hackathon hack;
  final VoidCallback onTap;

  const _HackCard({required this.hack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner / gradient hero
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: hack.bannerUrl != null
                  ? Image.network(
                      hack.bannerUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _GradientBanner(hack: hack),
                    )
                  : _GradientBanner(hack: hack),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + registered badge
                  Row(
                    children: [
                      _StatusPill(status: hack.status),
                      if (hack.isRegistered) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✅ Joined',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    hack.title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (hack.theme != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      hack.theme!,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Footer info
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.people_rounded,
                        label: hack.isSolo
                            ? 'Solo'
                            : 'Team ${hack.minTeamSize}–${hack.maxTeamSize}',
                      ),
                      const SizedBox(width: 8),
                      if (hack.endsAt != null)
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: _fmtDate(hack.endsAt!),
                        ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textTertiary),
                    ],
                  ),

                  // Prizes teaser
                  if (hack.prizes != null &&
                      hack.prizes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              hack.prizes!,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}';
  }
}

class _GradientBanner extends StatelessWidget {
  final Hackathon hack;
  const _GradientBanner({required this.hack});

  List<Color> get _colors {
    final hue =
        hack.title.codeUnits.fold(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.35).toColor(),
      HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.65, 0.25).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.code_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final HackStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            status.label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _EmptyHacks extends StatelessWidget {
  const _EmptyHacks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.code_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hackathons yet',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for upcoming events',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HackShimmer extends StatelessWidget {
  const _HackShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}
