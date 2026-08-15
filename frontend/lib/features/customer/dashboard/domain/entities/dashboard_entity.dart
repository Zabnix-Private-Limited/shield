import '../../../../../shared/models/appointment.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/models/notification.dart';
import '../../../../../shared/models/wallet.dart';

class DashboardEntity {
  final Customer customer;
  final Membership? membership;
  final MembershipApplicationEntity? membershipApplication;
  final DashboardWalletSummary wallet;
  final DashboardSummary summary;
  final List<Appointment> appointments;
  final List<WalletTransaction> recentActivity;
  final List<Document> documents;
  final List<NotificationModel> notifications;
  final List<DashboardBannerEntity> banners;
  final List<DashboardQuickActionEntity> quickActions;
  final List<DashboardServiceEntity> services;

  const DashboardEntity({
    required this.customer,
    required this.membership,
    required this.membershipApplication,
    required this.wallet,
    required this.summary,
    required this.appointments,
    required this.recentActivity,
    required this.documents,
    required this.notifications,
    required this.banners,
    required this.quickActions,
    required this.services,
  });
}

class DashboardSummary {
  const DashboardSummary({
    required this.upcomingVisitCount,
    required this.documentCount,
    required this.unreadNotificationCount,
  });

  final int upcomingVisitCount;
  final int documentCount;
  final int unreadNotificationCount;
}

class MembershipApplicationEntity {
  const MembershipApplicationEntity({
    required this.id,
    required this.reference,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reason,
  });

  final String id;
  final String reference;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reason;
}

class DashboardBannerEntity {
  const DashboardBannerEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.altText,
    required this.ctaLabel,
    required this.ctaRoute,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String altText;
  final String ctaLabel;
  final String ctaRoute;
}

class DashboardWalletSummary {
  final String walletId;
  final String customerId;
  final double balance;
  final double cashBalance;
  final double pointsBalance;
  final double creditAvailable;
  final String status;

  const DashboardWalletSummary({
    required this.walletId,
    required this.customerId,
    required this.balance,
    required this.cashBalance,
    required this.pointsBalance,
    required this.creditAvailable,
    required this.status,
  });
}

class DashboardQuickActionEntity {
  final String key;
  final String label;
  final String route;

  const DashboardQuickActionEntity({
    required this.key,
    required this.label,
    required this.route,
  });
}

class DashboardServiceEntity {
  final String key;
  final String label;
  final String description;

  const DashboardServiceEntity({
    required this.key,
    required this.label,
    required this.description,
  });
}
