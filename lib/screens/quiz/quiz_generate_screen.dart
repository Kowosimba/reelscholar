import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/quiz_models.dart';
import 'package:reelscholar/providers/quiz_provider.dart';
import 'package:reelscholar/screens/quiz/quiz_attempts_screen.dart';
import 'package:reelscholar/screens/quiz/quiz_question_screen.dart';

class QuizGenerateScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const QuizGenerateScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<QuizGenerateScreen> createState() => _QuizGenerateScreenState();
}

class _QuizGenerateScreenState extends State<QuizGenerateScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _enterCtrl;
  late Animation<double> _pulse;
  late Animation<double> _enter;

  _GeneratePhase _phase = _GeneratePhase.loading;
  Quiz? _generatedQuiz;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _enter = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    setState(() {
      _phase = _GeneratePhase.loading;
      _error = null;
    });
    final provider = context.read<QuizProvider>();
    final quiz = await provider.generateQuiz(widget.moduleId);
    if (!mounted) return;

    if (quiz != null) {
      _generatedQuiz = quiz;
      setState(() => _phase = _GeneratePhase.ready);
      _pulseCtrl.stop();
      _enterCtrl.forward(from: 0);
    } else {
      setState(() {
        _phase = _GeneratePhase.error;
        _error = provider.suggestionError;
      });
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _enterCtrl.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Quiz',
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
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_phase) {
            _GeneratePhase.loading => _LoadingView(pulseAnim: _pulse),
            _GeneratePhase.ready => _ReadyView(
                quiz: _generatedQuiz!,
                moduleName: widget.moduleName,
                enterAnim: _enter,
                onStart: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizQuestionScreen(
                          quizId: _generatedQuiz!.id),
                    ),
                  );
                },
                onViewHistory: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizAttemptsScreen(
                        moduleId: widget.moduleId,
                        moduleName: widget.moduleName,
                      ),
                    ),
                  );
                },
              ),
            _GeneratePhase.error => _ErrorView(
                error: _error ?? 'Failed to generate quiz',
                onRetry: _generate,
                onBack: () => Navigator.pop(context),
              ),
          },
        ),
      ),
    );
  }
}

enum _GeneratePhase { loading, ready, error }

class _LoadingView extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _LoadingView({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: pulseAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Generating Your Quiz',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Our AI is crafting personalised questions based on your module topics and learning progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 36),
            const _StepList(),
          ],
        ),
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (icon: '📚', text: 'Analysing your module content'),
      (icon: '🎯', text: 'Selecting key concepts'),
      (icon: '✏️', text: 'Crafting MCQ questions'),
    ];
    return Column(
      children: steps
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text(s.icon,
                            style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s.text,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReadyView extends StatelessWidget {
  final Quiz quiz;
  final String moduleName;
  final Animation<double> enterAnim;
  final VoidCallback onStart;
  final VoidCallback onViewHistory;

  const _ReadyView({
    required this.quiz,
    required this.moduleName,
    required this.enterAnim,
    required this.onStart,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: enterAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quiz Ready!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              quiz.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MetaChip(
                  icon: Icons.quiz_outlined,
                  label: '${quiz.questionCount} questions',
                ),
                const SizedBox(width: 10),
                _MetaChip(
                  icon: Icons.timer_outlined,
                  label: '~${quiz.questionCount} min',
                ),
                const SizedBox(width: 10),
                _MetaChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Generated',
                ),
              ],
            ),
            if (quiz.topicsCovered?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              const Text(
                'TOPICS COVERED',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: quiz.topicsCovered!
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 36),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded,
                    size: 20, color: Colors.white),
                label: const Text(
                  'Start Quiz',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onViewHistory,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text(
                  'View Past Attempts',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isTopicError = error.toLowerCase().contains('topic') ||
        error.toLowerCase().contains('complete');

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
                color: isTopicError
                    ? const Color(0xFFFEF3C7)
                    : AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTopicError
                    ? Icons.school_outlined
                    : Icons.error_outline_rounded,
                size: 40,
                color: isTopicError
                    ? const Color(0xFFF59E0B)
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTopicError ? 'Not Enough Progress' : 'Generation Failed',
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            if (!isTopicError)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!isTopicError) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onBack,
                child: Text(
                  isTopicError ? 'Continue Learning' : 'Go Back',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
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
