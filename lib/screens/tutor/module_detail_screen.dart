import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/providers/flashcard_provider.dart';
import 'package:reelscholar/providers/voice_call_provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'widgets/tutor_widgets.dart';
import 'tutor_chat_screen.dart';
import 'concept_map_screen.dart';
import 'flashcard_review_screen.dart';
import 'voice_call_screen.dart';
import 'session_history_screen.dart';
import 'package:reelscholar/screens/quiz/quiz_suggestion_card.dart';
import 'package:reelscholar/screens/quiz/quiz_attempts_screen.dart';

class ModuleDetailScreen extends StatefulWidget {
  final TutorModule module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  bool _isStarting = false;
  bool _flashcardsLoading = false;

  TutorModule get module => widget.module;

  Color get _accent => TColors.accentFor(module.code);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Reset session button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) async {
                  if (v == 'reset') await _resetSession();
                  if (v == 'history') _openHistory();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: TColors.textPrimary,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Session History',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: TColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: TColors.error,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reset Session',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: TColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent,
                      _accent.withValues(alpha: 0.8),
                      TColors.secondary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Code badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            module.code,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          module.name,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Year ${module.yearLevel} · Semester ${module.semester} · ${module.credits} credits',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Progress section ──────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ProgressArc(
                            progress: module.progressPercentage / 100,
                            size: 64,
                            color: _accent,
                            child: Text(
                              '${module.progressPercentage.toInt()}%',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.status == 'not_started'
                                      ? 'Not Started'
                                      : module.status == 'completed'
                                      ? 'Completed!'
                                      : 'In Progress',
                                  style: TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${module.topicsCompleted} of ${module.totalTopics} topics done',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    color: TColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${module.quizzesTaken} quizzes · avg ${module.averageQuizScore.toInt()}%',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    color: TColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: module.status),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Start / Continue session CTA ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<TutorProvider>(
                    builder: (_, prov, _) => SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_isStarting || prov.isStarting)
                            ? null
                            : () => _startSession(prov),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: (_isStarting || prov.isStarting)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                module.isNotStarted
                                    ? Icons.play_arrow_rounded
                                    : Icons.chat_rounded,
                                size: 20,
                              ),
                        label: Text(
                          module.isNotStarted
                              ? 'Start AI Tutor Session'
                              : module.isCompleted
                              ? 'Review with AI Tutor'
                              : 'Continue Session',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Module quiz (API: /tutor/modules/{module}/quiz*, /quizzes/*) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Quiz',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      QuizSuggestionCard(
                        moduleId: module.moduleId,
                        moduleName: module.name,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => QuizAttemptsScreen(
                                  moduleId: module.moduleId,
                                  moduleName: module.name,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: _accent,
                          ),
                          label: Text(
                            'Past attempts',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              color: _accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Learning tools grid ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Learning Tools',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _ToolCard(
                            icon: Icons.style_rounded,
                            label: 'Flashcards',
                            subtitle: _flashcardsLoading
                                ? 'Generating cards…'
                                : 'Test your memory',
                            color: const Color(0xFF6366F1),
                            onTap: _openFlashcards,
                            isLoading: _flashcardsLoading,
                          ),
                          _ToolCard(
                            icon: Icons.account_tree_rounded,
                            label: 'Concept Map',
                            subtitle: 'Visual overview',
                            color: const Color(0xFF0D9488),
                            onTap: _openConceptMap,
                          ),
                          _ToolCard(
                            icon: Icons.headset_mic_rounded,
                            label: 'Voice Tutor',
                            subtitle: 'Talk with AI',
                            color: const Color(0xFFF59E0B),
                            onTap: _openVoiceCall,
                          ),
                          _ToolCard(
                            icon: Icons.history_edu_rounded,
                            label: 'Session History',
                            subtitle: 'Past transcripts',
                            color: const Color(0xFF8B5CF6),
                            onTap: _openHistory,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(TutorProvider prov) async {
    setState(() => _isStarting = true);
    final ok = await prov.startSession(module);
    setState(() => _isStarting = false);

    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: prov,
            child: TutorChatScreen(module: module),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.chatError ?? 'Could not start session'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: TColors.error,
        ),
      );
    }
  }

  Future<void> _resetSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset Session',
          style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will clear your current conversation and let you start fresh. Your progress percentage will not change.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<TutorProvider>().resetSession(module.moduleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session reset. Ready to start fresh.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openFlashcards() async {
    setState(() => _flashcardsLoading = true);
    final prov = context.read<FlashcardProvider>();
    await prov.loadDecks(module.moduleId);
    if (!mounted) return;

    if (prov.decks.isEmpty) {
      await prov.generate(module.moduleId);
      if (!mounted) return;
      if (prov.error != null) {
        setState(() => _flashcardsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.error!),
            backgroundColor: TColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (prov.decks.isEmpty || !mounted) {
      setState(() => _flashcardsLoading = false);
      return;
    }
    final deck = prov.decks.first;
    await prov.startSession(deck.id);
    if (!mounted) return;
    setState(() => _flashcardsLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: prov,
          child: FlashcardReviewScreen(
            deckId: deck.id,
            deckTitle: deck.title,
          ),
        ),
      ),
    );
  }

  void _openConceptMap() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ConceptMapScreen(
        moduleId: module.moduleId,
        moduleName: module.name,
      ),
    ),
  );

  void _openVoiceCall() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<VoiceCallProvider>(),
        child: VoiceCallScreen(
          moduleId: module.moduleId,
          moduleName: module.name,
        ),
      ),
    ),
  );

  void _openHistory() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TutorProvider>(),
        child: SessionHistoryScreen(module: module),
      ),
    ),
  );
}

// ─── Tool card ────────────────────────────────────────────────────────────────
class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLoading ? 0.04 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 20, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
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
