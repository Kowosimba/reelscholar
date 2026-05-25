import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/voice_call_provider.dart';
import 'package:reelscholar/models/voice_models.dart';
import 'package:reelscholar/app_router.dart';
import 'widgets/tutor_widgets.dart' show TColors;

class VoiceCallScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const VoiceCallScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  Timer? _durationTicker;
  String? _lastTopicTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCallProvider>().startCall(widget.moduleId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      context.read<VoiceCallProvider>().endCall();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _durationTicker?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1116) : const Color(0xFFF7F8FB);
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmEnd();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Consumer<VoiceCallProvider>(
            builder: (ctx, prov, _) {
              // Detect topic advance and show toast.
              if (prov.topicAdvancedTitle != null &&
                  prov.topicAdvancedTitle != _lastTopicTitle) {
                _lastTopicTitle = prov.topicAdvancedTitle;
                _progressCtrl.forward(from: 0);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Topic complete! Now: ${prov.topicAdvancedTitle}',
                        style: const TextStyle(fontFamily: 'DM Sans'),
                      ),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  prov.clearTopicAdvancedTitle();
                });
              }

              return Column(
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(prov.state),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.moduleName,
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                prov.topicTitle.isNotEmpty
                                    ? prov.topicTitle
                                    : 'Voice tutor',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: subColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (prov.isResumed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Continued from last session',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDuration(prov.durationSeconds),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Progress panel ───────────────────────────────────────
                  if (prov.progress != null || prov.quota != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: _ProgressPanel(
                        progress: prov.progress,
                        quota: prov.quota,
                        turnCount: prov.turnCount,
                        progressCtrl: _progressCtrl,
                        isDark: isDark,
                        subColor: subColor,
                      ),
                    ),

                  // ── Quiz banner ──────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: prov.showQuizBanner
                        ? _QuizBanner(
                            key: const ValueKey('quiz-banner'),
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRouter.modules),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-quiz')),
                  ),

                  // ── Call orb ─────────────────────────────────────────────
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: _CallOrb(
                        state: prov.state,
                        pulseCtrl: _pulseCtrl,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // ── Caption ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: 90,
                      child: Center(
                        child: _CaptionText(
                          state: prov.state,
                          tutorReply: prov.currentReply,
                          userPartial: prov.interimTranscript,
                          error: prov.errorMessage,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                      ),
                    ),
                  ),

                  // ── Status pill ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _StatusPill(state: prov.state, isDark: isDark),
                  ),

                  // ── Controls ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallControl(
                          icon: prov.muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          label: prov.muted ? 'Unmute' : 'Mute',
                          color: prov.muted
                              ? TColors.error
                              : (isDark
                                    ? const Color(0xFF2A2F3A)
                                    : Colors.white),
                          iconColor: prov.muted
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          onTap:
                              prov.state == CallState.ended ||
                                  prov.state == CallState.error
                              ? null
                              : prov.toggleMute,
                        ),
                        _CallControl(
                          icon: _tapIcon(prov.state),
                          label: _tapLabel(prov.state),
                          color: const Color(0xFF4F46E5),
                          iconColor: Colors.white,
                          size: 78,
                          onTap:
                              prov.state == CallState.ended ||
                                  prov.state == CallState.error ||
                                  prov.state == CallState.connecting
                              ? null
                              : prov.tapToTalk,
                        ),
                        _CallControl(
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          color: TColors.error,
                          iconColor: Colors.white,
                          onTap: () async {
                            await prov.endCall();
                            if (!mounted) return;
                            await _showSessionSummary(prov);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEnd() async {
    final prov = context.read<VoiceCallProvider>();
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End the call?'),
        content: const Text('Your conversation history will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (shouldEnd == true && mounted) {
      await prov.endCall();
      if (mounted) await _showSessionSummary(prov);
    }
  }

  Future<void> _showSessionSummary(VoiceCallProvider prov) async {
    final summary = prov.endSummary;
    final progress = prov.progress;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionSummarySheet(
        duration: summary?.durationSeconds ?? prov.durationSeconds,
        turnCount: summary?.turnCount ?? prov.turnCount,
        progress: progress,
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  Color _statusColor(CallState s) => switch (s) {
    CallState.listening => const Color(0xFF10B981),
    CallState.speaking => const Color(0xFF4F46E5),
    CallState.thinking => TColors.warning,
    CallState.error => TColors.error,
    CallState.paused => Colors.grey,
    _ => Colors.grey.shade400,
  };

  IconData _tapIcon(CallState s) => switch (s) {
    CallState.listening => Icons.stop_rounded,
    CallState.speaking => Icons.touch_app_rounded,
    _ => Icons.mic_rounded,
  };

  String _tapLabel(CallState s) => switch (s) {
    CallState.listening => 'Stop',
    CallState.speaking => 'Interrupt',
    CallState.thinking => 'Wait…',
    _ => 'Talk',
  };
}

// ── Progress Panel ────────────────────────────────────────────────────────────

class _ProgressPanel extends StatelessWidget {
  final VoiceProgress? progress;
  final VoiceQuota? quota;
  final int turnCount;
  final AnimationController progressCtrl;
  final bool isDark;
  final Color subColor;

  const _ProgressPanel({
    required this.progress,
    required this.quota,
    required this.turnCount,
    required this.progressCtrl,
    required this.isDark,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    final total = progress?.totalTopics ?? 0;
    final completed = progress?.topicsCompleted ?? 0;
    final fraction = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          if (total > 0) ...[
            AnimatedBuilder(
              animation: progressCtrl,
              builder: (_, _) {
                final animated = fraction +
                    (progressCtrl.value * (1 / math.max(total, 1)) * 0.5);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: animated.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          // Row of chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (progress != null && total > 0)
                _Chip(
                  label:
                      'Topic ${completed + 1} of $total',
                  bg: chipBg,
                  color: subColor,
                ),
              _Chip(
                label: '$turnCount ${turnCount == 1 ? 'turn' : 'turns'}',
                bg: chipBg,
                color: subColor,
              ),
              if (quota != null)
                _Chip(
                  label: '${quota!.remainingTurns} left',
                  bg: quota!.remainingTurns < 10
                      ? TColors.error.withValues(alpha: 0.12)
                      : chipBg,
                  color: quota!.remainingTurns < 10 ? TColors.error : subColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;

  const _Chip({required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Quiz Banner ───────────────────────────────────────────────────────────────

class _QuizBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _QuizBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.quiz_rounded,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Quiz ready — tap to take it',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session Summary Sheet ─────────────────────────────────────────────────────

class _SessionSummarySheet extends StatelessWidget {
  final int duration;
  final int turnCount;
  final VoiceProgress? progress;

  const _SessionSummarySheet({
    required this.duration,
    required this.turnCount,
    required this.progress,
  });

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161B23) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.5);

    final total = progress?.totalTopics ?? 0;
    final completed = progress?.topicsCompleted ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Session Complete',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                label: 'Duration',
                value: _fmt(duration),
                icon: Icons.timer_outlined,
                isDark: isDark,
                textColor: textColor,
                subColor: subColor,
              ),
              _StatCard(
                label: 'Turns',
                value: '$turnCount',
                icon: Icons.swap_horiz_rounded,
                isDark: isDark,
                textColor: textColor,
                subColor: subColor,
              ),
              if (total > 0)
                _StatCard(
                  label: 'Topics',
                  value: '$completed / $total',
                  icon: Icons.menu_book_rounded,
                  isDark: isDark,
                  textColor: textColor,
                  subColor: subColor,
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color textColor;
  final Color subColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Call Orb ──────────────────────────────────────────────────────────────────

class _CallOrb extends StatelessWidget {
  final CallState state;
  final AnimationController pulseCtrl;
  final bool isDark;

  const _CallOrb({
    required this.state,
    required this.pulseCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final base = switch (state) {
      CallState.listening => const Color(0xFF10B981),
      CallState.speaking => const Color(0xFF4F46E5),
      CallState.thinking => TColors.warning,
      CallState.error => TColors.error,
      CallState.paused => Colors.grey,
      _ => const Color(0xFF4F46E5),
    };

    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, _) {
        final t = pulseCtrl.value;
        final pulse =
            state == CallState.listening ||
                state == CallState.speaking ||
                state == CallState.thinking
            ? (math.sin(t * math.pi * 2) * 0.08 + 1.0)
            : 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (state == CallState.listening || state == CallState.speaking)
              Container(
                width: 240 * (1 + t * 0.3),
                height: 240 * (1 + t * 0.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: base.withValues(alpha: 0.10 * (1 - t)),
                ),
              ),
            Container(
              width: 200 * pulse,
              height: 200 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: base.withValues(alpha: 0.18),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [base, base.withValues(alpha: 0.7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: base.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(_coreIcon(state), color: Colors.white, size: 56),
            ),
          ],
        );
      },
    );
  }

  IconData _coreIcon(CallState s) => switch (s) {
    CallState.listening => Icons.mic_rounded,
    CallState.speaking => Icons.graphic_eq_rounded,
    CallState.thinking => Icons.more_horiz_rounded,
    CallState.paused => Icons.pause_rounded,
    CallState.error => Icons.error_outline_rounded,
    CallState.ended => Icons.check_rounded,
    _ => Icons.school_rounded,
  };
}

// ── Caption Text ──────────────────────────────────────────────────────────────

class _CaptionText extends StatelessWidget {
  final CallState state;
  final String tutorReply;
  final String userPartial;
  final String? error;
  final Color textColor;
  final Color subColor;

  const _CaptionText({
    required this.state,
    required this.tutorReply,
    required this.userPartial,
    required this.error,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final (text, isItalic) = switch (state) {
      CallState.error => (error ?? 'Something went wrong', false),
      CallState.connecting => ('Connecting…', true),
      CallState.thinking => ('Thinking…', true),
      CallState.listening => (
        userPartial.isEmpty ? 'Listening…' : userPartial,
        userPartial.isEmpty,
      ),
      CallState.speaking => (tutorReply, false),
      CallState.paused => ('Paused', true),
      CallState.ended => ('Call ended', true),
      _ => ('', false),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          height: 1.45,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          color: isItalic ? subColor : textColor,
          fontWeight: isItalic ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final CallState state;
  final bool isDark;

  const _StatusPill({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      CallState.listening => ('Your turn', const Color(0xFF10B981)),
      CallState.speaking => ('Tutor speaking', const Color(0xFF4F46E5)),
      CallState.thinking => ('Tutor thinking', TColors.warning),
      CallState.paused => ('Paused', Colors.grey),
      CallState.connecting => ('Connecting', Colors.grey),
      CallState.error => ('Error', TColors.error),
      CallState.ended => ('Ended', Colors.grey),
      _ => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Call Control ──────────────────────────────────────────────────────────────

class _CallControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;

  const _CallControl({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.size = 64,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled ? color.withValues(alpha: 0.35) : color,
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.42),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: disabled
                ? Colors.grey
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87),
          ),
        ),
      ],
    );
  }
}
