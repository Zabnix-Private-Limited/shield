import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/notification.dart';
import '../../../../../shared/widgets/app_card.dart';

class NotificationsCard extends StatelessWidget {
  const NotificationsCard({super.key, required this.notifications});

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: AppTypography.h4),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            Text(
              'No recent notifications.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            )
          else
            ...notifications
                .take(2)
                .map(
                  (notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
