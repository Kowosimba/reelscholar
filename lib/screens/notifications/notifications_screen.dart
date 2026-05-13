import 'package:flutter/material.dart';
import 'package:reelscholar/providers/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // Mock notification data — replace with API data from GET /notifications
  static final _all = [
    _Notif(
      id: '1',
      type: _NotifType.like,
      title: 'Amara Osei',
      body: 'liked your reel on Newton\'s Laws',
      timeLabel: '2m ago',
      isRead: false,
    ),
    _Notif(
      id: '2',
      type: _NotifType.achievement,
      title: 'Leaderboard',
      body: '🏆 You ranked #4 on the Faculty Leaderboard this week!',
      timeLabel: '1h ago',
      isRead: false,
    ),
    _Notif(
      id: '3',
      type: _NotifType.comment,
      title: 'James Mutasa',
      body: 'commented on your reel: "Great explanation!"',
      timeLabel: '3h ago',
      isRead: false,
    ),
    _Notif(
      id: '4',
      type: _NotifType.learning,
      title: 'Daily Streak',
      body:
          '🔥 Keep it up! You\'re on a 12-day streak. Study today to maintain it.',
      timeLabel: '6h ago',
      isRead: true,
    ),
    _Notif(
      id: '5',
      type: _NotifType.follow,
      title: 'Dr. Sarah Williams',
      body: 'started following you',
      timeLabel: '1d ago',
      isRead: true,
    ),
    _Notif(
      id: '6',
      type: _NotifType.learning,
      title: 'Module Progress',
      body: 'You\'re 72% through Forces & Motion. Complete it this week!',
      timeLabel: '2d ago',
      isRead: true,
    ),
    _Notif(
      id: '7',
      type: _NotifType.system,
      title: 'ReelScholar',
      body:
          'New hackathon available: Physics Innovation Challenge. Closes in 3 days.',
      timeLabel: '3d ago',
      isRead: true,
    ),
  ];

  List<_Notif> _filtered(String tab) {
    switch (tab) {
      case 'Social':
        return _all
            .where(
              (n) => [
                _NotifType.like,
                _NotifType.comment,
                _NotifType.follow,
              ].contains(n.type),
            )
            .toList();
      case 'Learning':
        return _all.where((n) => n.type == _NotifType.learning).toList();
      case 'System':
        return _all
            .where(
              (n) =>
                  [_NotifType.system, _NotifType.achievement].contains(n.type),
            )
            .toList();
      default:
        return _all;
    }
  }

  void _markAllRead() {
    setState(() {
      for (final n in _all) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _all.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontFamily: AppFonts.sora,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppFonts.dmSans,
            fontSize: 12,
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Social'),
            Tab(text: 'Learning'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: ['All', 'Social', 'Learning', 'System'].map((tab) {
          final items = _filtered(tab);
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 52,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No $tab notifications',
                    style: const TextStyle(
                      fontFamily: AppFonts.sora,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(color: AppColors.border, height: 1),
            itemBuilder: (_, i) => _NotifTile(
              notif: items[i],
              onTap: () => setState(() => items[i].isRead = true),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: notif.isRead
            ? AppColors.white
            : AppColors.primarySubtle.withValues(alpha: 0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg(notif.type),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _emoji(notif.type),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: AppFonts.dmSans,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                      children: [
                        TextSpan(
                          text: '${notif.title} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: notif.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notif.timeLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.dmSans,
                      fontSize: 11,
                      color: notif.isRead
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      fontWeight: notif.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Unread dot
            if (!notif.isRead)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _iconBg(_NotifType t) {
    switch (t) {
      case _NotifType.like:
        return AppColors.errorLight;
      case _NotifType.comment:
        return AppColors.primarySubtle;
      case _NotifType.follow:
        return AppColors.successLight;
      case _NotifType.achievement:
        return AppColors.warningLight;
      case _NotifType.learning:
        return AppColors.primarySubtle;
      case _NotifType.system:
        return AppColors.muted;
    }
  }

  String _emoji(_NotifType t) {
    switch (t) {
      case _NotifType.like:
        return '❤️';
      case _NotifType.comment:
        return '💬';
      case _NotifType.follow:
        return '👤';
      case _NotifType.achievement:
        return '🏆';
      case _NotifType.learning:
        return '📚';
      case _NotifType.system:
        return '🔔';
    }
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────
enum _NotifType { like, comment, follow, achievement, learning, system }

class _Notif {
  final String id;
  final _NotifType type;
  final String title;
  final String body;
  final String timeLabel;
  bool isRead;

  _Notif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.isRead,
  });
}
