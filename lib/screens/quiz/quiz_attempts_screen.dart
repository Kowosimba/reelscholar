// lib/features/quiz/screens/quiz_attempts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/quiz_provider.dart';
import 'package:reelscholar/models/quiz_models.dart';
import 'package:reelscholar/screens/quiz/quiz_question_screen.dart';

class QuizAttemptsScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const QuizAttemptsScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<QuizAttemptsScreen> createState() => _QuizAttemptsScreenState();
}

class _QuizAttemptsScreenState extends State<QuizAttemptsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadAttempts(widget.moduleId);
    });
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
            const Text(
              'Past Attempts',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.moduleName,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: () =>
                context.read<QuizProvider>().loadAttempts(widget.moduleId),
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (_, provider, _) {
          if (provider.attemptsLoading) {
            return const _AttemptsShimmer();
          }
          if (provider.attemptsError != null) {
            return _AttemptsError(
              message: provider.attemptsError!,
              onRetry: () => provider.loadAttempts(widget.moduleId),
            );
          }
          if (provider.attempts.isEmpty) {
            return _AttemptsEmpty(
              moduleId: widget.moduleId,
            );
          }
          return _AttemptsList(
            attempts: provider.attempts,
            moduleId: widget.moduleId,
          );
        },
      ),
    );
  }
}

// ── Non-empty list ────────────────────────────────────────────────────────────

class _AttemptsList extends StatelessWidget {
  final List<QuizAttempt> attempts;
  final String moduleId;

  const _AttemptsList({
    required this.attempts,
    required this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    // Summary stats
    final best = attempts.fold<double>(
        0, (prev, a) => a.percentage > prev ? a.percentage : prev);
    final avg = attempts.isEmpty
        ? 0.0
        : attempts.fold<double>(0, (p, a) => p + a.percentage) /
            attempts.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SummaryRow(
              total: attempts.length,
              best: best,
              average: avg,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _AttemptCard(
                attempt: attempts[i],
                rank: i + 1,
              ),
              childCount: attempts.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total;
  final double best;
  final double average;

  const _SummaryRow({
    required this.total,
    required this.best,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _SumStat(
              label: 'Attempts', value: total.toString(), icon: '📝'),
          _vDivider(),
          _SumStat(
              label: 'Best Score',
              value: '${best.toStringAsFixed(0)}%',
              icon: '🏆'),
          _vDivider(),
          _SumStat(
              label: 'Average',
              value: '${average.toStringAsFixed(0)}%',
              icon: '📊'),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.25),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _SumStat extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _SumStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttempt attempt;
  final int rank;

  const _AttemptCard({required this.attempt, required this.rank});

  Color get _scoreColor {
    if (attempt.percentage >= 80) return AppColors.success;
    if (attempt.percentage >= 60) return const Color(0xFFF59E0B);
    return AppColors.error;
  }

  Color get _scoreBg {
    if (attempt.percentage >= 80) return const Color(0xFFDCFCE7);
    if (attempt.percentage >= 60) return const Color(0xFFFEF3C7);
    return AppColors.errorLight;
  }

  String _formatDuration(int? secs) {
    if (secs == null) return '—';
    if (secs < 60) return '${secs}s';
    return '${secs ~/ 60}m ${secs % 60}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rank == 1
                      ? const Color(0xFF92400E)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.quizTitle,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(attempt.createdAt),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.timer_outlined,
                        size: 11, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      _formatDuration(attempt.durationSeconds),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _scoreBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${attempt.score}/${attempt.total}',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _scoreColor,
                  ),
                ),
                Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    color: _scoreColor,
                    fontWeight: FontWeight.w600,
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

// ── Empty / error / loading states ───────────────────────────────────────────

class _AttemptsEmpty extends StatelessWidget {
  final String moduleId;
  const _AttemptsEmpty({required this.moduleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No attempts yet',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a quiz to start tracking your progress for this module.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final provider = context.read<QuizProvider>();
                final quiz = await provider.generateQuiz(moduleId);
                if (quiz != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QuizQuestionScreen(quizId: quiz.id),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Start a Quiz',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttemptsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AttemptsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 44, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _AttemptsShimmer extends StatelessWidget {
  const _AttemptsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
