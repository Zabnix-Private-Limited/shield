import 'package:equatable/equatable.dart';

enum NotificationType { wallet, appointment, document, membership, system }

class NotificationModel extends Equatable {
  final String id;
  final String uuid;
  final String customerId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.uuid,
    required this.customerId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? value) {
      switch ((value ?? '').toUpperCase()) {
        case 'WALLET':
          return NotificationType.wallet;
        case 'APPOINTMENT':
          return NotificationType.appointment;
        case 'DOCUMENT':
          return NotificationType.document;
        case 'MEMBERSHIP':
          return NotificationType.membership;
        default:
          return NotificationType.system;
      }
    }

    final title = (json['title'] ?? 'Notification').toString();
    final message = (json['message'] ?? json['body'] ?? '').toString();
    final combined = '$title $message'.toUpperCase();

    return NotificationModel(
      id: json['id'].toString(),
      uuid: (json['uuid'] ?? 'notification-${json['id']}').toString(),
      customerId: (json['customerId'] ?? json['customer_id'] ?? '').toString(),
      type: parseType(
        combined.contains('WALLET')
            ? 'WALLET'
            : combined.contains('APPOINT')
            ? 'APPOINTMENT'
            : combined.contains('REPORT') ||
                  combined.contains('DOCUMENT') ||
                  combined.contains('PRESCRIPTION')
            ? 'DOCUMENT'
            : combined.contains('MEMBER')
            ? 'MEMBERSHIP'
            : (json['channel'] ?? 'SYSTEM').toString(),
      ),
      title: title,
      body: message,
      isRead: (json['status'] ?? '').toString().toUpperCase() == 'READ',
      createdAt:
          DateTime.tryParse((json['sentAt'] ?? json['sent_at']).toString()) ??
          DateTime.now(),
    );
  }

  String get typeLabel => switch (type) {
    NotificationType.wallet => 'Wallet',
    NotificationType.appointment => 'Appointment',
    NotificationType.document => 'Document',
    NotificationType.membership => 'Membership',
    NotificationType.system => 'System',
  };

  @override
  List<Object?> get props => [
    id,
    uuid,
    customerId,
    type,
    title,
    body,
    isRead,
    createdAt,
  ];
}

final List<NotificationModel> dummyNotifications = [
  NotificationModel(
    id: '1',
    uuid: 'notif-001',
    customerId: '1',
    type: NotificationType.wallet,
    title: 'Wallet Credited on June 20',
    body:
        '₹500 credited to your wallet from SHIELD Hyper Pharmacy, Perinthalmanna on June 20, 2026',
    isRead: false,
    createdAt: DateTime(2026, 6, 20, 21, 20),
  ),
  NotificationModel(
    id: '2',
    uuid: 'notif-002',
    customerId: '1',
    type: NotificationType.appointment,
    title: 'Appointment on June 21',
    body:
        'Your appointment with Dr. Haneefa P at Manjeri is on June 21, 2026 at 10:00 AM',
    isRead: false,
    createdAt: DateTime(2026, 6, 20, 19, 30),
  ),
  NotificationModel(
    id: '3',
    uuid: 'notif-003',
    customerId: '1',
    type: NotificationType.document,
    title: 'Document Approved',
    body: 'Your June 18 prescription upload has been approved',
    isRead: true,
    createdAt: DateTime(2026, 6, 19, 11, 0),
  ),
  NotificationModel(
    id: '4',
    uuid: 'notif-004',
    customerId: '1',
    type: NotificationType.membership,
    title: 'Membership Renewed for June 2026',
    body:
        'Your SHIELD membership for the Perinthalmanna cluster was renewed on June 15, 2026',
    isRead: true,
    createdAt: DateTime(2026, 6, 15, 9, 30),
  ),
];
