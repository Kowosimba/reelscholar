import 'package:flutter/material.dart';
import 'package:reelscholar/app_router.dart';

class NotificationRouter {
  static void route(Map<String, dynamic> data, BuildContext context) {
    final routeName = data['route'] as String?;
    if (routeName == null) return;

    switch (routeName) {
      case 'reel_detail':
        final reelId = data['reel_id']?.toString();
        if (reelId != null) {
          Navigator.pushNamed(context, AppRouter.reelDetail, arguments: reelId);
        }

      case 'profile':
        final userId = data['user_id']?.toString() ?? '';
        Navigator.pushNamed(context, AppRouter.publicProfile, arguments: userId);

      case 'study_group_detail':
      case 'study_group_join_requests':
        Navigator.pushNamed(context, AppRouter.studyGroups);

      case 'study_group_invites':
        Navigator.pushNamed(context, AppRouter.studyGroups);

      case 'hackathon_detail':
        final hackId = data['hackathon_id']?.toString() ?? '';
        Navigator.pushNamed(context, '/hackathon-detail', arguments: hackId);

      case 'hackathon_vote':
        final hackId = data['hackathon_id']?.toString() ?? '';
        Navigator.pushNamed(context, '/hackathon-detail', arguments: hackId);

      case 'hackathon_leaderboard':
        final hackId = data['hackathon_id']?.toString() ?? '';
        if (hackId.isNotEmpty) {
          Navigator.pushNamed(context, '/hackathon-detail', arguments: hackId);
        } else {
          Navigator.pushNamed(context, AppRouter.leaderboard);
        }

      case 'notifications':
        Navigator.pushNamed(context, AppRouter.notifications);
    }
  }
}
