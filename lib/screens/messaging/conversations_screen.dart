import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/messaging_models.dart';
import 'package:reelscholar/providers/messaging_provider.dart';
import 'package:reelscholar/screens/messaging/chat_thread_screen.dart';
import 'package:reelscholar/screens/messaging/message_requests_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagingProvider>().loadConversations();
      context.read<MessagingProvider>().loadRequests();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Conversation> _filtered(List<Conversation> convs) {
    if (_search.isEmpty) return convs;
    final q = _search.toLowerCase();
    return convs
        .where((c) => c.displayName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              onRequestsTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MessageRequestsScreen(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: _SearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const _FilterTabs(),
            Expanded(
              child: Consumer<MessagingProvider>(
                builder: (_, provider, _) {
                  if (provider.convsLoading && provider.conversations.isEmpty) {
                    return const _ConvsShimmer();
                  }
                  if (provider.convsError != null &&
                      provider.conversations.isEmpty) {
                    return _ErrorState(
                      message: provider.convsError!,
                      onRetry: () =>
                          provider.loadConversations(refresh: true),
                    );
                  }
                  final convs = _filtered(provider.filteredConversations);
                  if (convs.isEmpty) {
                    return _EmptyState(filter: provider.filterType);
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        provider.loadConversations(refresh: true),
                    child: ListView.builder(
                      itemCount: convs.length,
                      itemBuilder: (_, i) => _ConvTile(
                        conv: convs[i],
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChatThreadScreen(
                                conversationId: convs[i].id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final VoidCallback onRequestsTap;
  const _AppBar({required this.onRequestsTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 2),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Consumer<MessagingProvider>(
            builder: (_, p, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                _IBtn(
                  icon: Icons.inbox_rounded,
                  onTap: onRequestsTap,
                ),
                if (p.pendingRequestCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${p.pendingRequestCount}',
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
          const SizedBox(width: 4),
          _IBtn(icon: Icons.edit_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Search conversations…',
                hintStyle: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
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
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingProvider>(
      builder: (_, p, _) {
        final filters = [
          ('all', 'All'),
          ('direct', 'Direct'),
          ('group', 'Groups'),
        ];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: filters.map((f) {
              final active = p.filterType == f.$1;
              return GestureDetector(
                onTap: () => p.setFilter(f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;

  const _ConvTile({required this.conv, required this.onTap});

  String _timeAgo(DateTime? dt) {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: unread > 0
              ? AppColors.bg
              : Theme.of(context).colorScheme.surface,
          border: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            _ConvAvatar(conv: conv),
            const SizedBox(width: 12),
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
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(conv.lastMessageAt),
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: unread > 0
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontWeight: unread > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
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
                              size: 11, color: AppColors.textTertiary),
                        ),
                      Expanded(
                        child: Text(
                          conv.lastMessagePreview ?? '',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: unread > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
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

class _ConvAvatar extends StatelessWidget {
  final Conversation conv;
  const _ConvAvatar({required this.conv});

  @override
  Widget build(BuildContext context) {
    final colors = _gradientForName(conv.displayName);
    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: conv.avatarUrl != null && conv.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      conv.avatarUrl!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    conv.displayInitials,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 16,
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
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.group_rounded,
                  size: 8, color: Colors.white),
            ),
          ),
      ],
    );
  }

  static List<Color> _gradientForName(String name) {
    final h = name.codeUnits.fold<int>(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, h.toDouble(), 0.6, 0.4).toColor(),
      HSLColor.fromAHSL(1, (h + 40).toDouble() % 360, 0.7, 0.3).toColor(),
    ];
  }
}

class _ConvsShimmer extends StatelessWidget {
  const _ConvsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        7,
        (i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 120,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: double.infinity,
                      color: AppColors.divider,
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
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = filter == 'group'
        ? 'No group chats yet'
        : filter == 'direct'
            ? 'No direct messages yet'
            : 'No conversations yet';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 52, color: AppColors.border),
          const SizedBox(height: 14),
          Text(
            msg,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a conversation to see it here',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
