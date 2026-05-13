import 'package:flutter/material.dart';
import 'package:reelscholar/providers/app_colors.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          _SearchBar(
            ctrl: _searchCtrl,
            onChanged: (q) => setState(() => _searchQuery = q),
          ),

          // ── Tab bar ───────────────────────────────────────────────────
          _TabBar(ctrl: _tabCtrl),

          const Divider(color: AppColors.border, height: 1),

          // ── Tab views ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _GroupsTab(searchQuery: _searchQuery),
                _MessagesTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _ComposeFAB(
        tabIndex: _tabCtrl.index,
        onTap: () => _compose(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: const Text(
        'Chats',
        style: TextStyle(
          fontFamily: AppFonts.sora,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(
            Icons.edit_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          onPressed: _compose,
        ),
      ],
    );
  }

  void _compose() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComposeSheet(isGroup: _tabCtrl.index == 0),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: ctrl,
                onChanged: onChanged,
                style: const TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search conversations…',
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  ctrl.clear();
                  onChanged('');
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController ctrl;

  const _TabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: ctrl,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(
        fontFamily: AppFonts.sora,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: AppFonts.dmSans,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textTertiary,
      tabs: const [
        Tab(text: 'Study Groups'),
        Tab(text: 'Messages'),
      ],
    );
  }
}

// ─── Study Groups tab ─────────────────────────────────────────────────────────
class _GroupsTab extends StatelessWidget {
  final String searchQuery;

  const _GroupsTab({required this.searchQuery});

  static const _groups = [
    _ConvItem(
      id: '1',
      name: 'Physics Revision Squad',
      subtitle: 'Priya: See you at 6pm in the lab',
      timeLabel: '15m',
      unread: 0,
      isGroup: true,
      isOnline: false,
      avatarColor: Color(0xFF6366F1),
      initial: 'P',
    ),
    _ConvItem(
      id: '2',
      name: 'Calculus Study Crew',
      subtitle: 'James: Chapter 7 solutions uploaded',
      timeLabel: '2h',
      unread: 5,
      isGroup: true,
      isOnline: false,
      avatarColor: Color(0xFFF59E0B),
      initial: 'C',
    ),
    _ConvItem(
      id: '3',
      name: 'Data Structures Masters',
      subtitle: 'You: Does anyone have the past paper?',
      timeLabel: 'Wed',
      unread: 0,
      isGroup: true,
      isOnline: false,
      avatarColor: Color(0xFF0D9488),
      initial: 'D',
    ),
    _ConvItem(
      id: '4',
      name: 'Engineering Hackathon Team',
      subtitle: 'Amara: Submission due tomorrow!',
      timeLabel: 'Mon',
      unread: 12,
      isGroup: true,
      isOnline: false,
      avatarColor: Color(0xFFEF4444),
      initial: 'E',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = searchQuery.isEmpty
        ? _groups
        : _groups
              .where(
                (g) => g.name.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        icon: Icons.group_outlined,
        title: searchQuery.isNotEmpty
            ? 'No groups found'
            : 'No study groups yet',
        subtitle: searchQuery.isNotEmpty
            ? 'No groups matching "$searchQuery"'
            : 'Join or create a study group to collaborate',
        actionLabel: 'Browse Groups',
        onAction: () => Navigator.pushNamed(context, '/study-groups'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => _ConversationTile(
        item: filtered[i],
        onTap: () => Navigator.pushNamed(
          context,
          '/conversation',
          arguments: filtered[i].id,
        ),
      ),
    );
  }
}

// ─── Direct Messages tab ──────────────────────────────────────────────────────
class _MessagesTab extends StatelessWidget {
  final String searchQuery;

  const _MessagesTab({required this.searchQuery});

  static const _messages = [
    _ConvItem(
      id: '10',
      name: 'David Chen',
      subtitle: 'Did you get the notes for today?',
      timeLabel: '2m',
      unread: 3,
      isGroup: false,
      isOnline: true,
      avatarColor: Color(0xFF0D9488),
      initial: 'D',
    ),
    _ConvItem(
      id: '11',
      name: 'Dr. Sarah Williams',
      subtitle: 'Great submission! Keep it up 👏',
      timeLabel: '1h',
      unread: 0,
      isGroup: false,
      isOnline: false,
      avatarColor: Color(0xFF6366F1),
      initial: 'S',
    ),
    _ConvItem(
      id: '12',
      name: 'Priya Nair',
      subtitle: 'Are you joining the revision session?',
      timeLabel: 'Tue',
      unread: 1,
      isGroup: false,
      isOnline: true,
      avatarColor: Color(0xFFF59E0B),
      initial: 'P',
    ),
    _ConvItem(
      id: '13',
      name: 'James Mutasa',
      subtitle: 'Thanks for sharing those notes 🙏',
      timeLabel: 'Mon',
      unread: 0,
      isGroup: false,
      isOnline: false,
      avatarColor: Color(0xFF22C55E),
      initial: 'J',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = searchQuery.isEmpty
        ? _messages
        : _messages
              .where(
                (m) => m.name.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: searchQuery.isNotEmpty ? 'No messages found' : 'No messages yet',
        subtitle: searchQuery.isNotEmpty
            ? 'No conversations matching "$searchQuery"'
            : 'Message a classmate to start a conversation',
        actionLabel: 'Find People',
        onAction: () => Navigator.pushNamed(context, '/search-users'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => _ConversationTile(
        item: filtered[i],
        onTap: () => Navigator.pushNamed(
          context,
          '/conversation',
          arguments: filtered[i].id,
        ),
      ),
    );
  }
}

// ─── Conversation tile ────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final _ConvItem item;
  final VoidCallback onTap;

  const _ConversationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: item.unread > 0
              ? AppColors.primarySubtle.withValues(alpha: 0.3)
              : AppColors.white,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online dot / group badge
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.initial,
                      style: const TextStyle(
                        fontFamily: AppFonts.sora,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Online dot (DMs only)
                if (!item.isGroup && item.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                // Group badge
                if (item.isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontFamily: AppFonts.sora,
                            fontSize: 14,
                            fontWeight: item.unread > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.timeLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.dmSans,
                          fontSize: 11,
                          color: item.unread > 0
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontWeight: item.unread > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.subtitle,
                          style: TextStyle(
                            fontFamily: AppFonts.dmSans,
                            fontSize: 13,
                            color: item.unread > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: item.unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              item.unread > 99 ? '99+' : '${item.unread}',
                              style: const TextStyle(
                                fontFamily: AppFonts.dmSans,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

// ─── Compose FAB ──────────────────────────────────────────────────────────────
class _ComposeFAB extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onTap;

  const _ComposeFAB({required this.tabIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(
        tabIndex == 0 ? Icons.group_add_rounded : Icons.edit_rounded,
        size: 20,
      ),
      label: Text(
        tabIndex == 0 ? 'New Group' : 'New Message',
        style: const TextStyle(
          fontFamily: AppFonts.dmSans,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Compose sheet ────────────────────────────────────────────────────────────
class _ComposeSheet extends StatelessWidget {
  final bool isGroup;

  const _ComposeSheet({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  isGroup ? 'Create Study Group' : 'New Message',
                  style: const TextStyle(
                    fontFamily: AppFonts.sora,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isGroup
                        ? 'Search classmates to add…'
                        : 'Search for a person…',
                    style: const TextStyle(
                      fontFamily: AppFonts.dmSans,
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SUGGESTED',
                style: TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.08,
                ),
              ),
            ),
          ),
          // Placeholder suggestions
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.warning,
                  ][i],
                  child: Text(
                    ['D', 'P', 'J'][i],
                    style: const TextStyle(
                      fontFamily: AppFonts.sora,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  ['David Chen', 'Priya Nair', 'James Mutasa'][i],
                  style: const TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  [
                    'Engineering · Year 3',
                    'Sciences · Year 2',
                    'CS · Year 4',
                  ][i],
                  style: const TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────
class _ConvItem {
  final String id;
  final String name;
  final String subtitle;
  final String timeLabel;
  final int unread;
  final bool isGroup;
  final bool isOnline;
  final Color avatarColor;
  final String initial;

  const _ConvItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.timeLabel,
    required this.unread,
    required this.isGroup,
    required this.isOnline,
    required this.avatarColor,
    required this.initial,
  });
}
