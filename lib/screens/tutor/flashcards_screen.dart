import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'widgets/tutor_widgets.dart';

class FlashcardsScreen extends StatefulWidget {
  final TutorModule module;

  const FlashcardsScreen({super.key, required this.module});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorProvider>().loadFlashcards(widget.module.moduleId);
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip(TutorProvider prov) {
    if (prov.cardFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    prov.flipCard();
  }

  void _markKnown(TutorProvider prov) {
    _flipCtrl.reset();
    prov.markCardKnown(widget.module.moduleId);
  }

  void _markLearning(TutorProvider prov) {
    _flipCtrl.reset();
    prov.markCardLearning(widget.module.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: TColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<TutorProvider>(
          builder: (_, prov, _) {
            final cards = prov.flashcardsFor(widget.module.moduleId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flashcards · ${widget.module.code}',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TColors.textPrimary,
                  ),
                ),
                if (cards.isNotEmpty)
                  Text(
                    '${prov.currentCardIndex + 1} / ${cards.length}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: TColors.textTertiary,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          Consumer<TutorProvider>(
            builder: (_, prov, _) => IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: TColors.textSecondary,
                size: 20,
              ),
              tooltip: 'Restart',
              onPressed: () {
                _flipCtrl.reset();
                prov.resetFlashcards(widget.module.moduleId);
              },
            ),
          ),
        ],
      ),
      body: Consumer<TutorProvider>(
        builder: (_, prov, _) {
          if (prov.flashcardsState == TutorLoadState.loading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: TColors.primary,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Generating flashcards…',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (prov.flashcardsState == TutorLoadState.error) {
            return TutorEmptyState(
              icon: Icons.style_outlined,
              title: 'Could not load flashcards',
              subtitle:
                  'Try starting a tutor session first to generate flashcards',
              actionLabel: 'Retry',
              onAction: () => prov.loadFlashcards(widget.module.moduleId),
            );
          }

          final cards = prov.flashcardsFor(widget.module.moduleId);
          if (cards.isEmpty) {
            return TutorEmptyState(
              icon: Icons.style_outlined,
              title: 'No flashcards yet',
              subtitle:
                  'Complete at least one topic with your AI tutor to generate flashcards',
            );
          }

          final known = cards
              .where((c) => c.status == FlashcardStatus.known)
              .length;
          final learning = cards
              .where((c) => c.status == FlashcardStatus.learning)
              .length;
          final isDone =
              prov.currentCardIndex >= cards.length - 1 &&
              cards[prov.currentCardIndex].status != FlashcardStatus.unseen;

          return Column(
            children: [
              // ── Progress row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (prov.currentCardIndex + 1) / cards.length,
                        minHeight: 5,
                        backgroundColor: TColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          TColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatLabel(
                          label: '✓ $known known',
                          color: TColors.success,
                        ),
                        _StatLabel(
                          label: '✗ $learning learning',
                          color: TColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Flip card ────────────────────────────────────────────────
              Expanded(
                child: isDone
                    ? _CompletionView(
                        known: known,
                        total: cards.length,
                        onRestart: () {
                          _flipCtrl.reset();
                          prov.resetFlashcards(widget.module.moduleId);
                        },
                      )
                    : GestureDetector(
                        onTap: () => _flip(prov),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (_, _) {
                              final angle = _flipAnim.value * math.pi;
                              final isBack = angle > math.pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: isBack
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(math.pi),
                                        child: _CardBack(
                                          card: cards[prov.currentCardIndex],
                                        ),
                                      )
                                    : _CardFront(
                                        card: cards[prov.currentCardIndex],
                                        index: prov.currentCardIndex,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
              ),

              // ── Action buttons ───────────────────────────────────────────
              if (!isDone) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: '✗  Still learning',
                          color: TColors.error,
                          bgColor: TColors.errorLight,
                          onTap: () => _markLearning(prov),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: '✓  Got it!',
                          color: TColors.success,
                          bgColor: TColors.successLight,
                          onTap: () => _markKnown(prov),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Mini cards list ──────────────────────────────────────
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => _MiniCard(
                      card: cards[i],
                      isActive: i == prov.currentCardIndex,
                      onTap: () {
                        _flipCtrl.reset();
                        prov.setCardIndex(i);
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Card front ───────────────────────────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final Flashcard card;
  final int index;

  const _CardFront({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TColors.primary, Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(painter: _DiagonalPatternPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONCEPT',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60,
                    letterSpacing: 0.1,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      card.front,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tap to reveal answer',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                    const Icon(
                      Icons.rotate_right_rounded,
                      size: 20,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card back ────────────────────────────────────────────────────────────────
class _CardBack extends StatelessWidget {
  final Flashcard card;

  const _CardBack({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TColors.primary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TColors.primarySubtle,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ANSWER',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: TColors.primary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                card.back.isNotEmpty
                    ? card.back
                    : 'See your AI tutor for the full explanation.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  color: TColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.rotate_left_rounded,
                size: 20,
                color: TColors.textTertiary,
              ),
              const SizedBox(width: 4),
              const Text(
                'Tap to flip back',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: TColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mini card ────────────────────────────────────────────────────────────────
class _MiniCard extends StatelessWidget {
  final Flashcard card;
  final bool isActive;
  final VoidCallback onTap;

  const _MiniCard({
    required this.card,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    switch (card.status) {
      case FlashcardStatus.known:
        dotColor = TColors.success;
        break;
      case FlashcardStatus.learning:
        dotColor = TColors.error;
        break;
      default:
        dotColor = TColors.border;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? TColors.primarySubtle : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? TColors.primary : TColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.front,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? TColors.primary : TColors.textPrimary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  card.status == FlashcardStatus.known
                      ? 'Learned'
                      : card.status == FlashcardStatus.learning
                      ? 'Learning'
                      : 'Not yet',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 9,
                    color: TColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Completion view ──────────────────────────────────────────────────────────
class _CompletionView extends StatelessWidget {
  final int known;
  final int total;
  final VoidCallback onRestart;

  const _CompletionView({
    required this.known,
    required this.total,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (known / total * 100).toInt() : 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: TColors.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pct >= 80 ? 'Excellent work! 🎉' : 'Round complete!',
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$known of $total cards known ($pct%)',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: TColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Restart Deck',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diagonal pattern painter ─────────────────────────────────────────────────
class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const spacing = 12.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Stat label ───────────────────────────────────────────────────────────────
class _StatLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _StatLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
