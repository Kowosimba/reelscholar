import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'widgets/tutor_widgets.dart';

class VoiceLessonScreen extends StatefulWidget {
  final TutorModule module;

  const VoiceLessonScreen({super.key, required this.module});

  @override
  State<VoiceLessonScreen> createState() => _VoiceLessonScreenState();
}

class _VoiceLessonScreenState extends State<VoiceLessonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorProvider>().loadVoiceLesson(widget.module.moduleId);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: TColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Lesson',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TColors.textPrimary,
              ),
            ),
            Text(
              widget.module.name,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: TColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.text_fields_rounded,
              color: TColors.textSecondary,
              size: 22,
            ),
            tooltip: 'Reading mode',
            onPressed: () => _showReadingMode(context),
          ),
        ],
      ),
      body: Consumer<TutorProvider>(
        builder: (_, prov, _) {
          if (prov.voiceLessonState == TutorLoadState.loading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: TColors.warning,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Generating voice script…',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (prov.voiceLessonState == TutorLoadState.error) {
            return TutorEmptyState(
              icon: Icons.headphones_outlined,
              title: 'Could not load voice lesson',
              subtitle: 'Complete at least one topic with your AI tutor first',
              actionLabel: 'Retry',
              onAction: () => prov.loadVoiceLesson(widget.module.moduleId),
            );
          }

          final lesson = prov.voiceLessonFor(widget.module.moduleId);
          if (lesson == null || lesson.segments.isEmpty) {
            return TutorEmptyState(
              icon: Icons.headphones_outlined,
              title: 'No voice lesson yet',
              subtitle:
                  'Chat with your AI tutor to generate a voice lesson script',
            );
          }

          return Column(
            children: [
              // ── Lesson header ────────────────────────────────────────────
              _LessonHeader(lesson: lesson),

              // ── Segment list ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: lesson.segments.length,
                  itemBuilder: (_, i) => _SegmentCard(
                    segment: lesson.segments[i],
                    index: i,
                    isActive: prov.activeSegmentIndex == i,
                    isPlaying:
                        prov.voiceIsPlaying && prov.activeSegmentIndex == i,
                    onTap: () => prov.setActiveSegment(i),
                  ),
                ),
              ),

              // ── Playback controls ────────────────────────────────────────
              _PlaybackControls(
                lesson: lesson,
                prov: prov,
                pulseCtrl: _pulseCtrl,
                moduleId: widget.module.moduleId,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReadingMode(BuildContext context) {
    final prov = context.read<TutorProvider>();
    final lesson = prov.voiceLessonFor(widget.module.moduleId);
    if (lesson == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: TColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: TColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TColors.textTertiary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: lesson.segments.length,
                itemBuilder: (_, i) {
                  final seg = lesson.segments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seg.title,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          seg.content,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            color: TColors.textPrimary,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lesson header ────────────────────────────────────────────────────────────
class _LessonHeader extends StatelessWidget {
  final VoiceLesson lesson;

  const _LessonHeader({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: TColors.warning.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: TColors.warning.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: 12,
                      color: TColors.warning,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI VOICE LESSON',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: TColors.warning,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.estimatedDurationMinutes != null) ...[
                const SizedBox(width: 8),
                Text(
                  '~${lesson.estimatedDurationMinutes} min',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: TColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: TColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.adjust_rounded,
                size: 12,
                color: TColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Focus: ${lesson.focusTopic}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: TColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Segment card ─────────────────────────────────────────────────────────────
class _SegmentCard extends StatelessWidget {
  final VoiceLessonSegment segment;
  final int index;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SegmentCard({
    required this.segment,
    required this.index,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  });

  Color get _typeColor {
    switch (segment.type) {
      case 'intro':
        return TColors.primary;
      case 'example':
        return TColors.secondary;
      case 'question':
        return TColors.warning;
      case 'summary':
        return TColors.success;
      default:
        return TColors.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (segment.type) {
      case 'intro':
        return Icons.play_circle_outline_rounded;
      case 'example':
        return Icons.lightbulb_outline_rounded;
      case 'question':
        return Icons.help_outline_rounded;
      case 'summary':
        return Icons.summarize_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? _typeColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? _typeColor.withValues(alpha: 0.4)
                : TColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? _typeColor : TColors.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPlaying
                        ? _WaveIcon(color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? Colors.white
                                  : TColors.textTertiary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(_typeIcon, size: 15, color: _typeColor),
                const SizedBox(width: 4),
                Text(
                  segment.type.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _typeColor,
                    letterSpacing: 0.05,
                  ),
                ),
                if (segment.durationSeconds != null) ...[
                  const Spacer(),
                  Text(
                    '${segment.durationSeconds}s',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: TColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              segment.title,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? _typeColor : TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              segment.content,
              maxLines: isActive ? null : 3,
              overflow: isActive ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: TColors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Playback controls ────────────────────────────────────────────────────────
class _PlaybackControls extends StatelessWidget {
  final VoiceLesson lesson;
  final TutorProvider prov;
  final AnimationController pulseCtrl;
  final String moduleId;

  const _PlaybackControls({
    required this.lesson,
    required this.prov,
    required this.pulseCtrl,
    required this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    final current = prov.activeSegmentIndex;
    final total = lesson.segments.length;
    final isFirst = current == 0;
    final isLast = current == total - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: TColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Segment progress ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section ${current + 1} of $total',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: TColors.textTertiary,
                ),
              ),
              Text(
                lesson.segments[current].title,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current + 1) / total,
              minHeight: 4,
              backgroundColor: TColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(TColors.warning),
            ),
          ),
          const SizedBox(height: 16),

          // ── Controls row ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous
              IconButton(
                onPressed: isFirst ? null : prov.prevSegment,
                icon: Icon(
                  Icons.skip_previous_rounded,
                  size: 28,
                  color: isFirst ? TColors.border : TColors.textSecondary,
                ),
              ),

              // Play / Pause
              GestureDetector(
                onTap: prov.toggleVoicePlayback,
                child: AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, child) {
                    final scale = prov.voiceIsPlaying
                        ? 1.0 + pulseCtrl.value * 0.08
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: TColors.warning,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TColors.warning.withValues(alpha: 0.4),
                          blurRadius: prov.voiceIsPlaying ? 16 : 8,
                          spreadRadius: prov.voiceIsPlaying ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      prov.voiceIsPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Next
              IconButton(
                onPressed: isLast ? null : () => prov.nextSegment(moduleId),
                icon: Icon(
                  Icons.skip_next_rounded,
                  size: 28,
                  color: isLast ? TColors.border : TColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated wave icon (playing indicator) ───────────────────────────────────
class _WaveIcon extends StatefulWidget {
  final Color color;
  const _WaveIcon({required this.color});

  @override
  State<_WaveIcon> createState() => _WaveIconState();
}

class _WaveIconState extends State<_WaveIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final h = 4.0 + (_ctrl.value * 8) * ((i % 2 == 0) ? 1 : 0.6);
          return Container(
            width: 2,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}
