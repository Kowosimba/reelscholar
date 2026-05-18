import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/quiz_provider.dart';
import 'package:reelscholar/models/quiz_models.dart';
import 'widgets/tutor_widgets.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startTutorQuiz(widget.quizId);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1116) : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer<QuizProvider>(
          builder: (_, prov, _) {
            if (prov.tutorLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: TColors.primary,
                  strokeWidth: 2.5,
                ),
              );
            }
            if (prov.attemptResult != null) {
              return _QuizResultsView(
                attempt: prov.attemptResult!,
                quiz: prov.tutorQuiz!,
                onDone: () {
                  prov.resetTutorQuiz();
                  Navigator.of(context).pop();
                },
              );
            }
            if (prov.tutorQuiz == null || prov.tutorCurrentQuestion == null) {
              return Center(child: Text(prov.tutorError ?? 'No quiz available'));
            }

            return _QuizTakingView(elapsedSeconds: prov.tutorElapsedSeconds);
          },
        ),
      ),
    );
  }
}

// ── Quiz-taking view ───────────────────────────────────────────────────

class _QuizTakingView extends StatelessWidget {
  final int elapsedSeconds;
  const _QuizTakingView({required this.elapsedSeconds});

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    final prov = context.watch<QuizProvider>();
    final q = prov.tutorCurrentQuestion!;
    final quiz = prov.tutorQuiz!;
    final revealed = prov.tutorRevealed.contains(q.id);
    final selected = prov.tutorAnswers[q.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
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
                      quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Question ${prov.tutorCurrentIndex + 1} of ${quiz.questions.length}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(elapsedSeconds),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (prov.tutorCurrentIndex + 1) / quiz.questions.length,
              minHeight: 4,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(TColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (q.bloomLevel != null) ...[
                      _BloomChip(level: q.bloomLevel!),
                      const SizedBox(width: 6),
                    ],
                    if (q.quizDifficulty != null) ...[
                      _DifficultyChip(difficulty: q.quizDifficulty!),
                      const SizedBox(width: 6),
                    ],
                    const Spacer(),
                    if (q.topicTitle != null)
                      Flexible(
                        child: Text(
                          q.topicTitle!,
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
                const SizedBox(height: 16),
                Text(
                  q.question,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(q.options.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionTile(
                      letter: String.fromCharCode(65 + i),
                      text: q.options[i],
                      selected: selected == i,
                      revealed: revealed,
                      isCorrect: i == (q.correctIndex ?? -1),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        prov.tutorSelect(q.id, i);
                      },
                    ),
                  );
                }),
                if (revealed && q.explanation != null) ...[
                  const SizedBox(height: 16),
                  _ExplanationCard(
                    explanation: q.explanation!,
                    isCorrect: selected == q.correctIndex,
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TColors.primary,
                disabledBackgroundColor: TColors.primary.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: !revealed
                  ? (selected != null
                        ? () {
                            HapticFeedback.mediumImpact();
                            prov.tutorConfirm();
                          }
                        : null)
                  : prov.tutorIsLastQuestion
                  ? (prov.tutorSubmitting ? null : prov.tutorSubmit)
                  : prov.tutorNext,
              child: Text(
                !revealed
                    ? 'Confirm'
                    : prov.tutorIsLastQuestion
                    ? (prov.tutorSubmitting ? 'Submitting…' : 'Finish quiz')
                    : 'Next question',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Option tile ─────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final bool revealed;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.revealed,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);

    Color bg, borderColor, letterBg, letterColor;
    IconData? trailingIcon;

    if (revealed) {
      if (isCorrect) {
        bg = const Color(0xFF10B981).withValues(alpha: 0.1);
        borderColor = const Color(0xFF10B981);
        letterBg = const Color(0xFF10B981);
        letterColor = Colors.white;
        trailingIcon = Icons.check_circle_rounded;
      } else if (selected) {
        bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        borderColor = const Color(0xFFEF4444);
        letterBg = const Color(0xFFEF4444);
        letterColor = Colors.white;
        trailingIcon = Icons.cancel_rounded;
      } else {
        bg = isDark ? TColors.darkCard : Colors.white;
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05);
        letterBg = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04);
        letterColor = isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.5);
      }
    } else if (selected) {
      bg = TColors.primary.withValues(alpha: 0.1);
      borderColor = TColors.primary;
      letterBg = TColors.primary;
      letterColor = Colors.white;
    } else {
      bg = isDark ? TColors.darkCard : Colors.white;
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05);
      letterBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04);
      letterColor = isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: letterColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: borderColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Explanation card ────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  final String explanation;
  final bool isCorrect;

  const _ExplanationCard({required this.explanation, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = isCorrect ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : tone.withValues(alpha: 0.05),
        border: Border.all(color: tone.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.lightbulb_rounded : Icons.school_rounded,
                size: 16,
                color: tone,
              ),
              const SizedBox(width: 6),
              Text(
                isCorrect ? 'Nice work — here\'s why' : 'Why the right answer is right',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: tone,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chips ────────────────────────────────────────────────────────────────

class _BloomChip extends StatelessWidget {
  final BloomLevel level;
  const _BloomChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      BloomLevel.remember => const Color(0xFF6366F1),
      BloomLevel.understand => const Color(0xFF0EA5E9),
      BloomLevel.apply => const Color(0xFF10B981),
      BloomLevel.analyze => const Color(0xFFEC4899),
    };
    return _Chip(label: level.label, color: color);
  }
}

class _DifficultyChip extends StatelessWidget {
  final QuizDifficulty difficulty;
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      QuizDifficulty.easy => const Color(0xFF10B981),
      QuizDifficulty.medium => const Color(0xFFF59E0B),
      QuizDifficulty.hard => const Color(0xFFEF4444),
    };
    return _Chip(label: difficulty.label, color: color);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Results view ────────────────────────────────────────────────────────

class _QuizResultsView extends StatelessWidget {
  final TutorQuizAttempt attempt;
  final Quiz quiz;
  final VoidCallback onDone;

  const _QuizResultsView({
    required this.attempt,
    required this.quiz,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    final scoreColor = attempt.percentage >= 80
        ? const Color(0xFF10B981)
        : attempt.percentage >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final byBloom = attempt.bucket('by_bloom');
    final byTopic = attempt.bucket('by_topic');
    final byDifficulty = attempt.bucket('by_difficulty');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${attempt.percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${attempt.score} out of ${attempt.total} correct',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                quiz.title,
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: subColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (byBloom.isNotEmpty)
          _BreakdownCard(
            title: 'By Bloom level',
            subtitle: 'How well you handled different cognitive demands',
            buckets: byBloom,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        if (byDifficulty.isNotEmpty)
          _BreakdownCard(title: 'By difficulty', buckets: byDifficulty, isDark: isDark),
        const SizedBox(height: 12),
        if (byTopic.isNotEmpty)
          _BreakdownCard(
            title: 'By topic',
            subtitle: 'Where to focus your revision',
            buckets: byTopic,
            isDark: isDark,
          ),
        const SizedBox(height: 32),
        SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onDone,
            child: const Text(
              'Done',
              style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<String, ({int correct, int total})> buckets;
  final bool isDark;

  const _BreakdownCard({
    required this.title,
    this.subtitle,
    required this.buckets,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: subColor)),
          ],
          const SizedBox(height: 12),
          ...buckets.entries.map((e) {
            final pct = e.value.total == 0 ? 0.0 : e.value.correct / e.value.total;
            final pctColor = pct >= 0.8
                ? const Color(0xFF10B981)
                : pct >= 0.5
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        '${e.value.correct}/${e.value.total}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pctColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
