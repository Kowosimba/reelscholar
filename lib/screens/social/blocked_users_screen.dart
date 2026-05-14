// lib/features/social/screens/blocked_users_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/social_provider.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/screens/social/user_tile.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadBlockedUsers(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<SocialProvider>(
        builder: (_, p, _) {
          if (p.blockedLoading && p.blockedUsers.isEmpty) {
            return const _BlockedShimmer();
          }
          if (p.blockedUsers.isEmpty) {
            return const _EmptyBlocked();
          }
          return Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: Color(0xFF92400E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Blocked users can\'t see your profile, content, or contact you.',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: Color(0xFF78350F),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => p.loadBlockedUsers(refresh: true),
                  child: ListView.separated(
                    itemCount: p.blockedUsers.length,
                    separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 70,
                        color: Color(0xFFF1F5F9)),
                    itemBuilder: (_, i) {
                      final user = p.blockedUsers[i];
                      return Container(
                        color: Colors.white,
                        child: UserTile(
                          user: user,
                          showFollowBtn: false,
                          showBlockedBadge: true,
                          trailing: _UnblockButton(user: user),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Unblock button ────────────────────────────────────────────────────────────

class _UnblockButton extends StatefulWidget {
  final AppUser user;
  const _UnblockButton({required this.user});

  @override
  State<_UnblockButton> createState() => _UnblockButtonState();
}

class _UnblockButtonState extends State<_UnblockButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _unblock,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textSecondary))
            : const Text(
                'Unblock',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }

  Future<void> _unblock() async {
    // Confirm
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unblock ${widget.user.fullName}?',
          style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
        content: const Text(
          'They\'ll be able to see your profile and contact you again.',
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await context.read<SocialProvider>().unblockUser(widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.user.fullName} unblocked'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBlocked extends StatelessWidget {
  const _EmptyBlocked();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block_rounded,
                size: 40, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No blocked users',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Users you block will appear here.\nYou can unblock them at any time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedShimmer extends StatelessWidget {
  const _BlockedShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, _) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 110, color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 170, color: const Color(0xFFF1F5F9)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 70,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



