import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_orders_repository.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';
import 'package:shield/shared/services/internal_auth_session.dart';
import 'package:shield/shared/widgets/portal_support.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;
  final PharmacyOrdersRepository _repository = PharmacyOrdersRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessCodeController = TextEditingController();
  final TextEditingController _drugLicenceController = TextEditingController();
  final TextEditingController _operatingHoursController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();

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

    _businessNameController.dispose();
    _businessCodeController.dispose();
    _drugLicenceController.dispose();
    _operatingHoursController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _gstinController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.fetchPharmacyProfile();
      if (!mounted) return;
      setState(() {
        _profileData = data;
        _isLoading = false;
        _nameController.text = data['displayName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';

        _businessNameController.text = data['pharmacyName'] ?? '';
        _businessCodeController.text = data['businessCode'] ?? '';
        _drugLicenceController.text = data['drugLicenceNo'] ?? '';
        _operatingHoursController.text = data['operatingHours'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _pinController.text = data['pin'] ?? '';
        _gstinController.text = data['gstin'] ?? '';
        _businessTypeController.text = data['businessType'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      final errText = e.toString();
      final msg = errText.contains('not assigned')
          ? 'Your SHIELD administrator has not assigned a Pharmacy/Outlet to this account.'
          : 'Pharmacy access is currently unavailable. Contact SHIELD administration.';
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  void _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'pharmacyName': _businessNameController.text.trim(),
        'businessCode': _businessCodeController.text.trim(),
        'drugLicenceNo': _drugLicenceController.text.trim(),
        'operatingHours': _operatingHoursController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pin': _pinController.text.trim(),
        'gstin': _gstinController.text.trim(),
        'businessType': _businessTypeController.text.trim(),
      };
      final updated = await _repository.updatePharmacyProfile(payload);
      if (!mounted) return;
      setState(() {
        _profileData = updated;
        _isSaving = false;
      });
      showPortalSnackBar(
        context,
        'Pharmacy & Business Details updated and persisted successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showPortalSnackBar(
        context,
        'Failed to update profile: $e',
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

    if (_errorMessage != null && _profileData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: PharmacyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 56, color: PharmacyColors.warning),
                const SizedBox(height: 16),
                Text(
                  'No Pharmacy Assigned',
                  style: PharmacyTypography.h2.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: PharmacyTypography.body.copyWith(color: PharmacyColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: PharmacyPrimaryButton(
                    label: 'Retry / Refresh Assignment',
                    icon: Icons.refresh_rounded,
                    onPressed: () => _loadProfile(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final session = InternalAuthSession.instance;
    final userName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (session.displayName ?? 'Pharmacy Staff');
    final userEmail = _emailController.text.isNotEmpty
        ? _emailController.text
        : (session.email ?? '—');
    final userRole = _profileData?['roleCode'] ?? session.roleCode ?? 'PHARMACY_PROVIDER';
    final businessName = _businessNameController.text.isNotEmpty
        ? _businessNameController.text
        : (_profileData?['pharmacyName'] ?? 'Unassigned Outlet');
    final businessCode = _businessCodeController.text.isNotEmpty
        ? _businessCodeController.text
        : (_profileData?['businessCode'] ?? '—');
    final drugLicence = _drugLicenceController.text.isNotEmpty
        ? _drugLicenceController.text
        : (_profileData?['drugLicenceNo'] ?? 'Not Specified');
    final gstin = _gstinController.text.isNotEmpty
        ? _gstinController.text
        : (_profileData?['gstin'] ?? 'Not Specified');
    final address = _addressController.text.isNotEmpty
        ? _addressController.text
        : (_profileData?['address'] ?? 'Not Specified');

    final String cityVal = _cityController.text.isNotEmpty
        ? _cityController.text
        : (_profileData?['city'] ?? '');
    final String stateVal = _stateController.text.isNotEmpty
        ? _stateController.text
        : (_profileData?['state'] ?? '');
    final String pinVal = _pinController.text.isNotEmpty
        ? _pinController.text
        : (_profileData?['pin'] ?? '');

    final cityStatePin = cityVal.isNotEmpty
        ? '$cityVal${stateVal.isNotEmpty ? ', $stateVal' : ''}${pinVal.isNotEmpty ? ' — $pinVal' : ''}'
        : 'Not Specified';

    final operatingHours = _operatingHoursController.text.isNotEmpty
        ? _operatingHoursController.text
        : (_profileData?['operatingHours'] ?? 'Standard Operating Hours');

    final businessType = _businessTypeController.text.isNotEmpty
        ? _businessTypeController.text
        : (_profileData?['businessType'] ?? 'Hyperpharmacy & Retail Outlet');

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isWideDesktop = screenWidth >= 1200;
    final isCompactHeader = screenWidth < 640;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Header Section
          PharmacyCard(
            padding: const EdgeInsets.all(20),
            child: isCompactHeader
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pharmacy Profile',
                                  style: PharmacyTypography.h2.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage account identity and provider details.',
                                  style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: PharmacyPrimaryButton(
                          label: 'Save Profile',
                          icon: Icons.save_rounded,
                          isLoading: _isSaving,
                          onPressed: _handleSave,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
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
                            Expanded(
                              child: Column(
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
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
                // Left Column: User Profile Details
                SizedBox(
                  width: isWideDesktop ? 340 : 300,
                  child: _buildUserProfileCard(userName, userEmail, userRole, businessName),
                ),
                const SizedBox(width: 20),

                // Center Column: Business Details
                Expanded(
                  child: _buildBusinessDetailsCard(businessName, businessCode, drugLicence, gstin, address, cityStatePin, operatingHours, businessType),
                ),
              ],
            )
          else ...[
            // Stacked Mobile / Tablet Layout
            _buildUserProfileCard(userName, userEmail, userRole, businessName),
            const SizedBox(height: 16),
            _buildBusinessDetailsCard(businessName, businessCode, drugLicence, gstin, address, cityStatePin, operatingHours, businessType),
          ],

          const SizedBox(height: 24),
          // Bottom Actions Row
          PharmacyCard(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 450;
                return isCompact
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: PharmacyPrimaryButton(
                              label: 'Save Profile Changes',
                              icon: Icons.check_circle_outline,
                              isLoading: _isSaving,
                              onPressed: _handleSave,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: PharmacySecondaryButton(
                              label: 'Discard Changes',
                              onPressed: _loadProfile,
                            ),
                          ),
                        ],
                      )
                    : Row(
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
                      );
              },
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
                    Text(
                      name,
                      style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone_outlined, 'Mobile Contact', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not Specified'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email_outlined, 'Email Address', email.isNotEmpty ? email : 'Not Specified'),
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
        content: SingleChildScrollView(
          child: Column(
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

  void _showEditBusinessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pharmacy & Business Details'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    hintText: 'e.g. SHIELD Hyper Pharmacy Perinthalmanna',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _businessCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Business Code',
                    hintText: 'e.g. HYP-PERINTHALMANNA',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _drugLicenceController,
                  decoration: const InputDecoration(
                    labelText: 'Drug Licence No.',
                    hintText: 'e.g. DL-2026/PHARM/77821',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _operatingHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Operating Hours',
                    hintText: 'e.g. 24/7 Standard Operating Hours',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Registered Address',
                    hintText: 'e.g. Main Road, Near Jubilee Hospital',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'State'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _pinController,
                        decoration: const InputDecoration(labelText: 'PIN Code'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _gstinController,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN / Tax ID',
                    hintText: 'e.g. 32AABCS1429B1Z5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _businessTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    hintText: 'e.g. Hyperpharmacy & Retail Outlet',
                  ),
                ),
              ],
            ),
          ),
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
            child: const Text('Save Business Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsCard(
    String business,
    String code,
    String licence,
    String gstin,
    String address,
    String cityStatePin,
    String hours,
    String businessType,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        return PharmacyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Pharmacy & Business Details',
                          style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PharmacyColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'VERIFIED PHARMACY',
                            style: PharmacyTypography.caption.copyWith(color: PharmacyColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PharmacySecondaryButton(
                    label: 'Edit Details',
                    icon: Icons.edit_note_rounded,
                    compact: true,
                    onPressed: _showEditBusinessDialog,
                  ),
                ],
              ),
              const Divider(height: 24),
              if (isCompact) ...[
                _buildDetailItem('Business Name', business),
                const SizedBox(height: 12),
                _buildDetailItem('Business Code', code),
                const SizedBox(height: 12),
                _buildDetailItem('Drug Licence No.', licence),
                const SizedBox(height: 12),
                _buildDetailItem('Operating Hours', hours),
                const SizedBox(height: 12),
                _buildDetailItem('Registered Address', address),
                const SizedBox(height: 12),
                _buildDetailItem('City / State / PIN', cityStatePin),
                const SizedBox(height: 12),
                _buildDetailItem('GSTIN / Tax ID', gstin),
                const SizedBox(height: 12),
                _buildDetailItem('Business Type', businessType),
              ] else ...[
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
                          _buildDetailItem('Business Type', businessType),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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
              Text(
                value,
                style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold, color: PharmacyColors.navy),
                overflow: TextOverflow.ellipsis,
              ),
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
        Text(
          value,
          style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}
