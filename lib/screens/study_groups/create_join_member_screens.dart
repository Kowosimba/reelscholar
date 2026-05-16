// lib/features/study_groups/screens/create_study_group_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/core/services/social_service.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/providers/study_group_provider.dart';
import 'package:reelscholar/models/study_group_models.dart';
import 'study_group_detail_screen.dart';

class CreateStudyGroupScreen extends StatefulWidget {
  /// Pass [group] to enter edit mode.
  final StudyGroup? group;

  const CreateStudyGroupScreen({super.key, this.group});

  @override
  State<CreateStudyGroupScreen> createState() =>
      _CreateStudyGroupScreenState();
}

class _CreateStudyGroupScreenState extends State<CreateStudyGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _subjectCtrl;

  late bool _isPublic;
  late bool _adminOnly;
  bool _isLoading = false;

  bool get _isEditMode => widget.group != null;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _subjectCtrl = TextEditingController(text: g?.subject ?? '');
    _isPublic = g?.isPublic ?? true;
    _adminOnly = g?.adminOnlyMessaging ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final p = context.read<StudyGroupProvider>();
      if (_isEditMode) {
        await p.updateGroup(
          widget.group!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          subject: _subjectCtrl.text.trim(),
          isPublic: _isPublic,
          adminOnlyMessaging: _adminOnly,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Group updated!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pop(context);
        }
      } else {
        final group = await p.createGroup(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          subject: _subjectCtrl.text.trim().isEmpty
              ? null
              : _subjectCtrl.text.trim(),
          isPublic: _isPublic,
          adminOnlyMessaging: _adminOnly,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudyGroupDetailScreen(groupId: group.id),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(
          _isEditMode ? 'Edit Group' : 'Create Group',
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon
                if (!_isEditMode) ...[
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.group_add_rounded,
                          size: 36, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Create a Study Group',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Up to 15 members · invite or request-based',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Name
                _FieldLabel('Group Name', required: true),
                TextFormField(
                  controller: _nameCtrl,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Physics Revision Squad',
                    prefixIcon:
                        Icon(Icons.group_rounded, size: 20),
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Subject
                _FieldLabel('Subject / Topic'),
                TextFormField(
                  controller: _subjectCtrl,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: 'e.g. PHY101 · Forces & Motion',
                    prefixIcon:
                        Icon(Icons.book_outlined, size: 20),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _FieldLabel('Description'),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText:
                        'What will your group focus on? (optional)',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_rounded, size: 20),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Settings card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _ToggleRow(
                        icon: Icons.public_rounded,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.primarySubtle,
                        title: 'Public Group',
                        subtitle: _isPublic
                            ? 'Anyone can discover and request to join'
                            : 'Only invited members can join',
                        value: _isPublic,
                        onChanged: (v) =>
                            setState(() => _isPublic = v),
                      ),
                      const Divider(height: 20),
                      _ToggleRow(
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: const Color(0xFF6366F1),
                        iconBg: const Color(0xFFEDE9FE),
                        title: 'Admin-only Messaging',
                        subtitle: 'Only admins can send messages',
                        value: _adminOnly,
                        onChanged: (v) =>
                            setState(() => _adminOnly = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(
                            _isEditMode
                                ? 'Save Changes'
                                : 'Create Group',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
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

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.textSecondary,
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
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// Join Requests Screen (admin only)
// ════════════════════════════════════════════════════════════════════════════

class JoinRequestsScreen extends StatefulWidget {
  final String groupId;
  const JoinRequestsScreen({super.key, required this.groupId});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyGroupProvider>().loadJoinRequests(widget.groupId);
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
          'Join Requests',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: () => context
                .read<StudyGroupProvider>()
                .loadJoinRequests(widget.groupId),
          ),
        ],
      ),
      body: Consumer<StudyGroupProvider>(
        builder: (_, p, _) {
          if (p.requestsLoading && p.joinRequests.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (p.joinRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.how_to_reg_rounded,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  const Text('No pending requests',
                      style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text(
                      'New join requests will appear here.',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => p.loadJoinRequests(widget.groupId),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.joinRequests.length,
              itemBuilder: (_, i) => _JoinRequestTile(
                request: p.joinRequests[i],
                onApprove: () => p.approveRequest(
                    widget.groupId, p.joinRequests[i].id),
                onReject: () => p.rejectRequest(
                    widget.groupId, p.joinRequests[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JoinRequestTile extends StatelessWidget {
  final JoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestTile({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final hue =
        request.userName.codeUnits.fold(0, (a, b) => a + b) % 360;
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    HSLColor.fromAHSL(
                            1, hue.toDouble(), 0.6, 0.4)
                        .toColor(),
                    HSLColor.fromAHSL(
                            1, (hue + 40.0) % 360, 0.7, 0.3)
                        .toColor(),
                  ]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    request.initials,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _timeAgo(request.createdAt),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
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
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Approve',
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
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Reject',
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}


// ════════════════════════════════════════════════════════════════════════════
// Member Management Screen (admin only)
// ════════════════════════════════════════════════════════════════════════════

class MemberManagementScreen extends StatefulWidget {
  final String groupId;
  const MemberManagementScreen({super.key, required this.groupId});

  @override
  State<MemberManagementScreen> createState() =>
      _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyGroupProvider>().loadMembers(widget.groupId);
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
          'Members',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: Consumer<StudyGroupProvider>(
        builder: (_, p, _) {
          final group = p.activeGroup;
          if (group == null || !group.isAdmin) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: group.isFull
                ? null
                : () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _AddMemberSheet(
                        groupId: widget.groupId,
                        currentMemberIds:
                            p.members.map((m) => m.id).toSet(),
                        memberCount: group.memberCount,
                        capacity: group.capacity,
                      ),
                    ),
            backgroundColor:
                group.isFull ? AppColors.border : AppColors.primary,
            icon: const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 18),
            label: Text(
              group.isFull ? 'Group Full' : 'Add Member',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
      body: Consumer<StudyGroupProvider>(
        builder: (_, p, _) {
          if (p.membersLoading && p.members.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final activeGroup = p.activeGroup;
          final isCreator = activeGroup?.isCreator ?? false;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: p.members.length,
            itemBuilder: (_, i) {
              final m = p.members[i];
              return _MemberManageTile(
                member: m,
                isCreator: isCreator,
                groupId: widget.groupId,
              );
            },
          );
        },
      ),
    );
  }
}

class _MemberManageTile extends StatelessWidget {
  final GroupMember member;
  final bool isCreator;
  final String groupId;

  const _MemberManageTile({
    required this.member,
    required this.isCreator,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final hue = member.name.codeUnits.fold(0, (a, b) => a + b) % 360;
    final p = context.read<StudyGroupProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (member.isAdmin)
                  Text(
                    member.isCreator ? '👑 Creator' : '⚡ Admin',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: member.isCreator
                          ? const Color(0xFF92400E)
                          : AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          // Only show actions for non-creator members
          if (!member.isCreator)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  size: 18, color: AppColors.textSecondary),
              onSelected: (val) async {
                switch (val) {
                  case 'promote':
                    await p.promoteMember(groupId, member.id);
                    break;
                  case 'demote':
                    await p.demoteMember(groupId, member.id);
                    break;
                  case 'remove':
                    await p.removeMember(groupId, member.id);
                    break;
                }
              },
              itemBuilder: (_) => [
                if (isCreator && !member.isAdmin)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Row(children: [
                      Icon(Icons.arrow_upward_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Promote to Admin',
                          style: TextStyle(fontFamily: 'DM Sans')),
                    ]),
                  ),
                if (isCreator && member.isAdmin)
                  const PopupMenuItem(
                    value: 'demote',
                    child: Row(children: [
                      Icon(Icons.arrow_downward_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Demote to Member',
                          style: TextStyle(fontFamily: 'DM Sans')),
                    ]),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(children: [
                    Icon(Icons.person_remove_rounded,
                        size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Remove',
                        style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: AppColors.error)),
                  ]),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Add Member Sheet (admin only)
// ════════════════════════════════════════════════════════════════════════════

class _AddMemberSheet extends StatefulWidget {
  final String groupId;
  final Set<String> currentMemberIds;
  final int memberCount;
  final int capacity;

  const _AddMemberSheet({
    required this.groupId,
    required this.currentMemberIds,
    required this.memberCount,
    required this.capacity,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _service = SocialService();
  Timer? _debounce;

  List<AppUser> _results = [];
  bool _searching = false;
  String? _searchError;
  final Set<String> _adding = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final res = await _service.searchUsers(query: q, perPage: 20);
      if (mounted) {
        setState(() {
          _results = res.users
              .where((u) => !widget.currentMemberIds.contains(u.uid))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _add(AppUser user) async {
    setState(() => _adding.add(user.uid));
    try {
      await context
          .read<StudyGroupProvider>()
          .addMember(widget.groupId, user.uid);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _adding.remove(user.uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1E293B) : AppColors.border;
    final handleColor = isDark ? const Color(0xFF334155) : AppColors.border;
    final remaining = widget.capacity - widget.memberCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Add Member',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: remaining <= 2
                          ? const Color(0xFFFEF3C7)
                          : AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.memberCount}/${widget.capacity}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: remaining <= 2
                            ? const Color(0xFF92400E)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search field — uses global InputDecorationTheme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or student ID…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Results / states
            Expanded(
              child: Builder(builder: (_) {
                if (_searchError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            _searchError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_results.isEmpty) {
                  return Center(
                    child: Text(
                      _searchCtrl.text.trim().length < 2
                          ? 'Type at least 2 characters to search'
                          : 'No users found',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final user = _results[i];
                    final hue =
                        user.fullName.codeUnits.fold(0, (a, b) => a + b) % 360;
                    final isAdding = _adding.contains(user.uid);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.4)
                                    .toColor(),
                                HSLColor.fromAHSL(
                                        1, (hue + 40.0) % 360, 0.7, 0.3)
                                    .toColor(),
                              ]),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (user.studentId != null)
                                  Text(
                                    user.studentId!,
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: isAdding ? null : () => _add(user),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isAdding
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text(
                                      'Add',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }
}
