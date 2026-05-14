// lib/features/study_groups/screens/study_group_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/study_group_provider.dart';
import 'package:reelscholar/models/study_group_models.dart';
import 'create_join_member_screens.dart';

class StudyGroupDetailScreen extends StatefulWidget {
  final String groupId;

  const StudyGroupDetailScreen({super.key, required this.groupId});

  @override
  State<StudyGroupDetailScreen> createState() =>
      _StudyGroupDetailScreenState();
}

class _StudyGroupDetailScreenState extends State<StudyGroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<StudyGroupProvider>();
      p.loadGroup(widget.groupId);
      p.loadMembers(widget.groupId);
    });
  }

  @override
  void dispose() {
    context.read<StudyGroupProvider>().clearActiveGroup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyGroupProvider>(
      builder: (_, p, _) {
        if (p.groupLoading && p.activeGroup == null) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (p.groupError != null && p.activeGroup == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: Center(
              child: Text(p.groupError!,
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.textSecondary)),
            ),
          );
        }
        final group = p.activeGroup;
        if (group == null) return const Scaffold(body: SizedBox.shrink());

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              _GroupSliverAppBar(group: group),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats row
                    _StatsRow(group: group),
                    const SizedBox(height: 16),

                    // Description
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              group.description!,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Members preview
                    _MembersPreview(
                      members: p.members,
                      loading: p.membersLoading,
                      isAdmin: group.isAdmin,
                      groupId: group.id,
                    ),
                    const SizedBox(height: 12),

                    // Admin tools
                    if (group.isAdmin) ...[
                      _AdminTools(group: group),
                      const SizedBox(height: 12),
                    ],

                    // Settings info
                    _SectionCard(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.lock_outline_rounded,
                            label: 'Visibility',
                            value: group.isPublic ? 'Public' : 'Private',
                          ),
                          _InfoRow(
                            icon: Icons.chat_outlined,
                            label: 'Messaging',
                            value: group.adminOnlyMessaging
                                ? 'Admins only'
                                : 'All members',
                          ),
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Created by',
                            value: group.createdBy?.name ?? '—',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Leave / Join
                    if (group.isMember && !group.isCreator)
                      _LeaveButton(groupId: group.id)
                    else if (!group.isMember)
                      _JoinRequestButton(group: group),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sliver app bar ────────────────────────────────────────────────────────────

class _GroupSliverAppBar extends StatelessWidget {
  final StudyGroup group;
  const _GroupSliverAppBar({required this.group});

  Color get _accent {
    final colors = [
      AppColors.primary, const Color(0xFF6366F1),
      const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF22C55E),
    ];
    return colors[group.name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      expandedHeight: 130,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (group.isAdmin)
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateStudyGroupScreen(group: group),
              ),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary),
          onSelected: (_) {},
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'share', child: Text('Share Group')),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: _accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (group.subject != null)
              Text(
                group.subject!,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final StudyGroup group;
  const _StatsRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.people_rounded,
          label: '${group.memberCount}/${group.capacity}',
          sub: 'Members',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: group.isPublic
              ? Icons.public_rounded
              : Icons.lock_rounded,
          label: group.isPublic ? 'Public' : 'Private',
          sub: 'Visibility',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: group.isFull
              ? Icons.block_rounded
              : Icons.check_circle_rounded,
          label: group.isFull ? 'Full' : 'Open',
          sub: 'Status',
          valueColor: group.isFull ? AppColors.error : AppColors.success,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color valueColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sub,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: valueColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            Text(
              sub,
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

// ── Members preview ───────────────────────────────────────────────────────────

class _MembersPreview extends StatelessWidget {
  final List<GroupMember> members;
  final bool loading;
  final bool isAdmin;
  final String groupId;

  const _MembersPreview({
    required this.members,
    required this.loading,
    required this.isAdmin,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isAdmin)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MemberManagementScreen(groupId: groupId),
                    ),
                  ),
                  child: const Text(
                    'Manage →',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else
            ...members.take(5).map((m) => _MemberRow(member: m)),
          if (members.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${members.length - 5} more members',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final GroupMember member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final hue = member.name.codeUnits.fold(0, (a, b) => a + b) % 360;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.4).toColor(),
                HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.7, 0.3).toColor(),
              ]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.initials,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (member.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: member.isCreator
                    ? const Color(0xFFFEF3C7)
                    : AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.isCreator ? '👑' : '⚡ Admin',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: member.isCreator
                      ? const Color(0xFF92400E)
                      : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Admin tools ───────────────────────────────────────────────────────────────

class _AdminTools extends StatelessWidget {
  final StudyGroup group;
  const _AdminTools({required this.group});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Tools',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _AdminToolRow(
            icon: Icons.how_to_reg_rounded,
            label: 'Join Requests',
            iconBg: AppColors.primarySubtle,
            iconColor: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    JoinRequestsScreen(groupId: group.id),
              ),
            ),
          ),
          _AdminToolRow(
            icon: Icons.group_add_rounded,
            label: 'Member Management',
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF6366F1),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MemberManagementScreen(groupId: group.id),
              ),
            ),
          ),
          if (group.isCreator)
            _AdminToolRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Group',
              iconBg: const Color(0xFFFEE2E2),
              iconColor: AppColors.error,
              onTap: () => _confirmDelete(context),
              isLast: true,
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Group?',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: Text(
          'This will permanently delete "${group.name}" and remove all members.',
          style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<StudyGroupProvider>().deleteGroup(group.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AdminToolRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLast;

  const _AdminToolRow({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
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

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leave / Join buttons ──────────────────────────────────────────────────────

class _LeaveButton extends StatefulWidget {
  final String groupId;
  const _LeaveButton({required this.groupId});

  @override
  State<_LeaveButton> createState() => _LeaveButtonState();
}

class _LeaveButtonState extends State<_LeaveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _loading ? null : _leave,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.error))
            : const Text(
                'Leave Group',
                style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _leave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave group?',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: const Text('You can rejoin later if the group is public.',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await context
          .read<StudyGroupProvider>()
          .leaveGroup(widget.groupId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _JoinRequestButton extends StatefulWidget {
  final StudyGroup group;
  const _JoinRequestButton({required this.group});

  @override
  State<_JoinRequestButton> createState() => _JoinRequestButtonState();
}

class _JoinRequestButtonState extends State<_JoinRequestButton> {
  bool _loading = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '✅ Request sent!',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF166534),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : _request,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                widget.group.isPublic ? 'Join Group' : 'Request to Join',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    try {
      await context
          .read<StudyGroupProvider>()
          .requestToJoin(widget.group.id);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Shared card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
