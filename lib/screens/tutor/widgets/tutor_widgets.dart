import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:reelscholar/models/tutor_models.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class TColors {
  // Brand
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primarySubtle = Color(0xFFCCFBF1);
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondarySubtle = Color(0xFFEDE9FE);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Surfaces
  static const Color bg = Color(0xFFF0FDF9);
  static const Color white = Colors.white;
  static const Color muted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Dark surfaces (chat)
  static const Color dark = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkMuted = Color(0xFF64748B);

  // Module accent colours (assigned by hash of module code)
  static const List<Color> accents = [
    Color(0xFF0D9488), // teal
    Color(0xFF6366F1), // indigo
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFF22C55E), // green
    Color(0xFFEC4899), // pink
    Color(0xFF3B82F6), // blue
  ];

  static Color accentFor(String code) {
    final idx = code.codeUnits.fold(0, (a, b) => a + b) % accents.length;
    return accents[idx];
  }
}

// ─── Module card (light) ──────────────────────────────────────────────────────
class ModuleCard extends StatelessWidget {
  final TutorModule module;
  final VoidCallback onTap;

  const ModuleCard({super.key, required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = TColors.accentFor(module.code);
    final progress = module.progressPercentage / 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Module icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(module.code), size: 22, color: accent),
            ),

            const SizedBox(width: 14),

            // Name + code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.code,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: TColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProgressBar(progress: progress, color: accent),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Progress % + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${module.progressPercentage.toInt()}%',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.isCompleted ? 'complete' : 'done',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
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

  IconData _iconFor(String code) {
    final lower = code.toLowerCase();
    if (lower.contains('phy')) return Icons.science_outlined;
    if (lower.contains('mat') || lower.contains('calc')) {
      return Icons.functions_outlined;
    }
    if (lower.contains('cs') || lower.contains('dat')) {
      return Icons.code_outlined;
    }
    if (lower.contains('chem')) return Icons.biotech_outlined;
    if (lower.contains('bio')) return Icons.eco_outlined;
    if (lower.contains('eng')) return Icons.engineering_outlined;
    return Icons.menu_book_outlined;
  }
}

// ─── Dark variant (for dark mode modules screen) ──────────────────────────────
class ModuleCardDark extends StatelessWidget {
  final TutorModule module;
  final VoidCallback onTap;

  const ModuleCardDark({super.key, required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = TColors.accentFor(module.code);
    final progress = module.progressPercentage / 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TColors.darkBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.menu_book_outlined, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.code,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: TColors.darkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dark progress bar
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: TColors.darkBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${module.progressPercentage.toInt()}%',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    switch (status) {
      case 'completed':
        bg = TColors.successLight;
        fg = TColors.success;
        label = 'Completed';
        break;
      case 'in_progress':
        bg = TColors.primarySubtle;
        fg = TColors.primary;
        label = 'In Progress';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = TColors.textTertiary;
        label = 'Not Started';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress; // 0–1
  final Color color;

  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: [
          Container(
            height: 5,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: TColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            height: 5,
            width: constraints.maxWidth * progress.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circular progress arc ────────────────────────────────────────────────────
class ProgressArc extends StatelessWidget {
  final double progress; // 0–1
  final double size;
  final Color color;
  final Widget? child;

  const ProgressArc({
    super.key,
    required this.progress,
    this.size = 64,
    required this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              progress: progress,
              color: color,
              bgColor: TColors.border,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class TutorEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TutorEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: TColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: TColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: TColors.textSecondary,
                height: 1.55,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Suggested prompt chip ────────────────────────────────────────────────────
class SuggestedPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestedPromptChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: TColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TColors.darkBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: TColors.darkMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: TColors.textTertiary,
              letterSpacing: 0.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: TColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
