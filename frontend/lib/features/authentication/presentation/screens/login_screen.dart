import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

enum SHIELDRole {
  customer('Customer'),
  pharmacy('Pharmacy'),
  clinic('Clinic'),
  dental('Dental Clinic'),
  lab('Diagnostic Lab'),
  crm('CRM'),
  admin('Admin'),
  superAdmin('Super Admin');

  final String label;
  const SHIELDRole(this.label);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  SHIELDRole _selectedRole = SHIELDRole.customer;

  // Track what's built
  final Map<SHIELDRole, List<String>> _builtFeatures = {
    SHIELDRole.customer: [
      'Login',
      'Dashboard',
      'Wallet',
      'Transactions',
      'Profile',
      'Documents',
      'Prescriptions',
      'Appointments',
      'Notifications',
      'Membership',
      'Settings',
    ],
    SHIELDRole.pharmacy: [],
    SHIELDRole.clinic: [],
    SHIELDRole.dental: [],
    SHIELDRole.lab: [],
    SHIELDRole.crm: [],
    SHIELDRole.admin: [],
    SHIELDRole.superAdmin: [],
  };

  final Map<SHIELDRole, List<String>> _pendingFeatures = {
    SHIELDRole.customer: [
      'Reports',
      'QR Scan Integration',
      'Payment Integration',
      'Document Upload',
      'Appointment Booking',
    ],
    SHIELDRole.pharmacy: [
      'Dashboard',
      'Customer Search',
      'Customer Verification',
      'Bill Upload',
      'Prescription Upload',
      'Transaction Entry',
      'History',
    ],
    SHIELDRole.clinic: [
      'Dashboard',
      'Patient Management',
      'Appointment Management',
      'Prescription Creation',
      'Document Management',
    ],
    SHIELDRole.dental: [
      'Dashboard',
      'Patient Management',
      'Appointment Management',
      'Treatment Records',
    ],
    SHIELDRole.lab: [
      'Dashboard',
      'Test Management',
      'Report Upload',
    ],
    SHIELDRole.crm: [
      'Dashboard',
      'Customer Management',
      'Lead Management',
      'Follow-ups',
    ],
    SHIELDRole.admin: [
      'Dashboard',
      'User Management',
      'Role Management',
      'Reporting',
      'Settings',
    ],
    SHIELDRole.superAdmin: [
      'Everything in Admin',
      'Multi-tenant Management',
      'Audit Logs',
    ],
  };

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showDiagnostics() {
    showDialog(
      context: context,
      builder: _buildDiagnosticsDialog,
    );
  }

  Widget _buildDiagnosticsDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('SHIELD - Build Status & Diagnostics'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: SHIELDRole.values.map((role) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            role.label,
                            style: AppTypography.h5,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _builtFeatures[role]!.isEmpty
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : _pendingFeatures[role]!.isEmpty
                                      ? AppColors.shieldGreen.withValues(alpha: 0.1)
                                      : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _builtFeatures[role]!.isEmpty
                                  ? 'Not Started'
                                  : _pendingFeatures[role]!.isEmpty
                                      ? 'Complete'
                                      : 'In Progress',
                              style: AppTypography.tiny.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _builtFeatures[role]!.isEmpty
                                    ? AppColors.error
                                    : _pendingFeatures[role]!.isEmpty
                                        ? AppColors.shieldGreen
                                        : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_builtFeatures[role]!.isNotEmpty) ...[
                        Text(
                          'Built (${_builtFeatures[role]!.length}):',
                          style: AppTypography.small.copyWith(
                            color: AppColors.shieldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _builtFeatures[role]!
                              .map(
                                (feature) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.shieldGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    feature,
                                    style: AppTypography.tiny.copyWith(color: AppColors.shieldGreen),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_pendingFeatures[role]!.isNotEmpty) ...[
                        Text(
                          'Pending (${_pendingFeatures[role]!.length}):',
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _pendingFeatures[role]!
                              .map(
                                (feature) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    feature,
                                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to',
                        style: AppTypography.h3,
                      ),
                      Text(
                        'SHIELD',
                        style: AppTypography.h1.copyWith(color: AppColors.shieldBlue),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.shieldBlue),
                    onPressed: _showDiagnostics,
                    tooltip: 'View Build Status & Diagnostics',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sahakar Healthcare Initiative to Exempt Lifestyle Disease',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 32),
              // Role Selector
              Text(
                'Select Role',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SHIELDRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: SHIELDRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          '${role.label} ${_builtFeatures[role]!.isEmpty ? '(Not Started)' : _pendingFeatures[role]!.isEmpty ? '(Complete)' : '(In Progress)'}',
                          style: AppTypography.body,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!_otpSent) ...[
                Text(
                  'Enter Mobile Number',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '9876543210',
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '+91',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Send OTP',
                  onPressed: () {
                    setState(() {
                      _otpSent = true;
                    });
                  },
                ),
              ] else ...[
                Text(
                  'Enter OTP',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '123456',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _otpSent = false;
                        _otpController.clear();
                      });
                    },
                    child: Text('Change number', style: AppTypography.small.copyWith(color: AppColors.shieldBlue)),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Verify & Login',
                  onPressed: () {
                    if (_selectedRole == SHIELDRole.customer) {
                      context.go('/');
                    } else {
                      // Show placeholder for other roles
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${_selectedRole.label} view not built yet!')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
