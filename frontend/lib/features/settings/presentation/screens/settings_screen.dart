import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/demo_support.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        child: AppPageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsSection(
                title: 'Account',
                items: [
                  _SettingsItem(
                    icon: Icons.edit,
                    label: 'Edit Profile',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Profile editing is represented in the customer profile and role-based member screens.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.lock,
                    label: 'Change PIN',
                    onTap: () => showDemoSnackBar(
                      context,
                      'PIN and device-security settings are part of the frontend-only demo.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip,
                    label: 'Privacy Settings',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Privacy controls are demonstrated in the customer settings and super-admin system pages.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SettingsSection(
                title: 'Notifications',
                items: [
                  _SettingsItem(
                    icon: Icons.notifications,
                    label: 'Push Notifications',
                    hasSwitch: true,
                    initialValue: true,
                  ),
                  _SettingsItem(
                    icon: Icons.email,
                    label: 'Email Notifications',
                    hasSwitch: true,
                    initialValue: true,
                  ),
                  _SettingsItem(
                    icon: Icons.sms,
                    label: 'SMS Notifications',
                    hasSwitch: true,
                    initialValue: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Support',
                items: [
                  _SettingsItem(
                    icon: Icons.help,
                    label: 'Help & Support',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Support flows are represented in the customer settings and SHIELD support-case demo pages.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.contact_support,
                    label: 'Contact Us',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Contact channels are kept dummy-only for this frontend review build.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.feedback,
                    label: 'Feedback',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Feedback capture is shown as a frontend placeholder without backend submission.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'About',
                items: [
                  _SettingsItem(
                    icon: Icons.info,
                    label: 'About SHIELD',
                    onTap: () => showDemoSnackBar(
                      context,
                      'SHIELD is presented here as the unified Sahakar healthcare platform demo.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.description,
                    label: 'Terms & Conditions',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Legal documents are intentionally represented as static frontend placeholders in this demo.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.policy,
                    label: 'Privacy Policy',
                    onTap: () => showDemoSnackBar(
                      context,
                      'Privacy policy content will be wired later when backend/content services are introduced.',
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.update,
                    label: 'Check for Updates',
                    onTap: () => showDemoSnackBar(
                      context,
                      'This demo build is already on the latest local frontend version.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: Text(
                    'Logout',
                    style: AppTypography.body.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool hasSwitch;
  final bool initialValue;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.hasSwitch = false,
    this.initialValue = false,
  });

  @override
  State<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<_SettingsItem> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.hasSwitch ? null : widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.shieldBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: AppColors.shieldBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(widget.label, style: AppTypography.body)),
            if (widget.hasSwitch)
              Switch(
                value: _value,
                onChanged: (newValue) {
                  setState(() {
                    _value = newValue;
                  });
                },
                activeThumbColor: AppColors.shieldBlue,
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.gray,
              ),
          ],
        ),
      ),
    );
  }
}
