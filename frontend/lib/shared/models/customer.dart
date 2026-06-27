import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String uuid;
  final String customerCode;
  final String aadhaarNumber;
  final String firstName;
  final String lastName;
  final DateTime? dob;
  final String? gender;
  final String mobile;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final String status;
  final String? createdBy;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bloodGroup;
  final String? agentCode;

  const Customer({
    required this.id,
    required this.uuid,
    required this.customerCode,
    required this.aadhaarNumber,
    required this.firstName,
    required this.lastName,
    this.dob,
    this.gender,
    required this.mobile,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.district,
    this.state,
    this.pincode,
    required this.status,
    this.createdBy,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.bloodGroup,
    this.agentCode,
  });

  String get fullName => '$firstName $lastName';

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String readString(dynamic value, {String fallback = ''}) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) {
        return fallback;
      }
      return text;
    }

    return Customer(
      id: readString(json['id']),
      uuid: readString(json['uuid']),
      customerCode: readString(
        json['customerCode'] ?? json['customer_code'],
        fallback: 'SHIELD-CUSTOMER',
      ),
      aadhaarNumber: readString(
        json['aadhaarNumber'] ?? json['aadhaar_number'],
      ),
      firstName: readString(json['firstName'] ?? json['first_name']),
      lastName: readString(json['lastName'] ?? json['last_name']),
      dob: parseDate(json['dob']),
      gender: readString(json['gender']).isEmpty
          ? null
          : readString(json['gender']),
      mobile: readString(json['mobile']),
      email: readString(json['email']).isEmpty
          ? null
          : readString(json['email']),
      addressLine1:
          readString(json['addressLine1'] ?? json['address_line1']).isEmpty
          ? null
          : readString(json['addressLine1'] ?? json['address_line1']),
      addressLine2:
          readString(json['addressLine2'] ?? json['address_line2']).isEmpty
          ? null
          : readString(json['addressLine2'] ?? json['address_line2']),
      city: readString(json['city']).isEmpty ? null : readString(json['city']),
      district: readString(json['district']).isEmpty
          ? null
          : readString(json['district']),
      state: readString(json['state']).isEmpty
          ? null
          : readString(json['state']),
      pincode: readString(json['pincode']).isEmpty
          ? null
          : readString(json['pincode']),
      status: readString(json['status'], fallback: 'ACTIVE'),
      createdBy: readString(json['createdBy'] ?? json['created_by']).isEmpty
          ? null
          : readString(json['createdBy'] ?? json['created_by']),
      approvedBy: readString(json['approvedBy'] ?? json['approved_by']).isEmpty
          ? null
          : readString(json['approvedBy'] ?? json['approved_by']),
      createdAt:
          parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt:
          parseDate(json['updatedAt'] ?? json['updated_at']) ?? DateTime.now(),
      bloodGroup: readString(json['bloodGroup'] ?? json['blood_group']).isEmpty
          ? null
          : readString(json['bloodGroup'] ?? json['blood_group']),
      agentCode: readString(json['agentCode'] ?? json['agent_code']).isEmpty
          ? null
          : readString(json['agentCode'] ?? json['agent_code']),
    );
  }

  Customer copyWith({
    String? id,
    String? uuid,
    String? customerCode,
    String? aadhaarNumber,
    String? firstName,
    String? lastName,
    DateTime? dob,
    String? gender,
    String? mobile,
    String? email,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? district,
    String? state,
    String? pincode,
    String? status,
    String? createdBy,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bloodGroup,
    String? agentCode,
  }) {
    return Customer(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      customerCode: customerCode ?? this.customerCode,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      agentCode: agentCode ?? this.agentCode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    customerCode,
    aadhaarNumber,
    firstName,
    lastName,
    dob,
    gender,
    mobile,
    email,
    addressLine1,
    addressLine2,
    city,
    district,
    state,
    pincode,
    status,
    createdBy,
    approvedBy,
    createdAt,
    updatedAt,
    bloodGroup,
    agentCode,
  ];
}

final List<Customer> dummyCustomers = [
  Customer(
    id: '1',
    uuid: '550e8400-e29b-41d4-a716-446655440000',
    customerCode: 'SHLD-001',
    aadhaarNumber: '123456789012',
    firstName: 'Nihal',
    lastName: 'Rahman',
    dob: DateTime(1988, 6, 15),
    gender: 'Male',
    mobile: '9876543210',
    email: 'Zabnixprivatelimited@gmail.com',
    addressLine1: 'Kizhakkethil House',
    addressLine2: 'Near Hyper Pharmacy',
    city: 'Perinthalmanna',
    district: 'Malappuram',
    state: 'Kerala',
    pincode: '679322',
    status: 'ACTIVE',
    createdAt: DateTime(2026, 1, 10),
    updatedAt: DateTime(2026, 6, 20),
  ),
  Customer(
    id: '2',
    uuid: '550e8400-e29b-41d4-a716-446655440000', // unified mock
    customerCode: 'SHLD-002',
    aadhaarNumber: '987654321098',
    firstName: 'Fathima',
    lastName: 'Sherin',
    dob: DateTime(1992, 3, 22),
    gender: 'Female',
    mobile: '9123456780',
    email: 'Zabnixprivatelimited@gmail.com',
    addressLine1: 'Kallingal House',
    addressLine2: 'Melattur Road',
    city: 'Melattur',
    district: 'Malappuram',
    state: 'Kerala',
    pincode: '679326',
    status: 'ACTIVE',
    createdAt: DateTime(2026, 1, 15),
    updatedAt: DateTime(2026, 6, 18),
  ),
  Customer(
    id: '3',
    uuid: '550e8400-e29b-41d4-a716-446655440002',
    customerCode: 'SHLD-003',
    aadhaarNumber: '112233445566',
    firstName: 'Shanib',
    lastName: 'K',
    dob: DateTime(1984, 11, 5),
    gender: 'Male',
    mobile: '8901234567',
    email: 'Zabnixprivatelimited@gmail.com',
    addressLine1: 'Pallikkal House',
    addressLine2: null,
    city: 'Manjeri',
    district: 'Malappuram',
    state: 'Kerala',
    pincode: '676121',
    status: 'PENDING',
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 6, 19),
  ),
];
