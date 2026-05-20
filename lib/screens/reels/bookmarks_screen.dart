import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'widgets/reel_widgets.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _isGrid = true;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().loadBookmarks();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ReelProvider>().loadMoreBookmarks();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Saved Reels',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Grid / List toggle
          IconButton(
            icon: Icon(
              _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Consumer<ReelProvider>(
        builder: (_, prov, _) {
          if (prov.bookmarksState == ReelLoadState.loading &&
              prov.bookmarks.isEmpty) {
            return const _BookmarksSkeleton();
          }

          final visibleBookmarks = prov.bookmarks.where((r) => r.isVisible).toList();

          if (visibleBookmarks.isEmpty) {
            return ReelEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved reels',
              subtitle:
                  'Tap the bookmark icon on any reel to save it here for later',
            );
          }

          if (_isGrid) {
            return _GridView(
              reels: visibleBookmarks,
              scrollCtrl: _scrollCtrl,
              hasMore: prov.hasMoreBookmarks,
            );
          } else {
            return _ListView(
              reels: visibleBookmarks,
              scrollCtrl: _scrollCtrl,
              hasMore: prov.hasMoreBookmarks,
              onUnsave: (reelId) => prov.toggleBookmark(reelId),
            );
          }
        },
      ),
    );
  }
}

// ─── Grid view ────────────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  final List<Reel> reels;
  final ScrollController scrollCtrl;
  final bool hasMore;

  const _GridView({
    required this.reels,
    required this.scrollCtrl,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollCtrl,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${reels.length} saved reel${reels.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ReelThumbnailCard(
                reel: reels[i],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/reel-detail',
                  arguments: reels[i],
                ),
              ),
              childCount: reels.length,
            ),
          ),
        ),
        if (hasMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── List view ────────────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final List<Reel> reels;
  final ScrollController scrollCtrl;
  final bool hasMore;
  final ValueChanged<String> onUnsave;

  const _ListView({
    required this.reels,
    required this.scrollCtrl,
    required this.hasMore,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: reels.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.border, height: 1),
      itemBuilder: (_, i) {
        if (i == reels.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final reel = reels[i];
        return _BookmarkListItem(
          reel: reel,
          onTap: () =>
              Navigator.pushNamed(context, '/reel-detail', arguments: reel),
          onUnsave: () => onUnsave(reel.id),
        );
      },
    );
  }
}

class _BookmarkListItem extends StatelessWidget {
  final Reel reel;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _BookmarkListItem({
    required this.reel,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 112,
                child: reel.thumbnailUrl != null
                    ? Image.network(
                        reel.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _DarkThumb(),
                      )
                    : _DarkThumb(),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uploader
                  Row(
                    children: [
                      UserAvatar(
                        imageUrl: reel.uploader.profilePicUrl,
                        initials: reel.uploader.initials,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reel.uploader.fullName,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Caption
                  if (reel.caption != null)
                    Text(
                      reel.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),

                  // Topic
                  if (reel.topic != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reel.topic!.name,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      _StatBadge(
                        Icons.play_arrow_rounded,
                        formatCount(reel.viewCount),
                      ),
                      const SizedBox(width: 10),
                      _StatBadge(
                        Icons.favorite_border_rounded,
                        formatCount(reel.likeCount),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unsave button
            IconButton(
              icon: const Icon(
                Icons.bookmark_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: onUnsave,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String count;
  const _StatBadge(this.icon, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(
          count,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _DarkThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1a2740), Color(0xFF0d1520)]),
    ),
    child: const Center(
      child: Icon(Icons.play_arrow_rounded, color: Colors.white24, size: 28),
    ),
  );
}

class _BookmarksSkeleton extends StatelessWidget {
  const _BookmarksSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.62,
      ),
      itemCount: 9,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundMuted,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
