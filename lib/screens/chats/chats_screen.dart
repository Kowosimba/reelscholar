import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/messaging_models.dart';
import 'package:reelscholar/providers/messaging_provider.dart';
import 'package:reelscholar/screens/messaging/chat_thread_screen.dart';
import 'package:reelscholar/screens/messaging/message_requests_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = context.read<MessagingProvider>();
      m.loadConversations(refresh: true);
      m.loadRequests();
    });
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
          _SearchBar(
            ctrl: _searchCtrl,
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          _TabBar(ctrl: _tabCtrl),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ChatsListTab(
                  searchQuery: _searchQuery,
                  filter: (c) => c.isGroup,
                  emptyTitle: 'No study groups yet',
                  emptySubtitle: 'Join or create a study group to collaborate',
                ),
                _ChatsListTab(
                  searchQuery: _searchQuery,
                  filter: (c) => c.isDirect,
                  emptyTitle: 'No messages yet',
                  emptySubtitle: 'Message a classmate to start a conversation',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _ComposeFAB(
        tabIndex: _tabCtrl.index,
        onTap: _compose,
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
        Consumer<MessagingProvider>(
          builder: (_, p, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.inbox_outlined,
                    color: AppColors.textSecondary, size: 22),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const MessageRequestsScreen(),
                  ),
                ),
              ),
              if (p.pendingRequestCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${p.pendingRequestCount > 9 ? '9+' : p.pendingRequestCount}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComposeSheet(isGroup: _tabCtrl.index == 0),
    );
  }
}

class _ChatsListTab extends StatelessWidget {
  final String searchQuery;
  final bool Function(Conversation c) filter;
  final String emptyTitle;
  final String emptySubtitle;

  const _ChatsListTab({
    required this.searchQuery,
    required this.filter,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingProvider>(
      builder: (_, p, _) {
        if (p.convsLoading && p.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (p.convsError != null && p.conversations.isEmpty) {
          return _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load chats',
            subtitle: p.convsError!,
            actionLabel: 'Retry',
            onAction: () => p.loadConversations(refresh: true),
          );
        }
        var list = p.conversations.where(filter).toList();
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          list = list
              .where((c) => c.displayName.toLowerCase().contains(q))
              .toList();
        }
        if (list.isEmpty) {
          return _EmptyState(
            icon: _tabIcon(),
            title: searchQuery.isNotEmpty ? 'No results' : emptyTitle,
            subtitle: searchQuery.isNotEmpty
                ? 'Nothing matches "$searchQuery"'
                : emptySubtitle,
            actionLabel: searchQuery.isEmpty ? 'Refresh' : null,
            onAction: searchQuery.isEmpty
                ? () => p.loadConversations(refresh: true)
                : null,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => p.loadConversations(refresh: true),
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return _ConversationTile(
                conv: c,
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChatThreadScreen(conversationId: c.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _tabIcon() =>
      emptyTitle.contains('group')
          ? Icons.group_outlined
          : Icons.chat_bubble_outline_rounded;
}

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
          ],
        ),
      ),
    );
  }
}

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

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  String _timeLabel() {
    final dt = conv.lastMessageAt;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = conv.unreadCount;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: unread > 0
              ? AppColors.primarySubtle.withValues(alpha: 0.35)
              : AppColors.white,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _avatarGradient(conv.displayName),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: conv.avatarUrl != null &&
                            conv.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              conv.avatarUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            conv.displayInitials,
                            style: const TextStyle(
                              fontFamily: AppFonts.sora,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                if (conv.isGroup)
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.displayName,
                          style: TextStyle(
                            fontFamily: AppFonts.sora,
                            fontSize: 14,
                            fontWeight: unread > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeLabel(),
                        style: TextStyle(
                          fontFamily: AppFonts.dmSans,
                          fontSize: 11,
                          color: unread > 0
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (conv.isMuted)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.volume_off_rounded,
                              size: 12, color: AppColors.textTertiary),
                        ),
                      Expanded(
                        child: Text(
                          conv.lastMessagePreview ?? '',
                          style: TextStyle(
                            fontFamily: AppFonts.dmSans,
                            fontSize: 13,
                            color: unread > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0) ...[
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
                              unread > 99 ? '99+' : '$unread',
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

  static LinearGradient _avatarGradient(String name) {
    final h = name.codeUnits.fold<int>(0, (a, b) => a + b) % 360;
    return LinearGradient(
      colors: [
        HSLColor.fromAHSL(1, h.toDouble(), 0.6, 0.4).toColor(),
        HSLColor.fromAHSL(1, (h + 40).toDouble() % 360, 0.7, 0.3).toColor(),
      ],
    );
  }
}

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

class _ComposeSheet extends StatelessWidget {
  final bool isGroup;

  const _ComposeSheet({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_search_rounded,
                color: AppColors.primary),
            title: const Text(
              'Find people',
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              isGroup
                  ? 'Add members from search (coming soon)'
                  : 'Search users to send a message request',
              style: const TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Use search from your profile area to find people. Message requests open from the inbox icon.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
