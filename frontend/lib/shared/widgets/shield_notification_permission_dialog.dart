import 'package:flutter/material.dart';
import '../services/notification_permission_coordinator.dart';

class ShieldNotificationPermissionDialog extends StatelessWidget {
  const ShieldNotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF0B9C78);
    const navyColor = Color(0xFF10213F);
    const grayColor = Color(0xFF64748B);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tealColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: tealColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Stay updated with SHIELD',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: navyColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Get important real-time updates about your orders, payments, prescriptions, and account activity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: grayColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await NotificationPermissionCoordinator.instance
                      .requestPermissionFromUserAction();
                },
                child: const Text(
                  'Enable Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: grayColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await NotificationPermissionCoordinator.instance
                      .deferPromptFromUserAction();
                },
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
