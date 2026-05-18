import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/flashcard_provider.dart';
import 'package:reelscholar/models/flashcard_models.dart';
import 'package:reelscholar/services/fsrs_scheduler.dart';
import 'widgets/tutor_widgets.dart';

class FlashcardReviewScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const FlashcardReviewScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().startSession(widget.deckId);
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1116) : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer<FlashcardProvider>(
          builder: (_, prov, _) {
            if (prov.activeDeck == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: TColors.primary,
                  strokeWidth: 2.5,
                ),
              );
            }

            if (prov.currentCard == null) {
              return _SessionComplete(
                reviewed: prov.sessionReviewed,
                correct: prov.sessionCorrect,
                deckTitle: widget.deckTitle,
                onDone: () {
                  prov.endSession();
                  Navigator.of(context).pop();
                },
              );
            }

            return Column(
              children: [
                _ReviewHeader(
                  deckTitle: widget.deckTitle,
                  position: prov.queuePosition,
                  total: prov.queueLength,
                  isDark: isDark,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        prov.flip();
                        if (_flipCtrl.status == AnimationStatus.dismissed) {
                          _flipCtrl.forward();
                        } else {
                          _flipCtrl.reverse();
                        }
                      },
                      child: _FlashcardWidget(
                        card: prov.currentCard!,
                        showBack: prov.showBack,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                _ReviewControls(
                  showBack: prov.showBack,
                  onFlip: prov.flip,
                  onRate: (rating) {
                    HapticFeedback.mediumImpact();
                    prov.rate(rating);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────

class _ReviewHeader extends StatelessWidget {
  final String deckTitle;
  final int position;
  final int total;
  final bool isDark;

  const _ReviewHeader({
    required this.deckTitle,
    required this.position,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    final progress = total == 0 ? 0.0 : position / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? TColors.darkCard : TColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : TColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deckTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${position + 1} of $total',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(TColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── The card itself ─────────────────────────────────────────────────────

class _FlashcardWidget extends StatelessWidget {
  final Flashcard card;
  final bool showBack;
  final bool isDark;

  const _FlashcardWidget({
    required this.card,
    required this.showBack,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? TColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey('${card.id}-$showBack'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          children: [
            Row(
              children: [
                _TypeChip(type: card.type, isDark: isDark),
                const Spacer(),
                Flexible(
                  child: Text(
                    card.topicTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        showBack ? 'Answer' : 'Question',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        showBack ? card.back : card.front,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: showBack ? 'DM Sans' : 'Sora',
                          fontSize: showBack ? 17 : 22,
                          fontWeight: showBack
                              ? FontWeight.w500
                              : FontWeight.w700,
                          height: 1.4,
                          color: textColor,
                        ),
                      ),
                      if (!showBack && card.hint.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFFFFAEB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 14,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  card.hint,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!showBack)
              Text(
                'Tap card to reveal',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: subColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final FlashcardType type;
  final bool isDark;
  const _TypeChip({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      FlashcardType.definition => (
        const Color(0xFF4F46E5),
        Icons.menu_book_rounded,
      ),
      FlashcardType.cloze => (
        const Color(0xFF0EA5E9),
        Icons.text_snippet_rounded,
      ),
      FlashcardType.application => (
        const Color(0xFF10B981),
        Icons.construction_rounded,
      ),
      FlashcardType.comparison => (
        const Color(0xFFF59E0B),
        Icons.compare_arrows_rounded,
      ),
      FlashcardType.example => (
        const Color(0xFFEC4899),
        Icons.format_quote_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom controls ─────────────────────────────────────────────────────

class _ReviewControls extends StatelessWidget {
  final bool showBack;
  final VoidCallback onFlip;
  final void Function(FsrsRating) onRate;
  final bool isDark;

  const _ReviewControls({
    required this.showBack,
    required this.onFlip,
    required this.onRate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBack) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onFlip,
            child: const Text(
              'Show answer',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _RatingButton(
            label: 'Again',
            hint: '< 1m',
            color: const Color(0xFFEF4444),
            onTap: () => onRate(FsrsRating.again),
          ),
          const SizedBox(width: 8),
          _RatingButton(
            label: 'Hard',
            hint: '< 10m',
            color: const Color(0xFFF59E0B),
            onTap: () => onRate(FsrsRating.hard),
          ),
          const SizedBox(width: 8),
          _RatingButton(
            label: 'Good',
            hint: '1-3d',
            color: const Color(0xFF10B981),
            onTap: () => onRate(FsrsRating.good),
          ),
          const SizedBox(width: 8),
          _RatingButton(
            label: 'Easy',
            hint: '4d+',
            color: const Color(0xFF4F46E5),
            onTap: () => onRate(FsrsRating.easy),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Session complete summary ────────────────────────────────────────────

class _SessionComplete extends StatelessWidget {
  final int reviewed;
  final int correct;
  final String deckTitle;
  final VoidCallback onDone;

  const _SessionComplete({
    required this.reviewed,
    required this.correct,
    required this.deckTitle,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    final accuracy = reviewed == 0 ? 0 : ((correct / reviewed) * 100).round();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [TColors.primary, TColors.primary.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Session complete',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            deckTitle,
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: subColor),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatColumn(value: '$reviewed', label: 'Reviewed', color: textColor),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 28),
                color: subColor.withValues(alpha: 0.2),
              ),
              _StatColumn(
                value: '$accuracy%',
                label: 'Accuracy',
                color: accuracy >= 80
                    ? const Color(0xFF10B981)
                    : accuracy >= 60
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onDone,
              child: const Text(
                'Done',
                style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.55),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
