import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/providers/notification_provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/models/notification_model.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<NotificationProvider>();
      await prov.load();
      if (!mounted) return;
      context
          .read<NavigationProvider>()
          .setUnreadNotifications(prov.unreadCount);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AppNotification> _filtered(
      List<AppNotification> all, String tab) {
    switch (tab) {
      case 'Social':
        return all
            .where((n) => [
                  NotifType.like,
                  NotifType.comment,
                  NotifType.follow,
                ].contains(n.type))
            .toList();
      case 'Learning':
        return all.where((n) => n.type == NotifType.learning).toList();
      case 'System':
        return all
            .where((n) =>
                [NotifType.system, NotifType.achievement].contains(n.type))
            .toList();
      default:
        return all;
    }
  }

  Future<void> _markAllRead() async {
    final prov = context.read<NotificationProvider>();
    await prov.markAllRead();
    if (!mounted) return;
    context.read<NavigationProvider>().setUnreadNotifications(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, prov, _) {
        final unreadCount = prov.unreadCount;

        return Scaffold(
          appBar: AppBar(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
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
          body: _buildBody(prov),
        );
      },
    );
  }

  Widget _buildBody(NotificationProvider prov) {
    if (prov.loading && prov.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (prov.error != null && prov.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 52, color: AppColors.textTertiary),
              const SizedBox(height: 14),
              Text(
                prov.error!,
                style: const TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  context.read<NotificationProvider>().load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabCtrl,
      children: ['All', 'Social', 'Learning', 'System'].map((tab) {
        final items = _filtered(prov.notifications, tab);
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
            onTap: () async {
              final prov = context.read<NotificationProvider>();
              if (!items[i].isRead) {
                await prov.markRead([items[i].id]);
                if (mounted) {
                  context
                      .read<NavigationProvider>()
                      .setUnreadNotifications(prov.unreadCount);
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final AppNotification notif;
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

  Color _iconBg(NotifType t) => switch (t) {
        NotifType.like => AppColors.errorLight,
        NotifType.comment => AppColors.primarySubtle,
        NotifType.follow => AppColors.successLight,
        NotifType.achievement => AppColors.warningLight,
        NotifType.learning => AppColors.primarySubtle,
        NotifType.system => AppColors.muted,
      };

  String _emoji(NotifType t) => switch (t) {
        NotifType.like => '❤️',
        NotifType.comment => '💬',
        NotifType.follow => '👤',
        NotifType.achievement => '🏆',
        NotifType.learning => '📚',
        NotifType.system => '🔔',
      };
}
