import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/providers/messaging_provider.dart';
import 'package:reelscholar/providers/social_provider.dart';
import 'package:reelscholar/screens/social/user_tile.dart';

class ChatUserSearchScreen extends StatefulWidget {
  const ChatUserSearchScreen({super.key});

  @override
  State<ChatUserSearchScreen> createState() => _ChatUserSearchScreenState();
}

class _ChatUserSearchScreenState extends State<ChatUserSearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadSuggestions();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      context.read<SocialProvider>().clearSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<SocialProvider>().search(value.trim());
    });
  }

  Future<void> _composeRequest(AppUser user) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MessageRequestComposer(user: user),
    );
    if (message == null || message.trim().isEmpty || !mounted) return;

    try {
      await context.read<MessagingProvider>().sendMessageRequest(
            receiverId: user.uid,
            initialMessage: message.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message request sent to ${user.fullName}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search users to follow or message…',
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
      body: Consumer<SocialProvider>(
        builder: (_, p, _) {
          final searching = _ctrl.text.trim().length >= 2;
          if (searching && p.searchLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final users = searching ? p.searchResults : p.suggestions;
          if (searching && p.searchError != null) {
            return Center(
              child: Text(
                p.searchError!,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          if (users.isEmpty) {
            return Center(
              child: Text(
                searching
                    ? 'No matching users found.'
                    : 'Search for people or start with suggestions.',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final user = users[i];
              return UserTile(
                user: user,
                secondaryTrailing: _MessageButton(
                  onTap: () => _composeRequest(user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MessageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Text(
          'Message',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MessageRequestComposer extends StatefulWidget {
  final AppUser user;

  const _MessageRequestComposer({required this.user});

  @override
  State<_MessageRequestComposer> createState() => _MessageRequestComposerState();
}

class _MessageRequestComposerState extends State<_MessageRequestComposer> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message ${widget.user.fullName}',
              style: const TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This sends a message request before the chat opens.',
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your first message…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _ctrl.text),
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
