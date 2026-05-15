// lib/features/social/screens/user_search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/social_provider.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/screens/social/user_tile.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadSuggestions();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      context.read<SocialProvider>().clearSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<SocialProvider>().search(value.trim());
    });
  }

  void _clearSearch() {
    _ctrl.clear();
    context.read<SocialProvider>().clearSearch();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _SearchBar(
          ctrl: _ctrl,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onClear: _clearSearch,
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _FilterChips(),

          // Divider
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // Results or suggestions
          Expanded(
            child: Consumer<SocialProvider>(
              builder: (_, p, _) {
                // Active search
                if (_ctrl.text.trim().length >= 2) {
                  if (p.searchLoading) {
                    return const _SearchShimmer();
                  }
                  if (p.searchError != null) {
                    return _ErrorState(
                        message: p.searchError!,
                        onRetry: () =>
                            p.search(_ctrl.text.trim()));
                  }
                  if (p.searchResults.isEmpty) {
                    return _EmptySearch(query: _ctrl.text.trim());
                  }
                  return _UserList(
                    users: p.searchResults,
                    label:
                        '${p.searchResults.length} result${p.searchResults.length == 1 ? '' : 's'}',
                  );
                }

                // Suggestions (idle)
                if (p.suggestionsLoading) {
                  return const _SearchShimmer();
                }
                if (p.suggestions.isNotEmpty) {
                  return _UserList(
                    users: p.suggestions,
                    label: 'Suggested for you',
                    showSectionLabel: true,
                  );
                }

                // Prompt
                return const _SearchPrompt();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.ctrl,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Search by name, ID, or faculty…',
                hintStyle: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: ctrl,
            builder: (_, val, _) => val.text.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.cancel_rounded,
                        size: 18, color: AppColors.textTertiary),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All'),
      ('students', 'Students'),
      ('lecturers', 'Lecturers'),
      ('faculty_only', 'My Faculty'),
    ];
    return Consumer<SocialProvider>(
      builder: (_, p, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: filters.map((f) {
            final active = p.searchFilter == f.$1;
            return GestureDetector(
              onTap: () => p.setFilter(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── User list ─────────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final List<AppUser> users;
  final String label;
  final bool showSectionLabel;

  const _UserList({
    required this.users,
    required this.label,
    this.showSectionLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length + 1,
      separatorBuilder: (_, i) => i == 0
          ? const SizedBox.shrink()
          : const Divider(
              height: 1, indent: 70, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
          );
        }
        return UserTile(user: users[i - 1]);
      },
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Find people on ReelScholar',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by name, student ID, or faculty',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 44, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different name, ID, or faculty',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 13,
                      width: 130,
                      color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 6),
                  Container(
                      height: 11,
                      width: 190,
                      color: const Color(0xFFF1F5F9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




