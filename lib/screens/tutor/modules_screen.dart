import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'widgets/tutor_widgets.dart';
import 'module_detail_screen.dart';

class ModulesScreen extends StatefulWidget {
  /// Opens the app drawer when embedded in [MainScreen].
  final VoidCallback? onMenuTap;

  const ModulesScreen({super.key, this.onMenuTap});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final _searchCtrl = TextEditingController();

  static const _filters = [
    ('all', 'All'),
    ('in_progress', 'In Progress'),
    ('completed', 'Completed'),
    ('not_started', 'Not Started'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorProvider>().loadModules();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? TColors.darkText : TColors.textPrimary;
    final subColor = isDark ? TColors.darkMuted : TColors.textSecondary;
    final searchBg = isDark ? TColors.darkCard : TColors.muted;
    final searchIcon = isDark ? TColors.darkMuted : TColors.textTertiary;

    return Scaffold(
      body: SafeArea(
        child: Consumer<TutorProvider>(
          builder: (_, prov, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      if (widget.onMenuTap != null) ...[
                        GestureDetector(
                          onTap: widget.onMenuTap,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? TColors.darkCard
                                  : TColors.primarySubtle,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_rounded,
                              size: 20,
                              color: isDark
                                  ? TColors.darkText
                                  : TColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Modules',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subtitle(prov),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (prov.modulesState == TutorLoadState.loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TColors.primary,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => prov.loadModules(refresh: true),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? TColors.darkCard
                                  : TColors.primarySubtle,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: isDark ? TColors.darkText : TColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Search bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: searchIcon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search modules, topics…',
                              hintStyle: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                color: searchIcon,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (q) => prov.setSearchQuery(q),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              prov.setSearchQuery('');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: searchIcon,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Filter tabs ───────────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final (key, label) = _filters[i];
                      final active = prov.moduleFilter == key;
                      return GestureDetector(
                        onTap: () => prov.setFilter(key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? TColors.primary
                                : isDark
                                ? TColors.darkCard
                                : TColors.muted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? TColors.primary
                                  : isDark
                                  ? TColors.darkBorder
                                  : TColors.border,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : isDark
                                  ? TColors.darkMuted
                                  : TColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Body ──────────────────────────────────────────────────
                Expanded(child: _buildBody(prov)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(TutorProvider prov) {
    if (prov.modulesState == TutorLoadState.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: TColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (prov.modulesState == TutorLoadState.error) {
      return TutorEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load modules',
        subtitle: prov.modulesError ?? 'Check your connection and try again',
        actionLabel: 'Retry',
        onAction: () => prov.loadModules(refresh: true),
      );
    }

    if (prov.modulesState == TutorLoadState.idle) {
      return const SizedBox.shrink();
    }

    final modules = prov.filteredModules;

    if (modules.isEmpty) {
      return TutorEmptyState(
        icon: Icons.school_outlined,
        title: 'No modules found',
        subtitle: prov.searchQuery.isNotEmpty
            ? 'No results for "${prov.searchQuery}"'
            : 'No modules match the selected filter',
      );
    }

    // Group by year → semester
    final response = prov.modulesResponse!;
    final grouped = response.grouped;
    final years = grouped.keys.toList()..sort();

    return RefreshIndicator(
      color: TColors.primary,
      onRefresh: () => prov.loadModules(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          for (final year in years) ...[
            for (final semester in (grouped[year]!.keys.toList()..sort())) ...[
              SectionHeader(
                title: 'Year $year · Semester $semester',
                subtitle:
                    '${grouped[year]![semester]!.length} module${grouped[year]![semester]!.length == 1 ? '' : 's'}',
              ),
              ...grouped[year]![semester]!
                  .where((m) => prov.filteredModules.contains(m))
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ModuleCard(module: m, onTap: () => _openModule(m)),
                    ),
                  ),
            ],
          ],

          // Related modules section
          if (response.relatedModules.isNotEmpty) ...[
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Also Available',
              subtitle: 'From other programmes',
            ),
            ...response.relatedModules.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ModuleCard(module: m, onTap: () => _openModule(m)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openModule(TutorModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<TutorProvider>(),
          child: ModuleDetailScreen(module: module),
        ),
      ),
    );
  }

  String _subtitle(TutorProvider prov) {
    final total = prov.modulesResponse?.currentModules.length ?? 0;
    final inProg =
        prov.modulesResponse?.currentModules
            .where((m) => m.isInProgress)
            .length ??
        0;
    if (total == 0) return 'Loading…';
    return '$total modules · $inProg in progress';
  }
}
