import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/routes/app_router.dart';
import 'app_button.dart';
import 'app_card.dart';

void showPortalSnackBar(BuildContext context, String message) {
  final toastContext = rootNavigatorKey.currentContext ?? context;
  final fToast = FToast()..init(toastContext);
  fToast.removeQueuedCustomToasts();
  fToast.removeCustomToast();
  fToast.showToast(
    toastDuration: const Duration(seconds: 5),
    fadeDuration: const Duration(milliseconds: 280),
    gravity: ToastGravity.TOP,
    isDismissible: true,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.shieldNavy.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.small.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> showPortalDetailsSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String meta,
  required String status,
  List<String> highlights = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.body.copyWith(color: AppColors.darkGray),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailChip(label: meta, color: AppColors.gray),
                  _DetailChip(label: status, color: AppColors.shieldBlue),
                ],
              ),
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portal Notes',
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...highlights.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.shieldGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton(text: 'Close', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    },
  );
}

class PortalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final VoidCallback onAction;

  const PortalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.shieldBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: AppColors.shieldBlue, size: 34),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.h4, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTypography.body.copyWith(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(text: actionText, onPressed: onAction),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
