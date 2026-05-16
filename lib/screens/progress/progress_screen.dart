// lib/screens/progress/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/progress_models.dart';
import 'package:reelscholar/providers/progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  final int initialTab;
  const ProgressScreen({super.key, this.initialTab = 0});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final ProgressProvider _provider;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);
    _provider = context.read<ProgressProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadDashboard();
      _provider.loadLeaderboard();
      _provider.loadAchievements();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'My Progress',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      _provider.loadDashboard(refresh: true);
                      _provider.loadLeaderboard(refresh: true);
                      _provider.loadAchievements(refresh: true);
                    },
                  ),
                ],
              ),
            ),

            // ── Tab bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Leaderboard'),
                    Tab(text: 'Achievements'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _OverviewTab(),
                  _LeaderboardTab(),
                  _AchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Overview Tab
// ════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (_, p, _) {
        if (p.dashboardLoading && p.dashboard == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (p.dashboardError != null && p.dashboard == null) {
          return _ErrorState(
            message: p.dashboardError!,
            onRetry: () => p.loadDashboard(refresh: true),
          );
        }
        final overview = p.dashboard?.overview ?? ProgressOverview.empty;
        final heatmap = p.dashboard?.heatmap ?? [];
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => p.loadDashboard(refresh: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              // XP + Streak hero
              _HeroCard(overview: overview),
              const SizedBox(height: 14),
              // Stats grid
              _StatsGrid(overview: overview),
              const SizedBox(height: 20),
              // Study heatmap
              if (heatmap.isNotEmpty) ...[
                const _SectionTitle('Activity Heatmap'),
                const SizedBox(height: 8),
                _HeatmapGrid(days: heatmap),
                const SizedBox(height: 20),
              ],
              // Module progress
              const _SectionTitle('Study Summary'),
              const SizedBox(height: 8),
              _SummaryRow(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  label: 'Modules Completed',
                  value: '${overview.modulesCompleted}/${overview.modulesTotal}'),
              _SummaryRow(
                  icon: Icons.auto_graph_rounded,
                  color: AppColors.primary,
                  label: 'Avg Quiz Score',
                  value: '${overview.avgQuizScore.toStringAsFixed(1)}%'),
              _SummaryRow(
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF6366F1),
                  label: 'Total Quizzes',
                  value: '${overview.totalQuizzes}'),
              _SummaryRow(
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                  label: 'Study Time',
                  value: _formatMinutes(overview.totalStudyMinutes),
                  isLast: true),
            ],
          ),
        );
      },
    );
  }

  String _formatMinutes(int mins) {
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _HeroCard extends StatelessWidget {
  final ProgressOverview overview;
  const _HeroCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total XP',
                    style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  '${overview.totalXp} XP',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${overview.currentStreak} day streak',
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Colors.amber, size: 32),
              ),
              const SizedBox(height: 6),
              Text(
                'Best: ${overview.longestStreak}d',
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ProgressOverview overview;
  const _StatsGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
            label: 'Modules Done',
            value: '${overview.modulesCompleted}',
            icon: Icons.check_circle_rounded,
            color: AppColors.success),
        _StatCard(
            label: 'In Progress',
            value: '${overview.modulesInProgress}',
            icon: Icons.pending_rounded,
            color: const Color(0xFF6366F1)),
        _StatCard(
            label: 'Quizzes Taken',
            value: '${overview.totalQuizzes}',
            icon: Icons.quiz_rounded,
            color: AppColors.primary),
        _StatCard(
            label: 'Avg Score',
            value: '${overview.avgQuizScore.toStringAsFixed(0)}%',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFF59E0B)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List<HeatmapDay> days;
  const _HeatmapGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Show last 84 days (12 weeks x 7)
    final recent = days.length > 84 ? days.sublist(days.length - 84) : days;
    // Pad to full weeks
    final padded = [...List.generate(recent.isEmpty ? 0 : recent.first.date.weekday % 7,
        (_) => null), ...recent.map<HeatmapDay?>((d) => d)];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last ${recent.length} days',
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary)),
              Row(
                children: [
                  const Text('Less',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: AppColors.textTertiary)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _intensityColor(i, isDark),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
                  const SizedBox(width: 4),
                  const Text('More',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1,
            ),
            itemCount: padded.length,
            itemBuilder: (_, i) {
              final day = padded[i];
              return Tooltip(
                message: day == null
                    ? ''
                    : '${day.date.month}/${day.date.day}: ${day.minutesStudied}m studied',
                child: Container(
                  decoration: BoxDecoration(
                    color: day == null
                        ? Colors.transparent
                        : _intensityColor(day.intensity, isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _intensityColor(int intensity, bool isDark) {
    const colors = [
      Color(0xFFE2E8F0),
      Color(0xFFBBF7D0),
      Color(0xFF86EFAC),
      Color(0xFF4ADE80),
      Color(0xFF16A34A),
    ];
    const darkColors = [
      Color(0xFF1E293B),
      Color(0xFF14532D),
      Color(0xFF166534),
      Color(0xFF15803D),
      Color(0xFF16A34A),
    ];
    final list = isDark ? darkColors : colors;
    return list[intensity.clamp(0, 4)];
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary));
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isLast;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary))),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Leaderboard Tab
// ════════════════════════════════════════════════════════════════════════════

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (_, p, _) {
        if (p.lbLoading && p.leaderboard == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (p.lbError != null && p.leaderboard == null) {
          return _ErrorState(
              message: p.lbError!,
              onRetry: () => p.loadLeaderboard(refresh: true));
        }
        final lb = p.leaderboard;
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => p.loadLeaderboard(refresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scope chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ScopeChip(
                                label: 'Programme',
                                value: 'programme',
                                active: p.lbScope == 'programme',
                                onTap: () =>
                                    p.setLeaderboardScope('programme')),
                            const SizedBox(width: 8),
                            _ScopeChip(
                                label: 'Faculty',
                                value: 'faculty',
                                active: p.lbScope == 'faculty',
                                onTap: () => p.setLeaderboardScope('faculty')),
                            const SizedBox(width: 8),
                            _ScopeChip(
                                label: 'Global',
                                value: 'global',
                                active: p.lbScope == 'global',
                                onTap: () => p.setLeaderboardScope('global')),
                          ],
                        ),
                      ),
                      if (lb != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.leaderboard_rounded,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your rank: #${lb.myRank}  ·  ${lb.scopeLabel}',
                                  style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
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
              ),
              if (lb == null || lb.entries.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No leaderboard data',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: AppColors.textSecondary)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _LeaderboardRow(
                        entry: lb.entries[i],
                        isLast: i == lb.entries.length - 1,
                      ),
                      childCount: lb.entries.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const _ScopeChip(
      {required this.label,
      required this.value,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isLast;

  const _LeaderboardRow({required this.entry, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rank = int.tryParse(entry.rank) ?? 99;
    final isTop3 = rank <= 3;
    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);
    final hue = entry.name.codeUnits.fold(0, (a, b) => a + b) % 360;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: isTop3
                ? Text(
                    rank == 1
                        ? '🥇'
                        : rank == 2
                            ? '🥈'
                            : '🥉',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  )
                : Text(
                    '#${entry.rank}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary),
                  ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.4).toColor(),
                HSLColor.fromAHSL(
                        1, (hue + 40.0) % 360, 0.7, 0.3)
                    .toColor(),
              ]),
              shape: BoxShape.circle,
              border: isTop3
                  ? Border.all(color: medalColor, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                if (entry.degreeProgramme != null)
                  Text(
                    entry.degreeProgramme!,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalXp} XP',
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 11, color: Colors.orange),
                  Text(
                    ' ${entry.currentStreak}d',
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Achievements Tab
// ════════════════════════════════════════════════════════════════════════════

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (_, p, _) {
        if (p.achievementsLoading && p.achievements.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (p.achievementsError != null && p.achievements.isEmpty) {
          return _ErrorState(
              message: p.achievementsError!,
              onRetry: () => p.loadAchievements(refresh: true));
        }
        if (p.achievements.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                    child: const Icon(Icons.emoji_events_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No achievements yet',
                      style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                      'Participate in hackathons to earn badges!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => p.loadAchievements(refresh: true),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: p.achievements.length,
            itemBuilder: (_, i) => _AchievementCard(achievement: p.achievements[i]),
          ),
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.badgeIcon,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.badgeLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.hackathonTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: AppColors.textTertiary),
          ),
          if (achievement.awardedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _fmtDate(achievement.awardedAt!),
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ════════════════════════════════════════════════════════════════════════════
// Shared
// ════════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
