// lib/features/quiz/widgets/quiz_suggestion_card.dart
//
// Drop this card anywhere (module detail, tutor chat, etc.)
// It auto-loads the latest quiz suggestion on first paint
// and lets the user launch or generate a new one.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/quiz_provider.dart';
import 'package:reelscholar/screens/quiz/quiz_question_screen.dart';

class QuizSuggestionCard extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const QuizSuggestionCard({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<QuizSuggestionCard> createState() => _QuizSuggestionCardState();
}

class _QuizSuggestionCardState extends State<QuizSuggestionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadSuggestion(widget.moduleId);
    });
  }

  Future<void> _generateAndLaunch() async {
    final provider = context.read<QuizProvider>();
    final quiz = await provider.generateQuiz(widget.moduleId);
    if (quiz == null || !mounted) return;
    if (provider.suggestionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.suggestionError!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizQuestionScreen(quizId: quiz.id),
      ),
    );
  }

  void _launchExisting(String quizId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizQuestionScreen(quizId: quizId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (_, provider, _) {
        if (provider.suggestionLoading) {
          return _SuggestionCardShell(
            child: _LoadingState(),
          );
        }

        final suggestion = provider.suggestion;

        if (suggestion != null) {
          return _SuggestionCardShell(
            child: _SuggestionReady(
              title: suggestion.title,
              questionCount: suggestion.questions,
              moduleName: widget.moduleName,
              onTake: () => _launchExisting(suggestion.quizId),
              onGenerate: _generateAndLaunch,
              isGenerating: provider.suggestionLoading,
            ),
          );
        }

        return _SuggestionCardShell(
          child: _GenerateState(
            moduleName: widget.moduleName,
            onGenerate: _generateAndLaunch,
            isGenerating: provider.suggestionLoading,
            error: provider.suggestionError,
          ),
        );
      },
    );
  }
}

class _SuggestionCardShell extends StatelessWidget {
  final Widget child;
  const _SuggestionCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionReady extends StatelessWidget {
  final String title;
  final String questionCount;
  final String moduleName;
  final VoidCallback onTake;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const _SuggestionReady({
    required this.title,
    required this.questionCount,
    required this.moduleName,
    required this.onTake,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.quiz_rounded,
                  size: 22, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$questionCount questions · $moduleName',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // AI badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✨ AI',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onTake,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Take Quiz',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isGenerating ? null : onGenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded,
                        size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenerateState extends StatelessWidget {
  final String moduleName;
  final VoidCallback onGenerate;
  final bool isGenerating;
  final String? error;

  const _GenerateState({
    required this.moduleName,
    required this.onGenerate,
    required this.isGenerating,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              size: 24, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-Generated Quiz',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                error != null
                    ? error!
                    : 'Test your knowledge of $moduleName',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: error != null
                      ? const Color(0xFFFECACA)
                      : Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isGenerating ? null : onGenerate,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Generate',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
