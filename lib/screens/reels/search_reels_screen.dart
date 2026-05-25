import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'widgets/reel_widgets.dart';

class SearchReelsScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchReelsScreen({super.key, this.initialQuery});

  @override
  State<SearchReelsScreen> createState() => _SearchReelsScreenState();
}

class _SearchReelsScreenState extends State<SearchReelsScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final prov = context.read<ReelProvider>();
    prov.loadTrendingTags();

    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prov.search(widget.initialQuery!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }

    _ctrl.addListener(_onChanged);
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ReelProvider>().search(_ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search reels, #hashtags…',
            hintStyle: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              color: AppColors.textTertiary,
            ),
            border: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      _ctrl.clear();
                      context.read<ReelProvider>().search('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Consumer<ReelProvider>(
        builder: (_, prov, _) {
          // Empty query — show trending tags + suggestions
          if (_ctrl.text.trim().isEmpty) {
            return _TrendingView(
              tags: prov.trendingTags,
              onTagTap: (tag) {
                _ctrl.text = '#$tag';
                _ctrl.selection = TextSelection.collapsed(
                  offset: _ctrl.text.length,
                );
                prov.search('#$tag');
              },
            );
          }

          // Loading
          if (prov.searchState == ReelLoadState.loading) {
            return const _SearchLoading();
          }

          // No results
          if (prov.searchResults.isEmpty) {
            return ReelEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              subtitle: 'Try different keywords or browse trending hashtags',
            );
          }

          // Results grid
          return _SearchResults(
            reels: prov.searchResults.where((r) => r.isVisible).toList(),
            query: _ctrl.text,
            onReelTap: (reel) =>
                Navigator.pushNamed(context, '/reel-detail', arguments: reel),
          );
        },
      ),
    );
  }
}

// ─── Trending view ────────────────────────────────────────────────────────────
class _TrendingView extends StatelessWidget {
  final List<Hashtag> tags;
  final ValueChanged<String> onTagTap;

  const _TrendingView({required this.tags, required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (tags.isNotEmpty) ...[
          const Text(
            'Trending Tags',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: tags
                .map(
                  (tag) => _TrendingTagChip(
                    tag: tag,
                    onTap: () => onTagTap(tag.name),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
        ],

        // Discover categories header
        const Text(
          'Browse Categories',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.0,
          children: const [
            _CategoryCard(
              emoji: '⚗️',
              label: 'Sciences',
              color: Color(0xFF0D9488),
            ),
            _CategoryCard(
              emoji: '📐',
              label: 'Engineering',
              color: Color(0xFF6366F1),
            ),
            _CategoryCard(
              emoji: '💼',
              label: 'Business',
              color: Color(0xFFF59E0B),
            ),
            _CategoryCard(emoji: '⚖️', label: 'Law', color: Color(0xFF8B5CF6)),
            _CategoryCard(
              emoji: '🎓',
              label: 'Education',
              color: Color(0xFF22C55E),
            ),
            _CategoryCard(
              emoji: '🏥',
              label: 'Health',
              color: Color(0xFFEF4444),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendingTagChip extends StatelessWidget {
  final Hashtag tag;
  final VoidCallback onTap;

  const _TrendingTagChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${tag.name}',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _fmt(tag.usageCount),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _CategoryCard({
    required this.emoji,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search loading ───────────────────────────────────────────────────────────
class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.65,
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

// ─── Search results grid ──────────────────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  final List<Reel> reels;
  final String query;
  final ValueChanged<Reel> onReelTap;

  const _SearchResults({
    required this.reels,
    required this.query,
    required this.onReelTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${reels.length} results for "$query"',
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
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ReelThumbnailCard(
                reel: reels[i],
                onTap: () => onReelTap(reels[i]),
              ),
              childCount: reels.length,
            ),
          ),
        ),
      ],
    );
  }
}
