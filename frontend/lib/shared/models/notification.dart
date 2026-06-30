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
