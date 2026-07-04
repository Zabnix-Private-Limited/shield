class AdminCustomerSummary {
  const AdminCustomerSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.branch,
    required this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String branch;
  final String status;

  AdminCustomerSummary copyWith({
    String? id,
    String? name,
    String? phone,
    String? branch,
    String? status,
  }) {
    return AdminCustomerSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      branch: branch ?? this.branch,
      status: status ?? this.status,
    );
  }
}
