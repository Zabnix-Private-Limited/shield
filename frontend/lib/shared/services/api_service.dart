import '../../../shared/models/shield_role.dart';
import '../../features/portal/presentation/portal_role_data.dart';
import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/document.dart';
import '../models/membership.dart';
import '../models/notification.dart';
import '../models/wallet.dart';

class ApiService {
  static const Duration _mockDelay = Duration(milliseconds: 180);

  static Future<PortalSectionData> getRoleSectionData(
    SHIELDRole role,
    String section,
  ) async {
    await Future<void>.delayed(_mockDelay);
    return portalDataForRole(role).sectionFor(section);
  }

  static Future<List<Appointment>> getAppointments(SHIELDRole role) async {
    await Future<void>.delayed(_mockDelay);
    if (role == SHIELDRole.customer) {
      return dummyAppointments
          .where((appointment) => appointment.customerId == '1')
          .toList()
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    }
    return dummyAppointments;
  }

  static Future<List<Document>> getDocuments(SHIELDRole role) async {
    await Future<void>.delayed(_mockDelay);
    if (role == SHIELDRole.customer) {
      return dummyDocuments
          .where((document) => document.customerId == '1')
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    }
    return dummyDocuments;
  }

  static Future<List<NotificationModel>> getNotifications(SHIELDRole role) async {
    await Future<void>.delayed(_mockDelay);
    if (role == SHIELDRole.customer) {
      return dummyNotifications
          .where((notification) => notification.customerId == '1')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return dummyNotifications;
  }

  static Future<Customer> getCustomerProfile(String customerId) async {
    await Future<void>.delayed(_mockDelay);
    return dummyCustomers.firstWhere(
      (customer) => customer.id == customerId,
      orElse: () => dummyCustomers.first,
    );
  }

  static Future<Map<String, dynamic>> getWalletProfile(String customerId) async {
    await Future<void>.delayed(_mockDelay);
    final transactions = dummyTransactions
        .where((transaction) => transaction.walletId == dummyWallet.id)
        .toList();

    double cashBalance = 0;
    double pointsBalance = 0;
    for (final transaction in transactions) {
      final delta = transaction.transactionType == 'CREDIT'
          ? transaction.amount
          : -transaction.amount;
      if (transaction.subLedgerType == 'POINTS') {
        pointsBalance += delta;
      } else {
        cashBalance += delta;
      }
    }

    return {
      'walletId': dummyWallet.id,
      'customerId': customerId,
      'cashBalance': cashBalance,
      'pointsBalance': pointsBalance,
      'balance': cashBalance,
      'status': dummyWallet.status,
    };
  }

  static Future<List<WalletTransaction>> getWalletTransactions(String walletId) async {
    await Future<void>.delayed(_mockDelay);
    return dummyTransactions
        .where((transaction) => transaction.walletId == walletId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<Membership> getCustomerMembership(String customerId) async {
    await Future<void>.delayed(_mockDelay);
    return dummyMembership;
  }
}
