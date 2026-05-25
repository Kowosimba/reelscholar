// lib/screens/hackathons/hackathon_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';
import 'submission_screen.dart';
import 'leaderboard_screen.dart';
import 'discussion_screen.dart';
import 'mentor_chat_screen.dart';
import 'team_chat_screen.dart';

class HackathonDetailScreen extends StatefulWidget {
  final String hackId;
  const HackathonDetailScreen({super.key, required this.hackId});

  @override
  State<HackathonDetailScreen> createState() =>
      _HackathonDetailScreenState();
}

class _HackathonDetailScreenState extends State<HackathonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  int _prevTabCount = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _prevTabCount = 3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HackathonProvider>().loadHackathon(widget.hackId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<({String label, Widget body})> _buildTabs(
      Hackathon hack, String currentUid) {
    final tabs = <({String label, Widget body})>[
      (label: 'Overview', body: _OverviewTab(hack: hack)),
      (label: 'Team', body: _TeamTab(hack: hack)),
      (label: 'Discussion', body: _DiscussionTab(hackId: hack.id)),
    ];

    final status = hack.status;
    final hasTeam = hack.hasTeam && hack.myTeamId != null;

    if (hasTeam &&
        (status == HackStatus.inProgress ||
            status == HackStatus.submissionClosed)) {
      tabs.add((
        label: 'Chat',
        body: _TeamChatTab(hackId: hack.id, teamId: hack.myTeamId!),
      ));
      tabs.add((
        label: 'Submit',
        body: _SubmissionTab(hackId: hack.id),
      ));
    }

    if (hasTeam && status == HackStatus.votingOpen) {
      tabs.add((
        label: 'Chat',
        body: _TeamChatTab(hackId: hack.id, teamId: hack.myTeamId!),
      ));
      tabs.add((
        label: 'Vote',
        body: _LeaderboardTab(hackId: hack.id, voteMode: true),
      ));
      tabs.add((
        label: 'Leaderboard',
        body: _LeaderboardTab(hackId: hack.id, voteMode: false),
      ));
    }

    if (hasTeam && status == HackStatus.judging) {
      tabs.add((
        label: 'Chat',
        body: _TeamChatTab(hackId: hack.id, teamId: hack.myTeamId!),
      ));
      tabs.add((
        label: 'Leaderboard',
        body: _LeaderboardTab(hackId: hack.id, voteMode: false),
      ));
    }

    if (status == HackStatus.completed || status == HackStatus.ended) {
      tabs.add((
        label: 'Leaderboard',
        body: _LeaderboardTab(hackId: hack.id, voteMode: false),
      ));
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HackathonProvider>(
      builder: (_, p, _) {
        if (p.activeLoading && p.active == null) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary)),
          );
        }
        if (p.activeError != null && p.active == null) {
          return Scaffold(
            appBar: AppBar(elevation: 0),
            body: Center(
                child: Text(p.activeError!,
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        color: AppColors.textSecondary))),
          );
        }
        final hack = p.active;
        if (hack == null) return const Scaffold(body: SizedBox.shrink());

        final currentUid =
            context.read<AuthProvider>().user?.uid ?? '';
        final tabs = _buildTabs(hack, currentUid);
        final tabCount = tabs.length;

        if (tabCount != _prevTabCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _tabs.dispose();
              _tabs = TabController(length: tabCount, vsync: this);
              _prevTabCount = tabCount;
            });
          });
        }

        final isScrollable = tabCount > 4;

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          body: NestedScrollView(
            headerSliverBuilder: (_, _) => [
              _HackSliverAppBar(hack: hack),
            ],
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: isScrollable,
                    tabAlignment: isScrollable
                        ? TabAlignment.start
                        : TabAlignment.fill,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    tabs: tabs
                        .map((t) => Tab(text: t.label))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: tabs.map((t) => t.body).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sliver app bar ────────────────────────────────────────────────────────────

class _HackSliverAppBar extends StatelessWidget {
  final Hackathon hack;
  const _HackSliverAppBar({required this.hack});

  List<Color> get _gradColors {
    final hue =
        hack.title.codeUnits.fold(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.35).toColor(),
      HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.65, 0.25).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner
            hack.bannerUrl != null
                ? Image.network(hack.bannerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _GradBg(colors: _gradColors))
                : _GradBg(colors: _gradColors),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Title over bottom
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPillLight(status: hack.status),
                  const SizedBox(height: 6),
                  Text(
                    hack.title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hack.theme != null)
                    Text(
                      hack.theme!,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
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

class _GradBg extends StatelessWidget {
  final List<Color> colors;
  const _GradBg({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _StatusPillLight extends StatelessWidget {
  final HackStatus status;
  const _StatusPillLight({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            status.label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Hackathon hack;
  const _OverviewTab({required this.hack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key dates
          _SCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SCardTitle('Key Dates'),
                const SizedBox(height: 10),
                if (hack.startsAt != null)
                  _DateRow(
                      icon: Icons.play_arrow_rounded,
                      label: 'Starts',
                      date: hack.startsAt!),
                if (hack.submissionDeadline != null)
                  _DateRow(
                      icon: Icons.upload_rounded,
                      label: 'Submission',
                      date: hack.submissionDeadline!),
                if (hack.votingDeadline != null)
                  _DateRow(
                      icon: Icons.how_to_vote_rounded,
                      label: 'Voting ends',
                      date: hack.votingDeadline!),
                if (hack.endsAt != null)
                  _DateRow(
                      icon: Icons.flag_rounded,
                      label: 'Event ends',
                      date: hack.endsAt!,
                      isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Description
          _SCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SCardTitle('About'),
                const SizedBox(height: 8),
                Text(
                  hack.description,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Prizes
          if (hack.prizes != null && hack.prizes!.isNotEmpty) ...[
            _SCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SCardTitle('Prizes 🏆'),
                  const SizedBox(height: 8),
                  Text(
                    hack.prizes!,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Criteria
          if (hack.criteria.isNotEmpty) ...[
            _SCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SCardTitle('Judging Criteria'),
                  const SizedBox(height: 10),
                  ...hack.criteria.map((c) => _CriterionRow(c: c)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Quick actions
          Row(
            children: [
              if (hack.status.showLeaderboard)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.leaderboard_rounded,
                    label: 'Leaderboard',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HackLeaderboardScreen(
                            hackId: hack.id),
                      ),
                    ),
                  ),
                ),
              if (hack.status.showLeaderboard)
                const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.forum_rounded,
                  label: 'Discussion',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DiscussionScreen(hackId: hack.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  final bool isLast;
  const _DateRow(
      {required this.icon,
      required this.label,
      required this.date,
      this.isLast = false});

  static String _fmt(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPast = date.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color:
                  isPast ? AppColors.textTertiary : AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: isPast
                  ? AppColors.textTertiary
                  : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            _fmt(date),
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPast ? AppColors.textTertiary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final HackCriterion c;
  const _CriterionRow({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${c.order}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (c.description != null)
                  Text(
                    c.description!,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '/${c.maxScore}',
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Team tab ──────────────────────────────────────────────────────────────────

class _TeamTab extends StatefulWidget {
  final Hackathon hack;
  const _TeamTab({required this.hack});

  @override
  State<_TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<_TeamTab> {
  final _teamNameCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _creating = false;
  bool _joining = false;

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hack = widget.hack;

    if (hack.hasTeam) {
      return _MyTeamView(hack: hack);
    }

    if (!hack.status.canRegister && !hack.hasTeam) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 44, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                'Registration is ${hack.status == HackStatus.ended ? 'closed' : 'not yet open'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Create team
          _SCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SCardTitle('Create a Team'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teamNameCtrl,
                  maxLength: 60,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Team name',
                    hintStyle: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.group_add_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _creating ? null : () => _createTeam(context),
                    child: _creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'Create Team',
                            style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Join team
          _SCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SCardTitle('Join with Invite Code'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _inviteCtrl,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter invite code',
                    hintStyle: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.vpn_key_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _joining ? null : () => _joinTeam(context),
                    child: _joining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary))
                        : const Text(
                            'Join Team',
                            style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Open teams
          _OpenTeamsSection(hackId: hack.id),
        ],
      ),
    );
  }

  Future<void> _createTeam(BuildContext context) async {
    if (_teamNameCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      final result = await context.read<HackathonProvider>().createTeam(
            widget.hack.id,
            _teamNameCtrl.text.trim(),
          );
      if (context.mounted) {
        _showInviteCode(context, result.inviteCode);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _joinTeam(BuildContext context) async {
    if (_inviteCtrl.text.trim().isEmpty) return;
    setState(() => _joining = true);
    try {
      await context.read<HackathonProvider>().joinTeam(
            widget.hack.id,
            _inviteCtrl.text.trim(),
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _showInviteCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Team Created! 🎉',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with your teammates:',
              style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy_rounded,
                        size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ── My team view ──────────────────────────────────────────────────────────────

class _MyTeamView extends StatelessWidget {
  final Hackathon hack;
  const _MyTeamView({required this.hack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Team name card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.group_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hack.myTeamName ?? 'My Team',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        hack.isLeader ? '👑 Team Leader' : 'Member',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          if (hack.status.canSubmit) ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SubmissionScreen(hackId: hack.id),
                ),
              ),
              icon: const Icon(Icons.upload_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Manage Submission',
                style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (hack.myTeamId != null) ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentorChatScreen(
                    hackId: hack.id,
                    teamId: hack.myTeamId!,
                  ),
                ),
              ),
              icon: const Icon(Icons.school_rounded, size: 18),
              label: const Text(
                'Mentor Chat',
                style: TextStyle(
                    fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Leave
          if (!hack.isLeader)
            TextButton(
              onPressed: () => _confirmLeave(context),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
              child: const Text(
                'Leave Team',
                style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave team?',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: const Text(
            'You will lose your team membership.',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<HackathonProvider>()
                  .leaveTeam(hack.id);
            },
            child: const Text('Leave',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Open teams section ────────────────────────────────────────────────────────

class _OpenTeamsSection extends StatefulWidget {
  final String hackId;
  const _OpenTeamsSection({required this.hackId});

  @override
  State<_OpenTeamsSection> createState() => _OpenTeamsSectionState();
}

class _OpenTeamsSectionState extends State<_OpenTeamsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HackathonProvider>().loadOpenTeams(widget.hackId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HackathonProvider>(
      builder: (_, p, _) {
        if (p.openTeams.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open Teams',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...p.openTeams.map((t) => _OpenTeamTile(
                  team: t,
                  hackId: widget.hackId,
                )),
          ],
        );
      },
    );
  }
}

class _OpenTeamTile extends StatefulWidget {
  final OpenTeam team;
  final String hackId;
  const _OpenTeamTile({required this.team, required this.hackId});

  @override
  State<_OpenTeamTile> createState() => _OpenTeamTileState();
}

class _OpenTeamTileState extends State<_OpenTeamTile> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Led by ${widget.team.leaderName} · ${widget.team.slotsLeft} slot${widget.team.slotsLeft == 1 ? '' : 's'} left',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            width: 64,
            child: ElevatedButton(
              onPressed: _joining
                  ? null
                  : () async {
                      setState(() => _joining = true);
                      try {
                        await context
                            .read<HackathonProvider>()
                            .joinTeam(widget.hackId, widget.team.inviteCode);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } finally {
                        if (mounted) setState(() => _joining = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _joining
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Join',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SCard extends StatelessWidget {
  final Widget child;
  const _SCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _SCardTitle extends StatelessWidget {
  final String text;
  const _SCardTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
}

// ── Phase-gated tab body wrappers ─────────────────────────────────────────────

class _TeamChatTab extends StatelessWidget {
  final String hackId;
  final String teamId;
  const _TeamChatTab({required this.hackId, required this.teamId});

  @override
  Widget build(BuildContext context) =>
      TeamChatScreen(hackId: hackId, teamId: teamId, showAppBar: false);
}

class _SubmissionTab extends StatelessWidget {
  final String hackId;
  const _SubmissionTab({required this.hackId});

  @override
  Widget build(BuildContext context) =>
      SubmissionScreen(hackId: hackId, showAppBar: false);
}

class _DiscussionTab extends StatelessWidget {
  final String hackId;
  const _DiscussionTab({required this.hackId});

  @override
  Widget build(BuildContext context) =>
      DiscussionScreen(hackId: hackId, showAppBar: false);
}

class _LeaderboardTab extends StatelessWidget {
  final String hackId;
  final bool voteMode;
  const _LeaderboardTab({required this.hackId, required this.voteMode});

  @override
  Widget build(BuildContext context) =>
      HackLeaderboardScreen(hackId: hackId, showAppBar: false);
}
