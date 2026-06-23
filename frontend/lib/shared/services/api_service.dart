import 'package:dio/dio.dart';
import '../../../shared/models/shield_role.dart';
import '../../features/role_demo/presentation/demo_role_data.dart';
import '../models/appointment.dart';
import '../models/document.dart';
import '../models/notification.dart';
import '../models/customer.dart';
import '../models/wallet.dart';
import '../models/membership.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<DemoSectionData> getRoleSectionData(
    SHIELDRole role,
    String section,
  ) async {
    try {
      final response = await _dio.get(
        '/dashboard/role/${role.routeKey}/$section',
        options: Options(
          headers: {
            'x-role': role.routeKey,
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        return DemoSectionData.fromJson(response.data['data']);
      }
      throw Exception('Failed to load dashboard metrics');
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Appointment>> getAppointments(SHIELDRole role) async {
    try {
      final response = await _dio.get(
        '/appointments',
        options: Options(
          headers: {
            'x-role': role.routeKey,
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => _parseAppointment(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Document>> getDocuments(SHIELDRole role) async {
    try {
      final response = await _dio.get(
        '/documents',
        options: Options(
          headers: {
            'x-role': role.routeKey,
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => _parseDocument(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<NotificationModel>> getNotifications(SHIELDRole role) async {
    try {
      final response = await _dio.get(
        '/notifications',
        options: Options(
          headers: {
            'x-role': role.routeKey,
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => _parseNotification(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Appointment _parseAppointment(Map<String, dynamic> json) {
    AppointmentType type = AppointmentType.clinic;
    final typeStr = (json['appointmentType'] ?? '').toString().toLowerCase();
    if (typeStr.contains('dental')) {
      type = AppointmentType.dental;
    } else if (typeStr.contains('home')) {
      type = AppointmentType.homeVisit;
    }

    AppointmentStatus status = AppointmentStatus.scheduled;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (statusStr.contains('completed')) {
      status = AppointmentStatus.completed;
    } else if (statusStr.contains('cancel')) {
      status = AppointmentStatus.cancelled;
    }

    return Appointment(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      customerId: json['customerId']?.toString() ?? '',
      providerId: json['providerId']?.toString(),
      type: type,
      appointmentDate: DateTime.tryParse(json['appointmentDate'] ?? '') ?? DateTime.now(),
      status: status,
      doctorName: json['remarks'] ?? 'Care Provider',
      department: json['provider'] != null ? json['provider']['providerName'] : 'Clinic Service',
      notes: json['remarks'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Document _parseDocument(Map<String, dynamic> json) {
    DocumentType type = DocumentType.prescription;
    final typeStr = (json['documentType'] ?? '').toString().toLowerCase();
    if (typeStr.contains('report')) {
      type = DocumentType.labReport;
    } else if (typeStr.contains('invoice') || typeStr.contains('bill')) {
      type = DocumentType.invoice;
    } else if (typeStr.contains('dental')) {
      type = DocumentType.dentalRecord;
    }

    DocumentStatus status = DocumentStatus.processing;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (statusStr.contains('approve')) {
      status = DocumentStatus.approved;
    } else if (statusStr.contains('valid')) {
      status = DocumentStatus.validated;
    } else if (statusStr.contains('class')) {
      status = DocumentStatus.classified;
    }

    return Document(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      customerId: json['customerId']?.toString() ?? '',
      fileName: json['fileName'] ?? 'Document.pdf',
      storagePath: json['storagePath'] ?? '',
      fileSize: int.tryParse(json['fileSize']?.toString() ?? ''),
      status: status,
      type: type,
      uploadedAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static NotificationModel _parseNotification(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      customerId: json['customerId']?.toString() ?? '',
      title: json['title'] ?? 'Alert',
      body: json['message'] ?? '',
      type: NotificationType.wallet, // default
      isRead: (json['status'] ?? '').toString().toUpperCase() == 'READ',
      createdAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
    );
  }

  static Future<Customer> getCustomerProfile(String customerId) async {
    try {
      final response = await _dio.get(
        '/customers/$customerId',
        options: Options(
          headers: {
            'x-role': 'customer',
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        return _parseCustomer(response.data['data']);
      }
      throw Exception('Failed to load customer profile');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getWalletProfile(String customerId) async {
    try {
      final response = await _dio.get(
        '/wallets/$customerId',
        options: Options(
          headers: {
            'x-role': 'customer',
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception('Failed to load wallet profile');
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<WalletTransaction>> getWalletTransactions(String walletId) async {
    try {
      final response = await _dio.get(
        '/wallets/$walletId/transactions',
        options: Options(
          headers: {
            'x-role': 'customer',
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => _parseTransaction(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Customer _parseCustomer(Map<String, dynamic> json) {
    return Customer(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      customerCode: json['customerCode'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dob: DateTime.tryParse(json['dob'] ?? ''),
      gender: json['gender'],
      mobile: json['mobile'] ?? '',
      email: json['email'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      district: json['district'],
      state: json['state'],
      pincode: json['pincode'],
      status: json['status'] ?? 'PENDING',
      createdBy: json['createdBy']?.toString(),
      approvedBy: json['approvedBy']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static WalletTransaction _parseTransaction(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      walletId: json['walletId']?.toString() ?? '',
      transactionType: json['transactionType'] ?? 'CREDIT',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      referenceType: json['referenceType'],
      referenceId: json['referenceId']?.toString(),
      remarks: json['remarks'],
      createdBy: json['createdBy']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static Future<Membership> getCustomerMembership(String customerId) async {
    try {
      final response = await _dio.get(
        '/customers/$customerId',
        options: Options(
          headers: {
            'x-role': 'customer',
          },
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final membershipData = data['membership'];
        if (membershipData == null) {
          throw Exception('No membership found for customer');
        }

        final walletData = data['wallet'];
        double earned = 0.0;
        double redeemed = 0.0;

        if (walletData != null) {
          final walletId = walletData['id'].toString();
          final transactions = await getWalletTransactions(walletId);
          for (var tx in transactions) {
            if (tx.transactionType.toUpperCase() == 'CREDIT') {
              earned += tx.amount;
            } else if (tx.transactionType.toUpperCase() == 'DEBIT') {
              redeemed += tx.amount;
            }
          }
        }

        final typeCode = membershipData['membershipType'] != null
            ? membershipData['membershipType']['code'].toString().toUpperCase()
            : '';
        final tier = typeCode == 'FOUNDING'
            ? MembershipTier.foundingMember
            : MembershipTier.standardMember;

        return Membership(
          id: membershipData['id'].toString(),
          uuid: membershipData['uuid'] ?? '',
          customerId: customerId,
          tier: tier,
          customerCode: membershipData['membershipNumber'] ?? '',
          startDate: DateTime.tryParse(membershipData['activationDate'] ?? '') ?? DateTime.now(),
          endDate: DateTime.tryParse(membershipData['expiryDate'] ?? '') ?? DateTime.now(),
          isActive: (membershipData['status'] ?? '').toString().toUpperCase() == 'ACTIVE',
          totalEarnedCredits: earned,
          totalRedeemedCredits: redeemed,
          createdAt: DateTime.tryParse(membershipData['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(membershipData['updatedAt'] ?? '') ?? DateTime.now(),
        );
      }
      throw Exception('Failed to load customer profile for membership');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(String mobile, String role) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'mobile': mobile,
          'role': role,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data?['message'] ?? 'Failed to login');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to login');
      }
      rethrow;
    }
  }
}

