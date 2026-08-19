import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/shared/services/internal_auth_session.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  bool _isSaving = false;

  void _handleSave() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pharmacy Profile saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = InternalAuthSession.instance;
    final userName = (session.displayName != null && session.displayName!.isNotEmpty)
        ? session.displayName!
        : 'Pharmacy Staff';
    final userEmail = (session.email != null && session.email!.isNotEmpty)
        ? session.email!
        : 'pharmacist@shieldhealth.org';
    final userRole = (session.roleCode != null && session.roleCode!.isNotEmpty)
        ? session.roleCode!
        : 'PHARMACY_PROVIDER';
    final businessName = 'Sahakar Pharmacy Outlet';

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
                      _buildBusinessDetailsCard(businessName),
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
                      _buildAccountInfoCard(),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            // Stacked Mobile / Tablet Layout
            _buildUserProfileCard(userName, userEmail, userRole, businessName),
            const SizedBox(height: 16),
            _buildBusinessDetailsCard(businessName),
            const SizedBox(height: 16),
            _buildOutletsCard(businessName),
            const SizedBox(height: 16),
            _buildDeliveryServiceCard(),
            const SizedBox(height: 16),
            _buildSecurityCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildAccountInfoCard(),
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
                  onPressed: () {},
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
          _buildInfoRow(Icons.phone_outlined, 'Mobile Contact', '+91 98765 43210'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email_outlined, 'Email Address', email),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.business_rounded, 'Assigned Outlet', business),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PharmacySecondaryButton(
              label: 'Edit User Profile',
              icon: Icons.edit_outlined,
              compact: true,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsCard(String business) {
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
                    _buildDetailItem('Business Code', 'PHARM-SHIELD-001'),
                    const SizedBox(height: 12),
                    _buildDetailItem('Drug Licence No.', 'DL-PHARM-2026-8841'),
                    const SizedBox(height: 12),
                    _buildDetailItem('Operating Hours', '08:00 AM - 10:00 PM (Mon-Sat)'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Registered Address', 'Building 14, Health Park Road, Sector 4'),
                    const SizedBox(height: 12),
                    _buildDetailItem('City / State / PIN', 'Bangalore, Karnataka — 560001'),
                    const SizedBox(height: 12),
                    _buildDetailItem('GSTIN / Tax ID', '29ABCDE1234F1Z5'),
                    const SizedBox(height: 12),
                    _buildDetailItem('Business Type', 'Hyperpharmacy & Retail Outlet'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: PharmacySecondaryButton(
              label: 'Edit Business Details',
              icon: Icons.edit_note_rounded,
              compact: true,
              onPressed: () {},
            ),
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
          _buildInfoRow(Icons.person_pin_outlined, 'Lead Pharmacist', 'Dr. Rajesh Sharma'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone_in_talk_outlined, 'Support Desk', '+91 80 4455 6677'),
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
            subtitle: Text('Last updated 30 days ago', style: PharmacyTypography.caption),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.devices_rounded, color: PharmacyColors.navy),
            title: Text('Active Sessions', style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('1 active Web session', style: PharmacyTypography.caption),
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
            label: 'Download Business Certificate',
            icon: Icons.download_rounded,
            compact: true,
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          PharmacySecondaryButton(
            label: 'View Pharmacy Storefront',
            icon: Icons.open_in_new_rounded,
            compact: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account System Info', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _buildInfoRow(Icons.calendar_today_outlined, 'Account Created', '2026-01-15'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time_rounded, 'Last Login', 'Today 08:30 AM'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.verified_user_outlined, 'Account Status', 'ACTIVE & VERIFIED'),
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
