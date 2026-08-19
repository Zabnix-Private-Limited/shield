import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';

class PharmacyStatusChip extends StatelessWidget {
  final String status;
  final String? label;
  final bool compact;

  const PharmacyStatusChip({
    super.key,
    required this.status,
    this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toUpperCase();
    final textLabel = label ?? _formatStatus(s);

    Color bg;
    Color fg;

    switch (s) {
      case 'NEW':
      case 'PLACED':
        bg = PharmacyColors.infoBg;
        fg = PharmacyColors.infoText;
        break;
      case 'ACCEPTED':
        bg = PharmacyColors.primarySoft;
        fg = PharmacyColors.primaryHover;
        break;
      case 'PARTIAL_REVIEW':
      case 'PARTIALLY_APPROVED':
      case 'PARTIAL':
        bg = PharmacyColors.purpleBg;
        fg = PharmacyColors.purple;
        break;
      case 'PREPARING':
      case 'PENDING':
        bg = PharmacyColors.warningBg;
        fg = PharmacyColors.warningText;
        break;
      case 'READY':
      case 'READY_FOR_PICKUP':
      case 'APPROVED':
      case 'FULL_STOCK':
        bg = PharmacyColors.successBg;
        fg = PharmacyColors.successText;
        break;
      case 'DELIVERY':
      case 'OUT_FOR_DELIVERY':
        bg = PharmacyColors.purpleBg;
        fg = PharmacyColors.purple;
        break;
      case 'COMPLETED':
        bg = PharmacyColors.primarySoft;
        fg = PharmacyColors.primaryHover;
        break;
      case 'CANCELLED':
      case 'REJECTED':
      case 'OUT_OF_STOCK':
        bg = PharmacyColors.dangerBg;
        fg = PharmacyColors.dangerText;
        break;
      case 'LOW_STOCK':
        bg = PharmacyColors.warningBg;
        fg = PharmacyColors.warningText;
        break;
      case 'SUBSTITUTED':
        bg = PharmacyColors.infoBg;
        fg = PharmacyColors.infoText;
        break;
      case 'AWAITING_CUSTOMER_CONFIRMATION':
      case 'AWAITING_CONFIRMATION':
        bg = PharmacyColors.warningBg;
        fg = PharmacyColors.warningText;
        break;
      default:
        bg = PharmacyColors.border;
        fg = PharmacyColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(PharmacyRadius.chip),
      ),
      child: Text(
        textLabel,
        style: (compact ? PharmacyTypography.tiny : PharmacyTypography.caption).copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'NEW':
        return 'New Order';
      case 'ACCEPTED':
        return 'Accepted';
      case 'PARTIAL_REVIEW':
      case 'PARTIALLY_APPROVED':
        return 'Partial Review';
      case 'PREPARING':
        return 'Preparing';
      case 'READY':
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'DELIVERY':
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REJECTED':
        return 'Rejected';
      case 'FULL_STOCK':
        return 'Full Stock';
      case 'LOW_STOCK':
        return 'Low Stock';
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      case 'SUBSTITUTED':
        return 'Substituted';
      case 'AWAITING_CUSTOMER_CONFIRMATION':
        return 'Awaiting Confirmation';
      case 'PENDING':
        return 'Pending Review';
      case 'APPROVED':
        return 'Approved';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}
