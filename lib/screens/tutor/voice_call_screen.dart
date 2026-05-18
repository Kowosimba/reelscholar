import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/voice_call_provider.dart';
import 'package:reelscholar/models/voice_models.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  Timer? _durationTicker;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCallProvider>().startCall(widget.moduleId);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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
            builder: (_, prov, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _StatusPill(state: prov.state, isDark: isDark),
                  ),

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
                              ? const Color(0xFFEF4444)
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
                          color: const Color(0xFFEF4444),
                          iconColor: Colors.white,
                          onTap: () async {
                            final nav = Navigator.of(context);
                            await prov.endCall();
                            if (!mounted) return;
                            nav.pop();
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (shouldEnd == true && mounted) {
      await context.read<VoiceCallProvider>().endCall();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Color _statusColor(CallState s) => switch (s) {
    CallState.listening => const Color(0xFF10B981),
    CallState.speaking => const Color(0xFF4F46E5),
    CallState.thinking => const Color(0xFFF59E0B),
    CallState.error => const Color(0xFFEF4444),
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

// ── Sub-widgets ─────────────────────────────────────────────────────────

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
      CallState.thinking => const Color(0xFFF59E0B),
      CallState.error => const Color(0xFFEF4444),
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

class _StatusPill extends StatelessWidget {
  final CallState state;
  final bool isDark;

  const _StatusPill({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      CallState.listening => ('Your turn', const Color(0xFF10B981)),
      CallState.speaking => ('Tutor speaking', const Color(0xFF4F46E5)),
      CallState.thinking => ('Tutor thinking', const Color(0xFFF59E0B)),
      CallState.paused => ('Paused', Colors.grey),
      CallState.connecting => ('Connecting', Colors.grey),
      CallState.error => ('Error', const Color(0xFFEF4444)),
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
