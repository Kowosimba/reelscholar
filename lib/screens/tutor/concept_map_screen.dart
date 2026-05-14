import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'widgets/tutor_widgets.dart';

class ConceptMapScreen extends StatefulWidget {
  final TutorModule module;

  const ConceptMapScreen({super.key, required this.module});

  @override
  State<ConceptMapScreen> createState() => _ConceptMapScreenState();
}

class _ConceptMapScreenState extends State<ConceptMapScreen> {
  final TransformationController _transformCtrl = TransformationController();
  ConceptNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorProvider>().loadConceptMap(widget.module.moduleId);
    });
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
              'Concept Map',
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
              Icons.center_focus_strong_rounded,
              color: TColors.textSecondary,
              size: 22,
            ),
            tooltip: 'Reset view',
            onPressed: _resetView,
          ),
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: TColors.textSecondary,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<TutorProvider>(
        builder: (_, prov, _) {
          if (prov.conceptMapState == TutorLoadState.loading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: TColors.primary,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Building concept map…',
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

          if (prov.conceptMapState == TutorLoadState.error) {
            return TutorEmptyState(
              icon: Icons.account_tree_outlined,
              title: 'Could not load concept map',
              subtitle: 'Start a tutor session to generate your concept map',
              actionLabel: 'Retry',
              onAction: () => prov.loadConceptMap(widget.module.moduleId),
            );
          }

          final map = prov.conceptMapFor(widget.module.moduleId);
          if (map == null || map.nodes.isEmpty) {
            return TutorEmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No concept map yet',
              subtitle:
                  'Complete topics with your AI tutor to build your personalised concept map',
            );
          }

          return Stack(
            children: [
              // ── Subtitle pill ───────────────────────────────────────────
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.module.name} · Generated by AI',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Graph canvas ────────────────────────────────────────────
              Positioned.fill(
                top: 44,
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 0.4,
                  maxScale: 3.0,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: SizedBox(
                    width: 900,
                    height: 700,
                    child: CustomPaint(
                      painter: _ConceptMapPainter(
                        nodes: map.nodes,
                        edges: map.edges,
                        selectedNodeId: _selectedNode?.id,
                      ),
                      child: Stack(children: [..._buildNodeWidgets(map)]),
                    ),
                  ),
                ),
              ),

              // ── Node detail sheet ───────────────────────────────────────
              if (_selectedNode != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _NodeDetailSheet(
                    node: _selectedNode!,
                    onClose: () => setState(() => _selectedNode = null),
                  ),
                ),

              // ── Zoom hint ───────────────────────────────────────────────
              Positioned(
                bottom: _selectedNode != null ? 190 : 20,
                right: 16,
                child: Column(
                  children: [
                    _ZoomButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        final m = _transformCtrl.value.clone();
                        m.scaleByDouble(1.2, 1.2, 1.0, 1.0);
                        _transformCtrl.value = m;
                      },
                    ),
                    const SizedBox(height: 8),
                    _ZoomButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        final m = _transformCtrl.value.clone();
                        m.scaleByDouble(0.8, 0.8, 1.0, 1.0);
                        _transformCtrl.value = m;
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildNodeWidgets(ConceptMap map) {
    final positions = _layoutNodes(map.nodes);
    return map.nodes.asMap().entries.map((entry) {
      final node = entry.value;
      final pos = positions[entry.key];
      return Positioned(
        left: pos.dx - 55,
        top: pos.dy - 28,
        child: GestureDetector(
          onTap: () => setState(
            () => _selectedNode = _selectedNode?.id == node.id ? null : node,
          ),
          child: _NodeWidget(
            node: node,
            isSelected: _selectedNode?.id == node.id,
          ),
        ),
      );
    }).toList();
  }

  /// Simple radial layout: root at centre, children in rings
  List<Offset> _layoutNodes(List<ConceptNode> nodes) {
    const cx = 450.0;
    const cy = 350.0;
    if (nodes.isEmpty) return [];
    if (nodes.length == 1) return [const Offset(cx, cy)];

    final positions = <Offset>[];
    // Root node at centre
    positions.add(const Offset(cx, cy));

    // Remaining nodes in concentric rings
    final remaining = nodes.length - 1;
    const ring1Count = 6;
    final ring1 = math.min(remaining, ring1Count);
    final ring2 = remaining - ring1;

    for (int i = 0; i < ring1; i++) {
      final angle = (2 * math.pi / ring1) * i - math.pi / 2;
      positions.add(
        Offset(cx + 180 * math.cos(angle), cy + 160 * math.sin(angle)),
      );
    }
    for (int i = 0; i < ring2; i++) {
      final angle = (2 * math.pi / (ring2 == 0 ? 1 : ring2)) * i - math.pi / 4;
      positions.add(
        Offset(cx + 340 * math.cos(angle), cy + 300 * math.sin(angle)),
      );
    }
    return positions;
  }
}

// ─── Node widget ──────────────────────────────────────────────────────────────
class _NodeWidget extends StatelessWidget {
  final ConceptNode node;
  final bool isSelected;

  const _NodeWidget({required this.node, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isRoot = node.type == 'module';
    final color = isRoot ? TColors.primary : TColors.secondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isRoot ? 130 : 110,
      padding: EdgeInsets.symmetric(
        horizontal: isRoot ? 14 : 10,
        vertical: isRoot ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? color
            : isRoot
            ? TColors.primarySubtle
            : Colors.white,
        borderRadius: BorderRadius.circular(isRoot ? 16 : 12),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        node.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: isRoot ? 12 : 11,
          fontWeight: isRoot ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? Colors.white
              : isRoot
              ? TColors.primary
              : TColors.textPrimary,
          height: 1.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Graph painter (draws edges) ──────────────────────────────────────────────
class _ConceptMapPainter extends CustomPainter {
  final List<ConceptNode> nodes;
  final List<String> edges;
  final String? selectedNodeId;

  _ConceptMapPainter({
    required this.nodes,
    required this.edges,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cx = 450.0;
    const cy = 350.0;
    if (nodes.isEmpty) return;

    final positions = _layout(nodes, cx, cy);
    final posMap = <String, Offset>{};
    for (int i = 0; i < nodes.length; i++) {
      posMap[nodes[i].id] = positions[i];
    }

    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw edges first
    for (final edge in edges) {
      final parts = edge.split('->').map((s) => s.trim()).toList();
      if (parts.length != 2) continue;
      final from = posMap[parts[0]];
      final to = posMap[parts[1]];
      if (from == null || to == null) continue;

      final isHighlighted =
          parts[0] == selectedNodeId || parts[1] == selectedNodeId;
      paint.color = isHighlighted
          ? TColors.primary.withValues(alpha: 0.8)
          : TColors.border;
      paint.strokeWidth = isHighlighted ? 2 : 1.5;

      // Curved connector
      final path = Path();
      path.moveTo(from.dx, from.dy);
      final ctrl = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 - 30);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
      canvas.drawPath(path, paint);

      // Arrow tip
      _drawArrow(canvas, from, to, paint);
    }

    // Draw dots at node centres
    for (int i = 0; i < nodes.length; i++) {
      final pos = positions[i];
      final dotPaint = Paint()
        ..color = nodes[i].type == 'module'
            ? TColors.primary
            : TColors.secondary.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 4, dotPaint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowLen = 8.0;
    const arrowAngle = 0.4;
    final tip = to;
    final a1 = Offset(
      tip.dx - arrowLen * math.cos(angle - arrowAngle),
      tip.dy - arrowLen * math.sin(angle - arrowAngle),
    );
    final a2 = Offset(
      tip.dx - arrowLen * math.cos(angle + arrowAngle),
      tip.dy - arrowLen * math.sin(angle + arrowAngle),
    );
    canvas.drawLine(tip, a1, paint);
    canvas.drawLine(tip, a2, paint);
  }

  List<Offset> _layout(List<ConceptNode> nodes, double cx, double cy) {
    if (nodes.isEmpty) return [];
    if (nodes.length == 1) return [Offset(cx, cy)];
    final positions = <Offset>[Offset(cx, cy)];
    final remaining = nodes.length - 1;
    const ring1Count = 6;
    final ring1 = math.min(remaining, ring1Count);
    final ring2 = remaining - ring1;
    for (int i = 0; i < ring1; i++) {
      final angle = (2 * math.pi / ring1) * i - math.pi / 2;
      positions.add(
        Offset(cx + 180 * math.cos(angle), cy + 160 * math.sin(angle)),
      );
    }
    for (int i = 0; i < ring2; i++) {
      final angle = (2 * math.pi / (ring2 == 0 ? 1 : ring2)) * i - math.pi / 4;
      positions.add(
        Offset(cx + 340 * math.cos(angle), cy + 300 * math.sin(angle)),
      );
    }
    return positions;
  }

  @override
  bool shouldRepaint(_ConceptMapPainter old) =>
      old.selectedNodeId != selectedNodeId || old.nodes.length != nodes.length;
}

// ─── Node detail sheet ────────────────────────────────────────────────────────
class _NodeDetailSheet extends StatelessWidget {
  final ConceptNode node;
  final VoidCallback onClose;

  const _NodeDetailSheet({required this.node, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  color: node.type == 'module'
                      ? TColors.primarySubtle
                      : TColors.secondarySubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.type.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: node.type == 'module'
                        ? TColors.primary
                        : TColors.secondary,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: TColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            node.label,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TColors.textPrimary,
            ),
          ),
          if (node.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              node.summary,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: TColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Zoom button ──────────────────────────────────────────────────────────────
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: TColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: TColors.textSecondary),
      ),
    );
  }
}
