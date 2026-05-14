import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'widgets/reel_widgets.dart';
import 'widgets/reel_player_item.dart';
import 'search_reels_screen.dart';

class ReelsScreen extends StatefulWidget {
  /// Opens the app drawer when embedded in [MainScreen].
  final VoidCallback? onMenuTap;

  const ReelsScreen({super.key, this.onMenuTap});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().initialLoad();
    });
    _pageCtrl.addListener(_onPageScroll);

    // Dark system bars for immersive feed
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _onPageScroll() {
    final page = _pageCtrl.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      context.read<ReelProvider>().setCurrentIndex(page);

      // Load more when near end
      final prov = context.read<ReelProvider>();
      final reels = prov.currentFeedReels;
      if (page >= reels.length - 3) {
        prov.loadMoreFeed(prov.activeFeed);
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Reel PageView ──────────────────────────────────────────────
          Consumer<ReelProvider>(
            builder: (_, prov, _) {
              final reels = prov.currentFeedReels;

              if (prov.feedState == ReelLoadState.loading && reels.isEmpty) {
                return const _FeedSkeleton();
              }

              if (prov.feedState == ReelLoadState.error && reels.isEmpty) {
                return _FeedError(
                  onRetry: () => prov.loadFeed(prov.activeFeed, refresh: true),
                );
              }

              if (reels.isEmpty) {
                return ReelEmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'No reels yet',
                  subtitle:
                      'Follow creators or upload your own reel to get started',
                  actionLabel: 'Discover',
                  onAction: () => prov.setFeedType(FeedType.trending),
                );
              }

              return PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                itemCount: reels.length,
                itemBuilder: (_, i) => ReelPlayerItem(
                  reel: reels[i],
                  isActive: i == _currentPage,
                  onProfileTap: () => Navigator.pushNamed(
                    context,
                    '/profile',
                    arguments: reels[i].uploader.uid,
                  ),
                  onHashtagTap: () => Navigator.pushNamed(
                    context,
                    '/search-reels',
                    arguments: reels[i].hashtags.isNotEmpty
                        ? reels[i].hashtags.first
                        : null,
                  ),
                ),
              );
            },
          ),

          // ── Top overlay: tabs + search ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  if (widget.onMenuTap != null) ...[
                    GestureDetector(
                      onTap: widget.onMenuTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Brand / tab selector
                  Expanded(
                    child: Consumer<ReelProvider>(
                      builder: (_, prov, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeedTab(
                            label: 'Following',
                            active: prov.activeFeed == FeedType.following,
                            onTap: () => prov.setFeedType(FeedType.following),
                          ),
                          const SizedBox(width: 20),
                          _FeedTab(
                            label: 'For You',
                            active: prov.activeFeed == FeedType.forYou,
                            onTap: () => prov.setFeedType(FeedType.forYou),
                          ),
                          const SizedBox(width: 20),
                          _FeedTab(
                            label: 'Trending',
                            active: prov.activeFeed == FeedType.trending,
                            onTap: () => prov.setFeedType(FeedType.trending),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Search icon
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchReelsScreen(),
                      ),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feed tab pill ────────────────────────────────────────────────────────────
class _FeedTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FeedTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
            ),
          ),
          if (active) ...[
            const SizedBox(height: 3),
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Feed skeleton loading ────────────────────────────────────────────────────
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Shimmer bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a2740), Color(0xFF0d1520)],
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading your feed…',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feed error ───────────────────────────────────────────────────────────────
class _FeedError extends StatelessWidget {
  final VoidCallback onRetry;
  const _FeedError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Could not load reels',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
