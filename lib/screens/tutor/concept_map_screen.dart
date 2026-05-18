import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:reelscholar/models/concept_map_models.dart';
import 'package:reelscholar/services/concept_map_service.dart';
import 'widgets/tutor_widgets.dart';

/// Force-directed concept map renderer.
///
/// Layout: Fruchterman-Reingold with 220 iterations on screen init.
/// Pan and zoom with InteractiveViewer. Tap a node to see its description.
class ConceptMapScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const ConceptMapScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<ConceptMapScreen> createState() => _ConceptMapScreenState();
}

class _ConceptMapScreenState extends State<ConceptMapScreen> {
  ConceptMap? _map;
  Map<String, Offset> _positions = {};
  bool _loading = true;
  String? _error;
  String? _selectedNodeId;
  NodeKind? _filterKind;
  late final TransformationController _transformCtrl;

  static const double _canvasW = 1200;
  static const double _canvasH = 1200;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
    _load();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final map = await ConceptMapService().get(widget.moduleId);
      _map = map;
      _positions = _layoutForceDirected(map);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        final scale = (size.shortestSide / _canvasW).clamp(0.2, 0.75);
        _transformCtrl.value = Matrix4.diagonal3Values(scale, scale, 1.0);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _loading = true);
    try {
      final map = await ConceptMapService().regenerate(widget.moduleId);
      _map = map;
      _positions = _layoutForceDirected(map);
      _selectedNodeId = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, Offset> _layoutForceDirected(ConceptMap map) {
    final rng = math.Random(42);
    final positions = <String, Offset>{};
    final disp = <String, Offset>{};

    for (final node in map.nodes) {
      positions[node.id] = Offset(
        rng.nextDouble() * _canvasW,
        rng.nextDouble() * _canvasH,
      );
    }

    if (map.nodes.isEmpty) return positions;

    final area = _canvasW * _canvasH;
    final k = math.sqrt(area / map.nodes.length);
    double temperature = _canvasW / 10;
    const iterations = 220;

    for (int i = 0; i < iterations; i++) {
      for (final n in map.nodes) {
        disp[n.id] = Offset.zero;
      }

      // Repulsive forces
      for (final v in map.nodes) {
        for (final u in map.nodes) {
          if (u.id == v.id) continue;
          final delta = positions[v.id]! - positions[u.id]!;
          final dist = math.max(delta.distance, 0.01);
          final force = (k * k) / dist;
          disp[v.id] = disp[v.id]! + (delta / dist) * force;
        }
      }

      // Attractive forces along edges
      for (final e in map.edges) {
        final pFrom = positions[e.from];
        final pTo = positions[e.to];
        if (pFrom == null || pTo == null) continue;
        final delta = pFrom - pTo;
        final dist = math.max(delta.distance, 0.01);
        final force = (dist * dist) / k;
        final pull = (delta / dist) * force;
        disp[e.from] = disp[e.from]! - pull;
        disp[e.to] = disp[e.to]! + pull;
      }

      // Apply with temperature-limited step
      for (final n in map.nodes) {
        final d = disp[n.id]!;
        final dist = math.max(d.distance, 0.01);
        final capped = (d / dist) * math.min(dist, temperature);
        var p = positions[n.id]! + capped;
        p = Offset(
          p.dx.clamp(60.0, _canvasW - 60),
          p.dy.clamp(60.0, _canvasH - 60),
        );
        positions[n.id] = p;
      }

      temperature = math.max(temperature * 0.96, 0.5);
    }

    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0D12) : const Color(0xFFF4F6FA);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: widget.moduleName,
              subtitle: _map?.title ?? 'Concept map',
              onClose: () => Navigator.of(context).pop(),
              onRegenerate: _loading ? null : _regenerate,
              isDark: isDark,
            ),
            _FilterBar(
              current: _filterKind,
              onChange: (k) => setState(() => _filterKind = k),
              isDark: isDark,
            ),
            Expanded(child: _buildBody(isDark)),
            if (_selectedNodeId != null && _map != null)
              _NodeDetailPanel(
                node: _map!.nodes.firstWhere(
                  (n) => n.id == _selectedNodeId,
                  orElse: () => _map!.nodes.first,
                ),
                edges: _map!.edges
                    .where((e) =>
                        e.from == _selectedNodeId || e.to == _selectedNodeId)
                    .toList(),
                nodeLookup: {for (final n in _map!.nodes) n.id: n.label},
                onClose: () => setState(() => _selectedNodeId = null),
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: TColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_map == null || _map!.nodes.isEmpty) {
      return const Center(child: Text('No concept map available'));
    }

    return InteractiveViewer(
      constrained: false,
      transformationController: _transformCtrl,
      minScale: 0.15,
      maxScale: 4,
      boundaryMargin: const EdgeInsets.all(500),
      child: SizedBox(
        width: _canvasW,
        height: _canvasH,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(_canvasW, _canvasH),
              painter: _EdgesPainter(
                edges: _map!.edges,
                positions: _positions,
                filterKind: _filterKind,
                nodeKinds: {for (final n in _map!.nodes) n.id: n.kind},
                isDark: isDark,
              ),
            ),
            ..._map!.nodes.map((node) {
              final pos = _positions[node.id];
              if (pos == null) return const SizedBox.shrink();
              final dimmed = _filterKind != null && node.kind != _filterKind;
              final r = _nodeRadius(node.importance);
              return Positioned(
                left: pos.dx - r,
                top: pos.dy - r,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedNodeId = node.id),
                  child: _NodeChip(
                    node: node,
                    selected: _selectedNodeId == node.id,
                    dimmed: dimmed,
                    isDark: isDark,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static double _nodeRadius(int importance) => switch (importance) {
        3 => 48,
        2 => 40,
        _ => 32,
      };
}

// ── Edge painter ─────────────────────────────────────────────────────────

class _EdgesPainter extends CustomPainter {
  final List<ConceptEdge> edges;
  final Map<String, Offset> positions;
  final NodeKind? filterKind;
  final Map<String, NodeKind> nodeKinds;
  final bool isDark;

  const _EdgesPainter({
    required this.edges,
    required this.positions,
    required this.filterKind,
    required this.nodeKinds,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final from = positions[e.from];
      final to = positions[e.to];
      if (from == null || to == null) continue;

      final fromKind = nodeKinds[e.from];
      final toKind = nodeKinds[e.to];
      final dimmed =
          filterKind != null && fromKind != filterKind && toKind != filterKind;

      final baseColor = _edgeColor(e.relation);
      final color = baseColor.withValues(alpha: dimmed ? 0.08 : 0.5);
      final paint = Paint()
        ..color = color
        ..strokeWidth = dimmed ? 1.0 : 1.8
        ..style = PaintingStyle.stroke;

      if (_isDashed(e.relation)) {
        _drawDashed(canvas, from, to, paint);
      } else {
        canvas.drawLine(from, to, paint);
      }

      if (!dimmed) _drawArrowHead(canvas, from, to, baseColor);
    }
  }

  Color _edgeColor(EdgeRelation r) => switch (r) {
        EdgeRelation.isA => const Color(0xFF6366F1),
        EdgeRelation.partOf => const Color(0xFF0EA5E9),
        EdgeRelation.causes => const Color(0xFFEF4444),
        EdgeRelation.dependsOn => const Color(0xFFF59E0B),
        EdgeRelation.contrastsWith => const Color(0xFFEC4899),
        EdgeRelation.exampleOf => const Color(0xFF14B8A6),
        EdgeRelation.appliesTo => const Color(0xFF8B5CF6),
        EdgeRelation.precedes => const Color(0xFF10B981),
      };

  bool _isDashed(EdgeRelation r) =>
      r == EdgeRelation.contrastsWith || r == EdgeRelation.appliesTo;

  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    double covered = 0;
    while (covered < total) {
      final start = from + dir * covered;
      final end = from + dir * math.min(covered + dashLen, total);
      canvas.drawLine(start, end, paint);
      covered += dashLen + gapLen;
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final dir = to - from;
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    final tip = to - unit * 36;
    final left = tip + Offset(-unit.dy, unit.dx) * 4 - unit * 6;
    final right = tip + Offset(unit.dy, -unit.dx) * 4 - unit * 6;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      old.edges != edges ||
      old.positions != positions ||
      old.filterKind != filterKind;
}

// ── Node chip ────────────────────────────────────────────────────────────

class _NodeChip extends StatelessWidget {
  final ConceptNode node;
  final bool selected;
  final bool dimmed;
  final bool isDark;

  const _NodeChip({
    required this.node,
    required this.selected,
    required this.dimmed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _kindStyle(node.kind);
    final r = _ConceptMapScreenState._nodeRadius(node.importance);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.25 : 1,
      child: Transform.scale(
        scale: dimmed ? 0.9 : 1.0,
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.75)],
            ),
            border: Border.all(
              color: selected ? Colors.white : color.withValues(alpha: 0.3),
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.5 : 0.25),
                blurRadius: selected ? 24 : 12,
                spreadRadius: selected ? 4 : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: r * 0.32),
              const SizedBox(height: 2),
              Text(
                node.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: r * 0.18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _kindStyle(NodeKind k) => switch (k) {
        NodeKind.concept => (const Color(0xFF6366F1), Icons.lightbulb_rounded),
        NodeKind.process => (const Color(0xFF10B981), Icons.sync_rounded),
        NodeKind.principle => (const Color(0xFFEF4444), Icons.gavel_rounded),
        NodeKind.example =>
          (const Color(0xFFEC4899), Icons.format_quote_rounded),
        NodeKind.tool => (const Color(0xFFF59E0B), Icons.build_rounded),
        NodeKind.topic => (const Color(0xFF0EA5E9), Icons.bookmark_rounded),
      };
}

// ── Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final VoidCallback? onRegenerate;
  final bool isDark;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.onRegenerate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? TColors.darkCard : TColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.white70 : TColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRegenerate,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? TColors.darkCard : TColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: onRegenerate == null
                    ? Colors.grey
                    : (isDark ? Colors.white70 : TColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final NodeKind? current;
  final ValueChanged<NodeKind?> onChange;
  final bool isDark;

  const _FilterBar({
    required this.current,
    required this.onChange,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _chip('All', null),
            for (final kind in NodeKind.values) _chip(kind.label, kind),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, NodeKind? kind) {
    final active = current == kind;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onChange(kind),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? TColors.primary
                : (isDark ? TColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? TColors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Node detail panel ────────────────────────────────────────────────────

class _NodeDetailPanel extends StatelessWidget {
  final ConceptNode node;
  final List<ConceptEdge> edges;
  final Map<String, String> nodeLookup;
  final VoidCallback onClose;
  final bool isDark;

  const _NodeDetailPanel({
    required this.node,
    required this.edges,
    required this.nodeLookup,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.6);
    final kindColor = _kindColor(node.kind);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.kind.label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kindColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close_rounded, size: 18, color: subColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            node.label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (node.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              node.description,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: subColor,
                height: 1.4,
              ),
            ),
          ],
          if (edges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 10),
            Text(
              'CONNECTIONS',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: subColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: edges.map((e) {
                  final otherId = e.from == node.id ? e.to : e.from;
                  final outgoing = e.from == node.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          outgoing
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          size: 14,
                          color: subColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.relation.label,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nodeLookup[otherId] ?? otherId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _kindColor(NodeKind k) => switch (k) {
        NodeKind.concept => const Color(0xFF6366F1),
        NodeKind.process => const Color(0xFF10B981),
        NodeKind.principle => const Color(0xFFEF4444),
        NodeKind.example => const Color(0xFFEC4899),
        NodeKind.tool => const Color(0xFFF59E0B),
        NodeKind.topic => const Color(0xFF0EA5E9),
      };
}
