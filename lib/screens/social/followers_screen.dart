// lib/features/social/screens/followers_screen.dart
//
// Shared screen for followers & following lists.
// Works for the authenticated user's own lists (/social/*)
// and for viewing another user's lists (/users/{id}/*).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/social_provider.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/screens/social/user_tile.dart';

class FollowersScreen extends StatefulWidget {
  /// The user whose followers/following we're viewing.
  /// Pass the current user's own ID to show your own lists.
  final String userId;
  final String userName;

  /// 0 = Followers, 1 = Following
  final int initialTab;

  /// If true, uses /social/* (my own lists). Otherwise /users/{id}/*
  final bool isMine;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialTab = 0,
    this.isMine = false,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final p = context.read<SocialProvider>();
    if (widget.isMine) {
      p.loadMyFollowers();
      p.loadMyFollowing();
    } else {
      p.loadProfileFollowers(widget.userId);
      p.loadProfileFollowing(widget.userId);
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isMine ? 'My Network' : widget.userName,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
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
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _UserListTab(
            listKey: 'followers',
            isMine: widget.isMine,
            userId: widget.userId,
            emptyIcon: Icons.people_outline_rounded,
            emptyTitle: 'No followers yet',
            emptySubtitle: widget.isMine
                ? 'Share your profile to get followers'
                : '${widget.userName} has no followers yet',
          ),
          _UserListTab(
            listKey: 'following',
            isMine: widget.isMine,
            userId: widget.userId,
            emptyIcon: Icons.person_add_alt_rounded,
            emptyTitle: 'Not following anyone',
            emptySubtitle: widget.isMine
                ? 'Discover people to follow'
                : '${widget.userName} isn\'t following anyone yet',
          ),
        ],
      ),
    );
  }
}

class _UserListTab extends StatelessWidget {
  final String listKey; // 'followers' | 'following'
  final bool isMine;
  final String userId;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _UserListTab({
    required this.listKey,
    required this.isMine,
    required this.userId,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (_, p, _) {
        final bool loading;
        final List<AppUser> users;

        if (listKey == 'followers') {
          loading = isMine ? p.followersLoading : p.profileFollowersLoading;
          users = isMine ? p.myFollowers : p.profileFollowers;
        } else {
          loading = isMine ? p.followingLoading : p.profileFollowingLoading;
          users = isMine ? p.myFollowing : p.profileFollowing;
        }

        if (loading && users.isEmpty) {
          return const _ListShimmer();
        }

        if (users.isEmpty) {
          return _EmptyList(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () {
            if (isMine) {
              if (listKey == 'followers') {
                return p.loadMyFollowers(refresh: true);
              } else {
                return p.loadMyFollowing(refresh: true);
              }
            } else {
              if (listKey == 'followers') {
                return p.loadProfileFollowers(userId);
              } else {
                return p.loadProfileFollowing(userId);
              }
            }
          },
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(
                height: 1, indent: 70, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) => Container(
              color: Colors.white,
              child: UserTile(user: users[i]),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyList extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyList({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
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
                  Container(
                      height: 12,
                      width: 120,
                      color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 6),
                  Container(
                      height: 10,
                      width: 180,
                      color: const Color(0xFFF1F5F9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



