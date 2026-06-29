import '../../../../../shared/models/appointment.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/models/notification.dart';
import '../../../../../shared/models/wallet.dart';

class DashboardEntity {
  final Customer customer;
  final Membership membership;
  final DashboardWalletSummary wallet;
  final List<Appointment> appointments;
  final List<WalletTransaction> recentActivity;
  final List<Document> documents;
  final List<NotificationModel> notifications;
  final List<DashboardQuickActionEntity> quickActions;
  final List<DashboardServiceEntity> services;

  const DashboardEntity({
    required this.customer,
    required this.membership,
    required this.wallet,
    required this.appointments,
    required this.recentActivity,
    required this.documents,
    required this.notifications,
    required this.quickActions,
    required this.services,
  });
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
