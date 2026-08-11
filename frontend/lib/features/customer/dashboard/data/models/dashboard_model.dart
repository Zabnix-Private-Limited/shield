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
    required super.wallet,
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
    final membershipPayload = Map<String, dynamic>.from(
      json['membership'] as Map? ?? const {},
    );
    final transactions = (json['recentActivity'] as List? ?? const [])
        .map(
          (item) => WalletTransaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final membership = Membership.fromApi(
      customer: customer,
      customerPayload: {
        'membership': membershipPayload,
        'shieldCard': json['shieldCard'],
      },
      transactions: transactions,
    );
    final walletPayload = Map<String, dynamic>.from(
      json['wallet'] as Map? ?? const {},
    );

    return DashboardModel(
      customer: customer,
      membership: membership,
      wallet: DashboardWalletSummary(
        walletId: (walletPayload['walletId'] ?? '').toString(),
        customerId: (walletPayload['customerId'] ?? customer.id).toString(),
        balance: _asDouble(walletPayload['balance']),
        cashBalance: _asDouble(walletPayload['cashBalance']),
        pointsBalance: _asDouble(walletPayload['pointsBalance']),
        creditAvailable: _asDouble(walletPayload['creditAvailable']),
        status: (walletPayload['status'] ?? 'ACTIVE').toString(),
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
      'membership': {
        'id': membership.id,
        'uuid': membership.uuid,
        'membershipNumber': membership.customerCode,
        'status': membership.isActive ? 'ACTIVE' : 'INACTIVE',
        'activationDate': membership.startDate.toIso8601String(),
        'expiryDate': membership.endDate.toIso8601String(),
        'createdAt': membership.createdAt.toIso8601String(),
        'updatedAt': membership.updatedAt.toIso8601String(),
        'membershipType': {'name': membership.tierLabel},
      },
      if (membership.cardNumber != null ||
          membership.cardQrPayload != null ||
          membership.cardStatus != null)
        'shieldCard': {
          'cardNumber': membership.cardNumber,
          'qrCode': membership.cardQrPayload,
          'status': membership.cardStatus,
          'issuedAt': membership.cardIssuedAt?.toIso8601String(),
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
    wallet.walletId,
    wallet.balance,
    wallet.cashBalance,
    wallet.pointsBalance,
    wallet.creditAvailable,
    wallet.status,
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
}
