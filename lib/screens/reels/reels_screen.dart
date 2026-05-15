import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
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
  FeedType? _lastFeedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().initialLoad();
    });
    _pageCtrl.addListener(_onPageScroll);
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
    final isReelsTab = context.watch<NavigationProvider>().isReels;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ReelsBackdrop(),
          // ── Reel PageView ──────────────────────────────────────────────
          Consumer<ReelProvider>(
            builder: (_, prov, _) {
              // Reset to page 0 whenever the active feed tab changes
              if (_lastFeedType != prov.activeFeed) {
                _lastFeedType = prov.activeFeed;
                if (_currentPage != 0) {
                  _currentPage = 0;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
                  });
                }
              }

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
                  isActive: isReelsTab && i == _currentPage,
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
              child: Row(
                children: [
                  if (widget.onMenuTap != null) ...[
                    _TopIconButton(
                      icon: Icons.menu_rounded,
                      onTap: widget.onMenuTap!,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Consumer<ReelProvider>(
                      builder: (_, prov, _) => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120F172A),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FeedTab(
                              label: 'Following',
                              active: prov.activeFeed == FeedType.following,
                              onTap: () => prov.setFeedType(FeedType.following),
                            ),
                            const SizedBox(width: 8),
                            _FeedTab(
                              label: 'For You',
                              active: prov.activeFeed == FeedType.forYou,
                              onTap: () => prov.setFeedType(FeedType.forYou),
                            ),
                            const SizedBox(width: 8),
                            _FeedTab(
                              label: 'Trending',
                              active: prov.activeFeed == FeedType.trending,
                              onTap: () => prov.setFeedType(FeedType.trending),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _TopIconButton(
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchReelsScreen(),
                      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? AppColors.fabGradient : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
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
          const _ReelsBackdrop(),
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
                    color: Colors.white60,
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
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white38,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load reels',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _ReelsBackdrop extends StatelessWidget {
  const _ReelsBackdrop();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.black);
  }
}
