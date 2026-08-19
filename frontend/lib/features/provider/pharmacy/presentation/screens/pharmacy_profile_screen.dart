import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_orders_repository.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';
import 'package:shield/shared/services/internal_auth_session.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profileData;
  final PharmacyOrdersRepository _repository = PharmacyOrdersRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchPharmacyProfile();
      if (!mounted) return;
      setState(() {
        _profileData = data;
        _isLoading = false;
        _nameController.text = data['displayName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleSave() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = {
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      final updated = await _repository.updatePharmacyProfile(payload);
      if (!mounted) return;
      setState(() {
        _profileData = updated;
        _isSaving = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Pharmacy Profile updated and persisted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: PharmacyProfileSkeleton(),
      );
    }

    final session = InternalAuthSession.instance;
    final userName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (session.displayName ?? 'Pharmacy Staff');
    final userEmail = _emailController.text.isNotEmpty
        ? _emailController.text
        : (session.email ?? '');
    final userRole = _profileData?['roleCode'] ?? session.roleCode ?? 'PHARMACY_PROVIDER';
    final businessName = _profileData?['pharmacyName'] ?? 'Sahakar Pharmacy Outlet';
    final businessCode = _profileData?['businessCode'] ?? 'PHARM-SHIELD-001';
    final drugLicence = _profileData?['drugLicenceNo'] ?? 'DL-PHARM-2026-8841';
    final gstin = _profileData?['gstin'] ?? '29ABCDE1234F1Z5';
    final address = _profileData?['address'] ?? 'Building 14, Health Park Road, Sector 4';
    final cityStatePin = '${_profileData?['city'] ?? 'Bangalore'}, ${_profileData?['state'] ?? 'Karnataka'} — ${_profileData?['pin'] ?? '560001'}';
    final operatingHours = _profileData?['operatingHours'] ?? '08:00 AM - 10:00 PM (Mon-Sat)';
    final accountCreated = _profileData?['accountCreatedAt']?.toString().split('T').first ?? '2026-01-15';
    final accountStatus = _profileData?['accountStatus'] ?? 'ACTIVE';

    final isWideDesktop = MediaQuery.of(context).size.width >= 1200;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          PharmacyCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PharmacyColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(PharmacyRadius.card),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: PharmacyColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacy Profile',
                          style: PharmacyTypography.h2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account identity, business details, and operating preferences.',
                          style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                PharmacyPrimaryButton(
                  label: 'Save Profile',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Layout Grid
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: User & Service Area
                SizedBox(
                  width: isWideDesktop ? 340 : 300,
                  child: Column(
                    children: [
                      _buildUserProfileCard(userName, userEmail, userRole, businessName),
                      const SizedBox(height: 16),
                      _buildDeliveryServiceCard(),
                      const SizedBox(height: 16),
                      _buildEmergencySupportCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Center Column: Business Details & Outlets
                Expanded(
                  child: Column(
                    children: [
                      _buildBusinessDetailsCard(businessName, businessCode, drugLicence, gstin, address, cityStatePin, operatingHours),
                      const SizedBox(height: 16),
                      _buildOutletsCard(businessName),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Security, Quick Actions & Info
                SizedBox(
                  width: isWideDesktop ? 320 : 280,
                  child: Column(
                    children: [
                      _buildSecurityCard(),
                      const SizedBox(height: 16),
                      _buildQuickActionsCard(),
                      const SizedBox(height: 16),
                      _buildAccountInfoCard(accountCreated, accountStatus),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            // Stacked Mobile / Tablet Layout
            _buildUserProfileCard(userName, userEmail, userRole, businessName),
            const SizedBox(height: 16),
            _buildBusinessDetailsCard(businessName, businessCode, drugLicence, gstin, address, cityStatePin, operatingHours),
            const SizedBox(height: 16),
            _buildOutletsCard(businessName),
            const SizedBox(height: 16),
            _buildDeliveryServiceCard(),
            const SizedBox(height: 16),
            _buildSecurityCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildAccountInfoCard(accountCreated, accountStatus),
          ],

          const SizedBox(height: 24),
          // Bottom Actions Row
          PharmacyCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PharmacySecondaryButton(
                  label: 'Discard Changes',
                  onPressed: _loadProfile,
                ),
                const SizedBox(width: 12),
                PharmacyPrimaryButton(
                  label: 'Save Profile Changes',
                  icon: Icons.check_circle_outline,
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(String name, String email, String role, String business) {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: PharmacyColors.primary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: PharmacyTypography.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: PharmacyColors.primarySoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role.replaceAll('_', ' '),
                        style: PharmacyTypography.caption.copyWith(color: PharmacyColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone_outlined, 'Mobile Contact', _phoneController.text.isNotEmpty ? _phoneController.text : '+91 98765 43210'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email_outlined, 'Email Address', email.isNotEmpty ? email : 'pharmacist@shieldhealth.org'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.business_rounded, 'Assigned Outlet', business),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PharmacySecondaryButton(
              label: 'Edit User Profile',
              icon: Icons.edit_outlined,
              compact: true,
              onPressed: () => _showEditUserDialog(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Mobile Contact'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSave();
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsCard(String business, String code, String licence, String gstin, String address, String cityStatePin, String hours) {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pharmacy & Business Details', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PharmacyColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('VERIFIED PHARMACY', style: PharmacyTypography.caption.copyWith(color: PharmacyColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Business Name', business),
                    const SizedBox(height: 12),
                    _buildDetailItem('Business Code', code),
                    const SizedBox(height: 12),
                    _buildDetailItem('Drug Licence No.', licence),
                    const SizedBox(height: 12),
                    _buildDetailItem('Operating Hours', hours),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Registered Address', address),
                    const SizedBox(height: 12),
                    _buildDetailItem('City / State / PIN', cityStatePin),
                    const SizedBox(height: 12),
                    _buildDetailItem('GSTIN / Tax ID', gstin),
                    const SizedBox(height: 12),
                    _buildDetailItem('Business Type', 'Hyperpharmacy & Retail Outlet'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutletsCard(String business) {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assigned Branches & Outlets', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PharmacyColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(PharmacyRadius.card),
              border: Border.all(color: PharmacyColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: PharmacyColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business, style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Primary Dispatch & Pickup Hub • Active Context', style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: PharmacyColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('PRIMARY OUTLET', style: PharmacyTypography.caption.copyWith(color: PharmacyColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryServiceCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery & Service Area', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _buildInfoRow(Icons.local_shipping_outlined, 'Home Delivery', 'Enabled (Max 10 km)'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.store_outlined, 'Store Pickup', 'Available (30 min lead)'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.map_outlined, 'Service Radius', 'Sector 1-12, Central Zone'),
        ],
      ),
    );
  }

  Widget _buildEmergencySupportCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Support & Escalation Contact', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _buildInfoRow(Icons.person_pin_outlined, 'Support Desk', 'SHIELD Operations Desk'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone_in_talk_outlined, 'Support Helpline', '+91 80 4455 6677'),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account & Security', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline_rounded, color: PharmacyColors.navy),
            title: Text('Change Password', style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Manage authentication credentials', style: PharmacyTypography.caption),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          PharmacySecondaryButton(
            label: 'Refresh Profile Data',
            icon: Icons.refresh_rounded,
            compact: true,
            onPressed: _loadProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(String created, String status) {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account System Info', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _buildInfoRow(Icons.calendar_today_outlined, 'Account Created', created),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.verified_user_outlined, 'Account Status', status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: PharmacyColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary)),
              Text(value, style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold, color: PharmacyColors.navy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
