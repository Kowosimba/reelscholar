// lib/features/study_groups/screens/study_groups_screen.dart
// Main entry: tabbed Browse / My Groups / Requests (invites)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/study_group_provider.dart';
import 'package:reelscholar/models/study_group_models.dart';
import 'package:reelscholar/screens/messaging/chat_thread_screen.dart';
import 'study_group_detail_screen.dart';
import 'create_join_member_screens.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<StudyGroupProvider>();
      p.browseGroups(refresh: true);
      p.loadMyGroups();
      p.loadMyInvites();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Study Groups',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateStudyGroupScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.primary,
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
          tabs: [
            const Tab(text: 'Discover'),
            const Tab(text: 'My Groups'),
            Consumer<StudyGroupProvider>(
              builder: (_, p, _) {
                final count = p.pendingInviteCount;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Invites'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DiscoverTab(),
          _MyGroupsTab(),
          _InvitesTab(),
        ],
      ),
    );
  }
}

// ── Discover tab ──────────────────────────────────────────────────────────────

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<StudyGroupProvider>().loadMoreGroups();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        context.read<StudyGroupProvider>().setSearch(v),
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search groups by subject…',
                      hintStyle: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Consumer<StudyGroupProvider>(
            builder: (_, p, _) {
              if (p.browseLoading && p.publicGroups.isEmpty) {
                return const _GroupsShimmer();
              }
              if (p.browseError != null && p.publicGroups.isEmpty) {
                return _ErrorState(
                  message: p.browseError!,
                  onRetry: () => p.browseGroups(refresh: true),
                );
              }
              if (p.publicGroups.isEmpty) {
                return const _EmptyDiscover();
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => p.browseGroups(refresh: true),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(14),
                  itemCount: p.publicGroups.length +
                      (p.browseLoadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == p.publicGroups.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
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
                    return _GroupCard(
                      group: p.publicGroups[i],
                      onTap: () => _openGroup(context, p.publicGroups[i]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openGroup(BuildContext ctx, StudyGroup g) {
    if (g.isMember) {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(groupId: g.id, groupName: g.name),
        ),
      );
    } else {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => StudyGroupDetailScreen(groupId: g.id),
        ),
      );
    }
  }
}

// ── My groups tab ─────────────────────────────────────────────────────────────

class _MyGroupsTab extends StatelessWidget {
  const _MyGroupsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyGroupProvider>(
      builder: (_, p, _) {
        if (p.myLoading && p.myGroups.isEmpty) {
          return const _GroupsShimmer();
        }
        if (p.myError != null && p.myGroups.isEmpty) {
          return _ErrorState(
            message: p.myError!,
            onRetry: () => p.loadMyGroups(refresh: true),
          );
        }
        if (p.myGroups.isEmpty) {
          return const _EmptyMyGroups();
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => p.loadMyGroups(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: p.myGroups.length,
            itemBuilder: (_, i) => _GroupCard(
              group: p.myGroups[i],
              showRole: true,
              onTap: () {
                final g = p.myGroups[i];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(
                      groupId: g.id,
                      groupName: g.name,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Invites tab ───────────────────────────────────────────────────────────────

class _InvitesTab extends StatelessWidget {
  const _InvitesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyGroupProvider>(
      builder: (_, p, _) {
        if (p.invitesLoading && p.myInvites.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (p.myInvites.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline_rounded,
                      size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No pending invites',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'When someone invites you to a group,\nyou\'ll see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: p.myInvites.length,
          itemBuilder: (_, i) => _InviteTile(
            invite: p.myInvites[i],
            onAccept: () async {
              try {
                await p.acceptInvite(p.myInvites[i].token);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joined the group!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            onDecline: () => p.declineInvite(p.myInvites[i].token),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Group card component
// ════════════════════════════════════════════════════════════════════════════

class _GroupCard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback onTap;
  final bool showRole;

  const _GroupCard({
    required this.group,
    required this.onTap,
    this.showRole = false,
  });

  // Accent colour rotates by group name hash — matches wireframe's coloured left borders
  Color get _accent {
    final colors = [
      AppColors.primary,
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF22C55E),
    ];
    final idx = group.name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Coloured left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + privacy badge row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (group.subject != null)
                                  Text(
                                    group.subject!,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PrivacyBadge(isPublic: group.isPublic),
                        ],
                      ),

                      if (group.description != null &&
                          group.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          group.description!,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Footer: member stack + count + action
                      Row(
                        children: [
                          // Avatar stack
                          _AvatarStack(count: group.memberCount),
                          const SizedBox(width: 8),
                          Text(
                            '${group.memberCount}/${group.capacity}',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (!group.isFull) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Active',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (showRole && group.role != null)
                            _RoleBadge(role: group.role!)
                          else if (!group.isMember)
                            _JoinButton(group: group),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  final bool isPublic;
  const _PrivacyBadge({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPublic
            ? AppColors.primarySubtle
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPublic ? 'PUBLIC' : 'PRIVATE',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isPublic ? AppColors.primary : const Color(0xFF92400E),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'creator' || role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.primarySubtle : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role == 'creator' ? '👑 Creator' : role == 'admin' ? '⚡ Admin' : 'Member',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isAdmin ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _JoinButton extends StatefulWidget {
  final StudyGroup group;
  const _JoinButton({required this.group});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.group.isPublic ? 'Join' : 'Request';
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await context
                      .read<StudyGroupProvider>()
                      .requestToJoin(widget.group.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.group.isPublic
                            ? 'Joined!'
                            : 'Request sent!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            e.toString().replaceFirst('Exception: ', '')),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final show = count.clamp(0, 4);
    final colors = [
      const Color(0xFF22C55E),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
    ];
    return SizedBox(
      width: 20.0 + (show - 1) * 14.0,
      height: 20,
      child: Stack(
        children: List.generate(
          show,
          (i) => Positioned(
            left: i * 14.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Invite tile ───────────────────────────────────────────────────────────────

class _InviteTile extends StatelessWidget {
  final GroupInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InviteTile({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.studyGroupName ?? 'Study Group',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (invite.invitedByName != null)
                      Text(
                        'Invited by ${invite.invitedByName}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
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

// ── Empty + error + shimmer ───────────────────────────────────────────────────

class _EmptyDiscover extends StatelessWidget {
  const _EmptyDiscover();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.border),
            SizedBox(height: 12),
            Text('No groups found',
                style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            SizedBox(height: 6),
            Text('Try a different search term',
                style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textTertiary)),
          ],
        ),
      );
}

class _EmptyMyGroups extends StatelessWidget {
  const _EmptyMyGroups();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.primarySubtle, shape: BoxShape.circle),
              child: const Icon(Icons.group_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text('No groups yet',
                style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text(
                'Join a group from Discover\nor create your own',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateStudyGroupScreen()),
              ),
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: Colors.white),
              label: const Text('Create Group',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _GroupsShimmer extends StatelessWidget {
  const _GroupsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}

