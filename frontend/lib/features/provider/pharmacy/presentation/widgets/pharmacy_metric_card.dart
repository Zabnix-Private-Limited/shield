import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';

class PharmacyMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const PharmacyMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.onTap,
  });

  @override
  State<PharmacyMetricCard> createState() => _PharmacyMetricCardState();
}

class _PharmacyMetricCardState extends State<PharmacyMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onTap != null;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: PharmacyColors.surface,
          borderRadius: BorderRadius.circular(PharmacyRadius.card),
          border: Border.all(
            color: _isHovered && isClickable
                ? PharmacyColors.primary
                : PharmacyColors.border,
            width: _isHovered && isClickable ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isHovered && isClickable)
              BoxShadow(
                color: PharmacyColors.primary.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(PharmacyRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: PharmacyTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: PharmacyColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, size: 18, color: widget.iconColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        widget.value,
                        style: PharmacyTypography.h1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PharmacyColors.navy,
                        ),
                      ),
                      if (widget.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (widget.badgeColor ?? PharmacyColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(PharmacyRadius.chip),
                          ),
                          child: Text(
                            widget.badge!,
                            style: PharmacyTypography.tiny.copyWith(
                              color: widget.badgeColor ?? PharmacyColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: PharmacyTypography.tiny.copyWith(
                        color: widget.iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
