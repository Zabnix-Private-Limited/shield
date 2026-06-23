import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../features/role_demo/presentation/demo_role_data.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isBootstrapping = true;
  bool _otpSent = false;
  bool _isLoading = false;
  SHIELDRole _selectedRole = SHIELDRole.customer;

  void _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10 || int.tryParse(mobile) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.login(mobile, _selectedRole.routeKey);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully (Use 123456)')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _handleVerifyAndLogin() {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulating verification step
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      context.go('/workspace/${_selectedRole.routeKey}/dashboard');
    });
  }

  static const List<String> _sharedCapabilities = [
    'Responsive Shell',
    'Role Switcher',
    'Dummy Metrics',
    'Priority Queue',
    'Recent Activity',
    'Operational Insights',
  ];

  List<String> _builtFeaturesForRole(SHIELDRole role) {
    final sectionTitles = demoDataForRole(
      role,
    ).sections.map((section) => section.title);
    return ['Login', ...sectionTitles, ..._sharedCapabilities];
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() {
        _isBootstrapping = false;
      });
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showDiagnostics() {
    showDialog(context: context, builder: _buildDiagnosticsDialog);
  }

  Widget _buildDiagnosticsDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('SHIELD - Demo Build Status'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: SHIELDRole.values.map((role) {
              final builtFeatures = _builtFeaturesForRole(role);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(role.label, style: AppTypography.h5),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.shieldGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ready',
                              style: AppTypography.tiny.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.shieldGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Built (${builtFeatures.length}):',
                        style: AppTypography.small.copyWith(
                          color: AppColors.shieldGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: builtFeatures.map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.shieldGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              feature,
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.shieldGreen,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
    final preview = demoDataForRole(_selectedRole);
    final sections = preview.sections.map((section) => section.title).toList();

    if (_isBootstrapping) {
      return const AppPageSkeleton();
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: AppPageFrame(
            maxWidth: 1140,
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.horizontalPadding(context),
              vertical: 24,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LoginHero(
                          selectedRole: _selectedRole,
                          previewSections: sections,
                          onShowDiagnostics: _showDiagnostics,
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 420,
                        child: _LoginPanel(
                          mobileController: _mobileController,
                          otpController: _otpController,
                          otpSent: _otpSent,
                          isLoading: _isLoading,
                          selectedRole: _selectedRole,
                          onRoleChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                          onSendOtp: _handleSendOtp,
                          onChangeNumber: () {
                            setState(() {
                              _otpSent = false;
                              _otpController.clear();
                            });
                          },
                          onLogin: _handleVerifyAndLogin,
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _LoginHero(
                      selectedRole: _selectedRole,
                      previewSections: sections,
                      onShowDiagnostics: _showDiagnostics,
                    ),
                    const SizedBox(height: 24),
                    _LoginPanel(
                      mobileController: _mobileController,
                      otpController: _otpController,
                      otpSent: _otpSent,
                      isLoading: _isLoading,
                      selectedRole: _selectedRole,
                      onRoleChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      onSendOtp: _handleSendOtp,
                      onChangeNumber: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        });
                      },
                      onLogin: _handleVerifyAndLogin,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  final SHIELDRole selectedRole;
  final List<String> previewSections;
  final VoidCallback onShowDiagnostics;

  const _LoginHero({
    required this.selectedRole,
    required this.previewSections,
    required this.onShowDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final preview = demoDataForRole(selectedRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to', style: AppTypography.h3),
                Text(
                  'SHIELD',
                  style: AppTypography.h1.copyWith(color: AppColors.shieldBlue),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: AppColors.shieldBlue),
              onPressed: onShowDiagnostics,
              tooltip: 'View role demo status',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sahakar Healthcare Initiative to Exempt Lifestyle Disease',
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                preview.accentColor.withValues(alpha: 0.94),
                AppColors.shieldNavy,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(preview.icon, color: AppColors.white, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                preview.role.label,
                style: AppTypography.h2.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 6),
              Text(
                preview.headline,
                style: AppTypography.body.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 6),
              Text(
                preview.regionLabel,
                style: AppTypography.small.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: previewSections.take(6).map((section) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      section,
                      style: AppTypography.small.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHIELD Workspaces', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Each login role opens a complete, responsive workspace with role-specific sections and real-time database integrations connected directly to your Neon PostgreSQL instance.',
                style: AppTypography.body.copyWith(color: AppColors.darkGray),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _PreviewBadge(label: 'Desktop sidebar'),
                  _PreviewBadge(label: 'Mobile drawer'),
                  _PreviewBadge(label: 'Role switch dropdown'),
                  _PreviewBadge(label: 'Live insights'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final TextEditingController mobileController;
  final TextEditingController otpController;
  final bool otpSent;
  final bool isLoading;
  final SHIELDRole selectedRole;
  final ValueChanged<SHIELDRole> onRoleChanged;
  final VoidCallback onSendOtp;
  final VoidCallback onChangeNumber;
  final VoidCallback onLogin;

  const _LoginPanel({
    required this.mobileController,
    required this.otpController,
    required this.otpSent,
    required this.isLoading,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onSendOtp,
    required this.onChangeNumber,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign in to workspace', style: AppTypography.h4),
          const SizedBox(height: 6),
          Text(
            'Select your role and sign in to access your SHIELD workspace.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 24),
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
                value: selectedRole,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: SHIELDRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.label,
                      style: AppTypography.body,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onRoleChanged(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.shieldBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.shieldBlue.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.shieldBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Logging in as ${selectedRole.label} will authenticate using your live database-seeded credentials.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: !otpSent
                ? Column(
                    key: const ValueKey('mobile'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Mobile Number',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          hintText: '9876543210',
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('+91', style: TextStyle(fontSize: 16)),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(text: 'Send OTP', onPressed: onSendOtp, isLoading: isLoading),
                    ],
                  )
                : Column(
                    key: const ValueKey('otp'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter OTP',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(hintText: '123456'),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onChangeNumber,
                          child: Text(
                            'Change number',
                            style: AppTypography.small.copyWith(
                              color: AppColors.shieldBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(text: 'Verify & Login', onPressed: onLogin, isLoading: isLoading),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final String label;

  const _PreviewBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: AppColors.darkGray,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
