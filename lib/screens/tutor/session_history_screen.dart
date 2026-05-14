import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'widgets/tutor_widgets.dart';
import 'tutor_chat_screen.dart';

class SessionHistoryScreen extends StatefulWidget {
  final TutorModule module;

  const SessionHistoryScreen({super.key, required this.module});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorProvider>().loadHistory(widget.module.moduleId);
    });
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
            color: TColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Session History',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: TColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<TutorProvider>(
        builder: (_, prov, _) {
          // ── Loading state ─────────────────────────────────────────────────
          if (prov.historyState == TutorLoadState.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: TColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          // ── Module context pill ───────────────────────────────────────────
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Module selector bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: TColors.accentFor(
                          widget.module.code,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: TColors.accentFor(widget.module.code),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.module.name,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: TColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${widget.module.code} · ${widget.module.progressPercentage.toInt()}% complete',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: TColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: TColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: prov.messages.isEmpty
                    ? TutorEmptyState(
                        icon: Icons.history_outlined,
                        title: 'No history yet',
                        subtitle:
                            'Start a tutor session to begin learning. Your conversations will appear here.',
                        actionLabel: 'Start Session',
                        onAction: () => _startSession(prov),
                      )
                    : _HistoryView(
                        messages: prov.messages,
                        module: widget.module,
                        onContinue: () => _startSession(prov),
                      ),
              ),
            ],
          );
        },
      ),

      // ── Floating action ───────────────────────────────────────────────────
      floatingActionButton: Consumer<TutorProvider>(
        builder: (_, prov, _) => prov.messages.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text(
                  'Continue Session',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _startSession(prov),
              ),
      ),
    );
  }

  Future<void> _startSession(TutorProvider prov) async {
    final ok = await prov.startSession(widget.module);
    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: prov,
            child: TutorChatScreen(module: widget.module),
          ),
        ),
      );
    }
  }
}

// ─── History view ─────────────────────────────────────────────────────────────
class _HistoryView extends StatelessWidget {
  final List<ChatMessage> messages;
  final TutorModule module;
  final VoidCallback onContinue;

  const _HistoryView({
    required this.messages,
    required this.module,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Group messages into a single "current session" card +
    // the individual messages as a transcript
    final userCount = messages.where((m) => m.isUser).length;
    final tutorCount = messages.where((m) => m.isTutor).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // ── Active session card ──────────────────────────────────────────
        _ActiveSessionCard(
          module: module,
          messageCount: messages.length,
          onContinue: onContinue,
        ),

        const SizedBox(height: 20),

        // ── Stats row ─────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                value: '${messages.length}',
                color: TColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline_rounded,
                label: 'Your Inputs',
                value: '$userCount',
                color: TColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.smart_toy_outlined,
                label: 'AI Replies',
                value: '$tutorCount',
                color: TColors.warning,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Transcript header ──────────────────────────────────────────────
        const Row(
          children: [
            Icon(Icons.history_edu_rounded, size: 16, color: TColors.primary),
            SizedBox(width: 8),
            Text(
              'Conversation Transcript',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TColors.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Messages ───────────────────────────────────────────────────────
        ...messages.map((msg) => _TranscriptMessage(message: msg)),
      ],
    );
  }
}

// ─── Active session card ──────────────────────────────────────────────────────
class _ActiveSessionCard extends StatelessWidget {
  final TutorModule module;
  final int messageCount;
  final VoidCallback onContinue;

  const _ActiveSessionCard({
    required this.module,
    required this.messageCount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final accent = TColors.accentFor(module.code);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current Session',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: TColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                '$messageCount messages',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: TColors.textTertiary,
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.bar_chart_rounded,
                size: 14,
                color: TColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                '${module.progressPercentage.toInt()}% progress',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: TColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: module.progressPercentage / 100,
              minHeight: 4,
              backgroundColor: TColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Continue Session →',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: TColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transcript message ───────────────────────────────────────────────────────
class _TranscriptMessage extends StatelessWidget {
  final ChatMessage message;

  const _TranscriptMessage({required this.message});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Tutor avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? TColors.primary : TColors.muted,
                borderRadius: BorderRadius.only(
                  topLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  topRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: isUser ? Colors.white : TColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(message.timestamp),
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: isUser ? Colors.white60 : TColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                color: TColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: TColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
