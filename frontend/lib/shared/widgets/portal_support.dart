import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/routes/app_router.dart';
import 'app_button.dart';
import 'app_card.dart';

enum PortalToastType { info, success, warning, error }

void showPortalSnackBar(
  BuildContext context,
  String message, {
  PortalToastType? type,
  Duration duration = const Duration(seconds: 4),
}) {
  final toastContext = rootNavigatorKey.currentContext ?? context;
  final fToast = FToast()..init(toastContext);
  fToast.removeQueuedCustomToasts();
  fToast.removeCustomToast();

  final lowerMsg = message.toLowerCase();
  final resolvedType = type ??
      (lowerMsg.contains('error') || lowerMsg.contains('failed') || lowerMsg.contains('unable') || lowerMsg.contains('invalid')
          ? PortalToastType.error
          : (lowerMsg.contains('warn') || lowerMsg.contains('caution')
              ? PortalToastType.warning
              : (lowerMsg.contains('success') || lowerMsg.contains('saved') || lowerMsg.contains('updated') || lowerMsg.contains('approved') || lowerMsg.contains('tagged') || lowerMsg.contains('sent') || lowerMsg.contains('completed')
                  ? PortalToastType.success
                  : PortalToastType.info)));

  final IconData iconData;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;

  switch (resolvedType) {
    case PortalToastType.success:
      iconData = Icons.check_circle_rounded;
      bgColor = const Color(0xFF0F392B); // Deep Emerald Navy
      borderColor = const Color(0xFF10B981);
      iconColor = const Color(0xFF34D399);
      break;
    case PortalToastType.error:
      iconData = Icons.error_rounded;
      bgColor = const Color(0xFF3E1317); // Deep Crimson
      borderColor = const Color(0xFFEF4444);
      iconColor = const Color(0xFFF87171);
      break;
    case PortalToastType.warning:
      iconData = Icons.warning_rounded;
      bgColor = const Color(0xFF3C2607); // Deep Amber
      borderColor = const Color(0xFFF59E0B);
      iconColor = const Color(0xFFFBBF24);
      break;
    case PortalToastType.info:
      iconData = Icons.info_rounded;
      bgColor = AppColors.shieldNavy;
      borderColor = const Color(0xFF3B82F6);
      iconColor = const Color(0xFF60A5FA);
      break;
  }

  fToast.showToast(
    toastDuration: duration,
    fadeDuration: const Duration(milliseconds: 250),
    gravity: ToastGravity.TOP,
    isDismissible: true,
    child: SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTypography.body.copyWith(
                          color: AppColors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => fToast.removeCustomToast(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
  String? actionText,
  VoidCallback? onAction,
  String? secondaryActionText,
  VoidCallback? onSecondaryAction,
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
              if (actionText != null && onAction != null) ...[
                AppButton(text: actionText, onPressed: onAction),
                if (secondaryActionText != null &&
                    onSecondaryAction != null) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    text: secondaryActionText,
                    type: AppButtonType.outline,
                    onPressed: onSecondaryAction,
                  ),
                ],
                const SizedBox(height: 10),
              ],
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
