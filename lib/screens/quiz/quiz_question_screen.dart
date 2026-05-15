// lib/features/quiz/screens/quiz_question_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/quiz_provider.dart';
import 'package:reelscholar/models/quiz_models.dart';
import 'package:reelscholar/screens/quiz/quiz_result_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  /// Pass [quizId] when navigating here fresh,
  /// or rely on an already-loaded quiz in QuizProvider.
  final String? quizId;

  const QuizQuestionScreen({super.key, this.quizId});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen>
    with SingleTickerProviderStateMixin {
  // Per-question 60-second countdown
  Timer? _timer;
  int _secondsLeft = 60;
  bool _answered = false; // confirmed selection before moving on
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuizProvider>();
      if (widget.quizId != null && provider.state != QuizState.active) {
        provider.loadQuiz(widget.quizId!);
      }
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
      _answered = false;
    });
    _slideCtrl.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft == 0) {
        _timer?.cancel();
        _handleTimeout();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handleTimeout() {
    final provider = context.read<QuizProvider>();
    final q = provider.currentQuestion;
    if (q == null) return;
    // Auto-submit with current selection (or no selection) and advance
    if (!provider.isLastQuestion) {
      provider.nextQuestion();
      _startTimer();
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    final provider = context.read<QuizProvider>();
    await provider.submitQuiz();
    if (!mounted) return;
    if (provider.result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const QuizResultScreen(),
        ),
      );
    }
  }

  void _onConfirm() {
    final provider = context.read<QuizProvider>();
    if (provider.selectedAnswerForCurrent() == null) return;
    setState(() => _answered = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (provider.isLastQuestion) {
        _submitQuiz();
      } else {
        provider.nextQuestion();
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  Color get _timerColor {
    if (_secondsLeft <= 10) return AppColors.error;
    if (_secondsLeft <= 20) return const Color(0xFFF59E0B);
    return AppColors.textSecondary;
  }

  Color get _timerBg {
    if (_secondsLeft <= 10) return AppColors.errorLight;
    if (_secondsLeft <= 20) return const Color(0xFFFEF3C7);
    return AppColors.backgroundMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (_, provider, _) {
        if (provider.state == QuizState.loading) {
          return const _QuizLoadingScreen();
        }
        if (provider.state == QuizState.error) {
          return _QuizErrorScreen(
            message: provider.error ?? 'Something went wrong',
            onRetry: () {
              final id = widget.quizId ?? provider.quiz?.id;
              if (id != null && id.isNotEmpty) {
                provider.loadQuiz(id);
              }
            },
          );
        }
        if (provider.state == QuizState.submitting) {
          return const _QuizSubmittingScreen();
        }
        if (provider.quiz == null) {
          return const _QuizLoadingScreen();
        }
        return _buildQuiz(context, provider);
      },
    );
  }

  Widget _buildQuiz(BuildContext context, QuizProvider provider) {
    final quiz = provider.quiz!;
    final question = provider.currentQuestion!;
    final total = quiz.questions.length;
    final current = provider.currentIndex + 1;
    final selected = provider.selectedAnswerForCurrent();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _IconBtn(
                        icon: Icons.close_rounded,
                        onTap: () => _showExitDialog(context, provider),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Question $current of $total',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // Timer pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _timerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 14, color: _timerColor),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(_secondsLeft),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _timerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress track
                  Row(
                    children: List.generate(total, (i) {
                      Color color;
                      if (i < provider.currentIndex) {
                        color = AppColors.success;
                      } else if (i == provider.currentIndex) {
                        color = AppColors.primary;
                      } else {
                        color = AppColors.border;
                      }
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ── Question + Options ────────────────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic badge
                      if (quiz.topicsCovered?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            quiz.topicsCovered!.first,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Question card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Options
                      ...List.generate(question.options.length, (i) {
                        final label =
                            String.fromCharCode(65 + i); // A, B, C, D
                        final isSelected = selected == i;
                        return _OptionTile(
                          label: label,
                          text: question.options[i],
                          isSelected: isSelected,
                          answered: _answered,
                          onTap: _answered
                              ? null
                              : () {
                                  provider.selectAnswer(question.id, i);
                                },
                        );
                      }),

                      const SizedBox(height: 20),

                      // Hint / Skip row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _showHintDialog(context, question),
                            icon: const Text('💡',
                                style: TextStyle(fontSize: 14)),
                            label: const Text(
                              'Hint',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            color: AppColors.border,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          TextButton(
                            onPressed: () {
                              if (provider.isLastQuestion) {
                                _submitQuiz();
                              } else {
                                provider.nextQuestion();
                                _startTimer();
                              }
                            },
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Confirm button ────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selected == null || _answered ? null : _onConfirm,
                  child: Text(
                    provider.isLastQuestion
                        ? 'Submit Quiz'
                        : 'Confirm Answer',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, QuizProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(
              fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Your progress will be lost if you exit now.',
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.resetQuiz();
              Navigator.pop(context);
            },
            child: const Text('Exit',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showHintDialog(BuildContext context, QuizQuestion question) {
    final explanation = question.explanation;
    if (explanation == null || explanation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hint available for this question.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Hint',
                style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool answered;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.answered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = Colors.white;
    Color textColor = AppColors.textPrimary;
    Color labelBg = const Color(0xFFF1F5F9);
    Color labelColor = AppColors.textSecondary;

    if (isSelected) {
      borderColor = const Color(0xFF6366F1);
      bgColor = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF3730A3);
      labelBg = const Color(0xFF6366F1);
      labelColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: Color(0xFF6366F1)),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _QuizLoadingScreen extends StatelessWidget {
  const _QuizLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading quiz…',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizSubmittingScreen extends StatelessWidget {
  const _QuizSubmittingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Grading your answers…',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hold tight, we\'re calculating your score',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _QuizErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
