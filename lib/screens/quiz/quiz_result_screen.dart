// lib/features/quiz/screens/quiz_result_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/quiz_provider.dart';
import 'package:reelscholar/models/quiz_models.dart';
import 'package:reelscholar/screens/quiz/quiz_question_screen.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  late AnimationController _listCtrl;
  late Animation<double> _listAnim;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic),
    );
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listAnim = CurvedAnimation(parent: _listCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scoreCtrl.forward().then((_) => _listCtrl.forward());
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final result = provider.result;
    final quiz = provider.quiz;

    if (result == null || quiz == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final xpEarned = (result.score * 50).clamp(0, 9999);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: () {
              provider.resetQuiz();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Score ring ───────────────────────────────────────────────
              Center(
                child: AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (_, _) => _ScoreRing(
                    progress: _scoreAnim.value *
                        (result.percentage / 100),
                    score: result.score,
                    total: result.total,
                    percentage: result.percentage,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Grade label ──────────────────────────────────────────────
              Column(
                children: [
                  Text(
                    '${result.gradeEmoji} ${result.grade}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Stats row ────────────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    value: result.score.toString(),
                    label: 'Correct',
                    valueColor: AppColors.success,
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    iconBg: const Color(0xFFDCFCE7),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: (result.total - result.score).toString(),
                    label: 'Wrong',
                    valueColor: AppColors.error,
                    icon: Icons.cancel_rounded,
                    iconColor: AppColors.error,
                    iconBg: AppColors.errorLight,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '+$xpEarned',
                    label: 'XP Earned',
                    valueColor: AppColors.primary,
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primarySubtle,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Review section ───────────────────────────────────────────
              const Text(
                'REVIEW ANSWERS',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),

              FadeTransition(
                opacity: _listAnim,
                child: Column(
                  children: List.generate(result.results.length, (i) {
                    final item = result.results[i];
                    return _ReviewTile(
                      index: i,
                      item: item,
                      isExpanded: _expandedIndex == i,
                      onTap: item.isCorrect
                          ? null
                          : () => setState(() =>
                              _expandedIndex =
                                  _expandedIndex == i ? null : i),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 28),

              // ── Actions ──────────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.resetQuiz();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QuizQuestionScreen(quizId: quiz.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: Colors.white),
                  label: const Text(
                    'Retake Quiz',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    provider.resetQuiz();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Back to Module',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score ring ────────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final double progress;
  final int score;
  final int total;
  final double percentage;

  const _ScoreRing({
    required this.progress,
    required this.score,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 140),
      painter: _RingPainter(progress: progress),
      child: SizedBox(
        width: 140,
        height: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score/$total',
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.primary, Color(0xFF6366F1)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Review tile ───────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final int index;
  final QuizResultItem item;
  final bool isExpanded;
  final VoidCallback? onTap;

  const _ReviewTile({
    required this.index,
    required this.item,
    required this.isExpanded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = item.isCorrect;
    final bg = isCorrect
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    final iconColor = isCorrect ? AppColors.success : AppColors.error;
    final icon =
        isCorrect ? Icons.check_rounded : Icons.close_rounded;
    final textColor =
        isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Question ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                if (!isCorrect)
                  Row(
                    children: [
                      Text(
                        isExpanded ? 'Hide' : 'Review',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: textColor,
                      ),
                    ],
                  ),
              ],
            ),

            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                item.question,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              if (item.yourAnswer != null) ...[
                const SizedBox(height: 6),
                _ReviewInfoRow(
                  label: 'Your answer:',
                  value: item.yourAnswer!,
                  isError: true,
                ),
              ],
              if (item.explanation != null &&
                  item.explanation!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.explanation!,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _ReviewInfoRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isError ? AppColors.error : AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}
