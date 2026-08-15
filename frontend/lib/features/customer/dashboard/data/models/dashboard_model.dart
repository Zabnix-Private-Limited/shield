import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../../../shared/models/appointment.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/models/notification.dart';
import '../../../../../shared/models/wallet.dart';
import '../../domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity with EquatableMixin {
  const DashboardModel({
    required super.customer,
    required super.membership,
    required super.membershipApplication,
    required super.wallet,
    required super.summary,
    required super.appointments,
    required super.recentActivity,
    required super.documents,
    required super.notifications,
    required super.banners,
    required super.quickActions,
    required super.services,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final customer = Customer.fromJson(
      Map<String, dynamic>.from(json['customer'] as Map? ?? const {}),
    );
    final membershipPayload = json['membership'] is Map
        ? Map<String, dynamic>.from(json['membership'] as Map)
        : null;
    final transactions = (json['recentActivity'] as List? ?? const [])
        .map(
          (item) => WalletTransaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final membership = membershipPayload == null
        ? null
        : Membership.fromApi(
            customer: customer,
            customerPayload: {
              'membership': membershipPayload,
              'shieldCard': json['shieldCard'],
            },
            transactions: transactions,
          );
    final applicationPayload = json['membershipApplication'] is Map
        ? Map<String, dynamic>.from(json['membershipApplication'] as Map)
        : null;
    final walletPayload = Map<String, dynamic>.from(
      json['wallet'] as Map? ?? const {},
    );
    final summaryPayload = Map<String, dynamic>.from(
      json['summary'] as Map? ?? const {},
    );

    return DashboardModel(
      customer: customer,
      membership: membership,
      membershipApplication: applicationPayload == null
          ? null
          : MembershipApplicationEntity(
              id: (applicationPayload['id'] ?? '').toString(),
              reference: (applicationPayload['reference'] ?? '').toString(),
              status: (applicationPayload['status'] ?? 'PENDING').toString(),
              submittedAt:
                  DateTime.tryParse(
                    (applicationPayload['submittedAt'] ?? '').toString(),
                  ) ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              reviewedAt: DateTime.tryParse(
                (applicationPayload['reviewedAt'] ?? '').toString(),
              ),
              reason: applicationPayload['reason']?.toString(),
            ),
      wallet: DashboardWalletSummary(
        walletId: (walletPayload['walletId'] ?? '').toString(),
        customerId: (walletPayload['customerId'] ?? customer.id).toString(),
        balance: _asDouble(walletPayload['balance']),
        cashBalance: _asDouble(walletPayload['cashBalance']),
        pointsBalance: _asDouble(walletPayload['pointsBalance']),
        creditAvailable: _asDouble(walletPayload['creditAvailable']),
        status: (walletPayload['status'] ?? 'ACTIVE').toString(),
      ),
      summary: DashboardSummary(
        upcomingVisitCount: _asInt(
          summaryPayload['upcomingVisitCount'],
          fallback: (json['appointments'] as List? ?? const []).length,
        ),
        documentCount: _asInt(
          summaryPayload['documentCount'],
          fallback: (json['documents'] as List? ?? const []).length,
        ),
        unreadNotificationCount: _asInt(
          summaryPayload['unreadNotificationCount'],
          fallback: (json['notifications'] as List? ?? const [])
              .where((item) => item is Map && item['status'] != 'READ')
              .length,
        ),
      ),
      appointments: (json['appointments'] as List? ?? const [])
          .map(
            (item) =>
                Appointment.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      recentActivity: transactions,
      documents: (json['documents'] as List? ?? const [])
          .map(
            (item) => Document.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      notifications: (json['notifications'] as List? ?? const [])
          .map(
            (item) => NotificationModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      banners: (json['banners'] as List? ?? const [])
          .map(
            (item) => DashboardBannerEntity(
              id: (item as Map)['id'].toString(),
              title: item['title'].toString(),
              subtitle: item['subtitle'].toString(),
              imageUrl: item['imageUrl'].toString(),
              altText: item['altText'].toString(),
              ctaLabel: item['ctaLabel'].toString(),
              ctaRoute: item['ctaRoute'].toString(),
            ),
          )
          .toList(),
      quickActions: (json['quickActions'] as List? ?? const [])
          .map(
            (item) => DashboardQuickActionEntity(
              key: (item as Map)['key'].toString(),
              label: item['label'].toString(),
              route: item['route'].toString(),
            ),
          )
          .toList(),
      services: (json['services'] as List? ?? const [])
          .map(
            (item) => DashboardServiceEntity(
              key: (item as Map)['key'].toString(),
              label: item['label'].toString(),
              description: item['description'].toString(),
            ),
          )
          .toList(),
    );
  }

  factory DashboardModel.fromCache(String source) {
    return DashboardModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  Map<String, dynamic> toJson() {
    final cachedMembership = membership;
    final cachedApplication = membershipApplication;
    return {
      'customer': {
        'id': customer.id,
        'uuid': customer.uuid,
        'customer_code': customer.customerCode,
        'aadhaar_number': customer.aadhaarNumber,
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'dob': customer.dob?.toIso8601String(),
        'gender': customer.gender,
        'mobile': customer.mobile,
        'email': customer.email,
        'address_line1': customer.addressLine1,
        'address_line2': customer.addressLine2,
        'city': customer.city,
        'district': customer.district,
        'state': customer.state,
        'pincode': customer.pincode,
        'status': customer.status,
        'created_by': customer.createdBy,
        'approved_by': customer.approvedBy,
        'created_at': customer.createdAt.toIso8601String(),
        'updated_at': customer.updatedAt.toIso8601String(),
        'blood_group': customer.bloodGroup,
        'agent_code': customer.agentCode,
      },
      'membership': cachedMembership == null
          ? null
          : {
              'id': cachedMembership.id,
              'uuid': cachedMembership.uuid,
              'membershipNumber': cachedMembership.customerCode,
              'status': cachedMembership.membershipStatus,
              'activationDate': cachedMembership.startDate.toIso8601String(),
              'expiryDate': cachedMembership.endDate.toIso8601String(),
              'createdAt': cachedMembership.createdAt.toIso8601String(),
              'updatedAt': cachedMembership.updatedAt.toIso8601String(),
              'membershipType': {'name': cachedMembership.tierLabel},
            },
      'membershipApplication': cachedApplication == null
          ? null
          : {
              'id': cachedApplication.id,
              'reference': cachedApplication.reference,
              'status': cachedApplication.status,
              'submittedAt': cachedApplication.submittedAt.toIso8601String(),
              'reviewedAt': cachedApplication.reviewedAt?.toIso8601String(),
              'reason': cachedApplication.reason,
            },
      if (cachedMembership != null &&
          (cachedMembership.cardNumber != null ||
              cachedMembership.cardQrPayload != null ||
              cachedMembership.cardStatus != null))
        'shieldCard': {
          'cardNumber': cachedMembership.cardNumber,
          'qrCode': cachedMembership.cardQrPayload,
          'status': cachedMembership.cardStatus,
          'issuedAt': cachedMembership.cardIssuedAt?.toIso8601String(),
        },
      'wallet': {
        'walletId': wallet.walletId,
        'customerId': wallet.customerId,
        'balance': wallet.balance,
        'cashBalance': wallet.cashBalance,
        'pointsBalance': wallet.pointsBalance,
        'creditAvailable': wallet.creditAvailable,
        'status': wallet.status,
      },
      'summary': {
        'upcomingVisitCount': summary.upcomingVisitCount,
        'documentCount': summary.documentCount,
        'unreadNotificationCount': summary.unreadNotificationCount,
      },
      'appointments': appointments
          .map(
            (item) => {
              'id': item.id,
              'uuid': item.uuid,
              'customer_id': item.customerId,
              'provider_id': item.providerId,
              'appointment_type': item.type.name.toUpperCase(),
              'appointment_date': item.appointmentDate.toIso8601String(),
              'status': item.status.name.toUpperCase(),
              'remarks': item.notes,
              'provider': {
                'providerName': item.doctorName,
                'providerType': item.department,
              },
            },
          )
          .toList(),
      'recentActivity': recentActivity
          .map(
            (item) => {
              'id': item.id,
              'uuid': item.uuid,
              'wallet_id': item.walletId,
              'transaction_type': item.transactionType,
              'sub_ledger_type': item.subLedgerType,
              'amount': item.amount,
              'reference_type': item.referenceType,
              'reference_id': item.referenceId,
              'remarks': item.remarks,
              'created_by': item.createdBy,
              'created_at': item.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'documents': documents
          .map(
            (item) => {
              'id': item.id,
              'uuid': item.uuid,
              'customer_id': item.customerId,
              'file_name': item.fileName,
              'storage_path': item.storagePath,
              'file_size': item.fileSize,
              'mime_type': item.mimeType,
              'document_type': item.type?.name.toUpperCase(),
              'status': item.status.name.toUpperCase(),
              'uploaded_by': item.uploadedBy,
              'created_at': item.uploadedAt.toIso8601String(),
              'processed_at': item.processedAt?.toIso8601String(),
            },
          )
          .toList(),
      'notifications': notifications
          .map(
            (item) => {
              'id': item.id,
              'uuid': item.uuid,
              'customer_id': item.customerId,
              'title': item.title,
              'message': item.body,
              'status': item.isRead ? 'READ' : 'UNREAD',
              'sent_at': item.createdAt.toIso8601String(),
              'channel': item.type.name.toUpperCase(),
            },
          )
          .toList(),
      'banners': banners
          .map(
            (item) => {
              'id': item.id,
              'title': item.title,
              'subtitle': item.subtitle,
              'imageUrl': item.imageUrl,
              'altText': item.altText,
              'ctaLabel': item.ctaLabel,
              'ctaRoute': item.ctaRoute,
            },
          )
          .toList(),
      'quickActions': quickActions
          .map(
            (item) => {
              'key': item.key,
              'label': item.label,
              'route': item.route,
            },
          )
          .toList(),
      'services': services
          .map(
            (item) => {
              'key': item.key,
              'label': item.label,
              'description': item.description,
            },
          )
          .toList(),
    };
  }

  String toCache() => jsonEncode(toJson());

  @override
  List<Object?> get props => [
    customer,
    membership,
    membershipApplication?.id,
    membershipApplication?.status,
    wallet.walletId,
    wallet.balance,
    wallet.cashBalance,
    wallet.pointsBalance,
    wallet.creditAvailable,
    wallet.status,
    summary.upcomingVisitCount,
    summary.documentCount,
    summary.unreadNotificationCount,
    appointments,
    recentActivity,
    documents,
    notifications,
    banners,
    quickActions,
    services,
  ];

  static double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _asInt(dynamic value, {required int fallback}) {
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
