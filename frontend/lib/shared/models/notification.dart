import 'package:equatable/equatable.dart';

enum NotificationType {
  wallet,
  appointment,
  document,
  membership,
  system,
}

class Notification extends Equatable {
  final String id;
  final String uuid;
  final String customerId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.uuid,
    required this.customerId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

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

final List<Notification> dummyNotifications = [
  Notification(
    id: '1',
    uuid: 'notif-001',
    customerId: '1',
    type: NotificationType.wallet,
    title: 'Wallet Credited!',
    body: '₹500 credited to your wallet from SHIELD Hyper Pharmacy, Perinthalmanna',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  Notification(
    id: '2',
    uuid: 'notif-002',
    customerId: '1',
    type: NotificationType.appointment,
    title: 'Appointment Tomorrow!',
    body: 'Your appointment with Dr. Haneefa P at Manjeri is tomorrow at 10:00 AM',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Notification(
    id: '3',
    uuid: 'notif-003',
    customerId: '1',
    type: NotificationType.document,
    title: 'Document Approved',
    body: 'Your recent prescription upload has been approved',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Notification(
    id: '4',
    uuid: 'notif-004',
    customerId: '1',
    type: NotificationType.membership,
    title: 'Membership Renewed!',
    body: 'Your SHIELD membership for the Perinthalmanna cluster has been renewed',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];
