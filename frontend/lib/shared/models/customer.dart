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
  });

  String get fullName => '$firstName $lastName';

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
    email: 'nihal.rahman@example.com',
    addressLine1: 'Kizhakkethil House',
    addressLine2: 'Near Hyper Pharmacy',
    city: 'Perinthalmanna',
    district: 'Malappuram',
    state: 'Kerala',
    pincode: '679322',
    status: 'ACTIVE',
    createdAt: DateTime(2024, 1, 10),
    updatedAt: DateTime(2024, 1, 10),
  ),
  Customer(
    id: '2',
    uuid: '550e8400-e29b-41d4-a716-446655440001',
    customerCode: 'SHLD-002',
    aadhaarNumber: '987654321098',
    firstName: 'Fathima',
    lastName: 'Sherin',
    dob: DateTime(1992, 3, 22),
    gender: 'Female',
    mobile: '9123456780',
    email: 'fathima.sherin@example.com',
    addressLine1: 'Kallingal House',
    addressLine2: 'Melattur Road',
    city: 'Melattur',
    district: 'Malappuram',
    state: 'Kerala',
    pincode: '679326',
    status: 'ACTIVE',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
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
    email: 'shanib.k@example.com',
    addressLine1: 'Pallikkal House',
    city: 'Manjeri',
    district: 'Malappuram',
    state: 'Kerala',
    pincode: '676121',
    status: 'PENDING',
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 2, 1),
  ),
];
