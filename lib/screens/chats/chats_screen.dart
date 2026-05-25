import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/messaging_models.dart';
import 'package:reelscholar/providers/messaging_provider.dart';
import 'package:reelscholar/screens/chats/chat_user_search_screen.dart';
import 'package:reelscholar/screens/messaging/chat_thread_screen.dart';
import 'package:reelscholar/screens/messaging/message_requests_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showGroups = false;

  void _switchTab(bool groups) {
    if (_showGroups == groups) return;
    setState(() => _showGroups = groups);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = context.read<MessagingProvider>();
      m.loadConversations(refresh: true);
      m.loadGroupConversations();
      m.loadRequests();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _SearchBar(
            ctrl: _searchCtrl,
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openPeopleSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_search_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Find people to follow or message',
                              style: TextStyle(
                                fontFamily: AppFonts.dmSans,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Direct / Groups tab strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _TabChip(
                  label: 'Direct',
                  selected: !_showGroups,
                  onTap: () => _switchTab(false),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: 'Study Groups',
                  selected: _showGroups,
                  onTap: () => _switchTab(true),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (_, p, _) {
                final loading = _showGroups ? p.groupConvsLoading : p.convsLoading;
                final allConvs = p.conversations;
                if (loading && allConvs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (p.convsError != null && allConvs.isEmpty) {
                  return _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load messages',
                    subtitle: p.convsError!,
                    actionLabel: 'Retry',
                    onAction: () => p.loadConversations(refresh: true),
                  );
                }
                var list = _showGroups
                    ? allConvs.where((c) => c.studyGroupId != null).toList()
                    : allConvs.where((c) => c.isDirect).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  list = list
                      .where((c) => c.displayName.toLowerCase().contains(q))
                      .toList();
                }
                if (list.isEmpty) {
                  return _EmptyState(
                    icon: _showGroups
                        ? Icons.group_outlined
                        : Icons.chat_bubble_outline_rounded,
                    title: _searchQuery.isNotEmpty
                        ? 'No matching conversations'
                        : _showGroups
                            ? 'No study groups yet'
                            : 'No direct messages yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try a different name'
                        : _showGroups
                            ? 'Join a study group to start chatting with its members.'
                            : 'Search for people, follow them, and send a message request to start chatting.',
                    actionLabel: _searchQuery.isEmpty && !_showGroups
                        ? 'Find People'
                        : null,
                    onAction: _searchQuery.isEmpty && !_showGroups
                        ? _openPeopleSearch
                        : null,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await p.loadConversations(refresh: true);
                    if (_showGroups) await p.loadGroupConversations();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPeopleSearch,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text(
          'New Message',
          style: TextStyle(
            fontFamily: AppFonts.dmSans,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: Text(
        'Messages',
        style: TextStyle(
          fontFamily: AppFonts.sora,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        Consumer<MessagingProvider>(
          builder: (_, p, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.inbox_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  size: 22,
                ),
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
          icon: Icon(
            Icons.person_add_alt_1_rounded,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            size: 22,
          ),
          onPressed: _openPeopleSearch,
        ),
      ],
    );
  }

  void _openPeopleSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatUserSearchScreen()),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.dmSans,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : AppColors.muted,
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
                style: TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search direct messages…',
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
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _avatarGradient(conv.displayName),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: conv.avatarUrl != null && conv.avatarUrl!.isNotEmpty
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
                            fontWeight:
                                unread > 0 ? FontWeight.w800 : FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
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
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w400,
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
                          child: Icon(
                            Icons.volume_off_rounded,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          conv.lastMessagePreview ?? '',
                          style: TextStyle(
                            fontFamily: AppFonts.dmSans,
                            fontSize: 13,
                            color: unread > 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight:
                                unread > 0 ? FontWeight.w600 : FontWeight.w400,
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
              style: TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
