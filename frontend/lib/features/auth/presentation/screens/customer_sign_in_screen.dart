import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/services/customer_auth_session.dart';

class CustomerSignInScreen extends StatefulWidget {
  const CustomerSignInScreen({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  State<CustomerSignInScreen> createState() => _CustomerSignInScreenState();
}

class _CustomerSignInScreenState extends State<CustomerSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _memberIdController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _mobileController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await CustomerAuthSession.instance.signInLocally(
        mobile: _mobileController.text,
        memberId: _memberIdController.text,
      );
      if (!mounted) {
        return;
      }
      context.go(_resolveNextLocation());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.toString().replaceFirst('StateError: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _resolveNextLocation() {
    final next = widget.nextLocation?.trim();
    if (next == null || next.isEmpty || !next.startsWith('/')) {
      return '/portal/customer/dashboard';
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final session = CustomerAuthSession.instance;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isWide
                      ? Row(
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 28),
                                child: _AuthStoryPanel(),
                              ),
                            ),
                            Expanded(
                              child: _SignInCard(
                                formKey: _formKey,
                                mobileController: _mobileController,
                                memberIdController: _memberIdController,
                                isSubmitting: _isSubmitting,
                                errorText: _errorText,
                                supportsLocalSignIn:
                                    session.supportsLocalSignIn,
                                onSubmit: _handleSubmit,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const _AuthStoryPanel(compact: true),
                            const SizedBox(height: 20),
                            _SignInCard(
                              formKey: _formKey,
                              mobileController: _mobileController,
                              memberIdController: _memberIdController,
                              isSubmitting: _isSubmitting,
                              errorText: _errorText,
                              supportsLocalSignIn: session.supportsLocalSignIn,
                              onSubmit: _handleSubmit,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7FBFF), Color(0xFFF2F8F6), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              diameter: 240,
              color: AppColors.shieldBlue.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: _GlowOrb(
              diameter: 220,
              color: AppColors.shieldGreen.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(width: diameter, height: diameter, color: color),
        ),
      ),
    );
  }
}

class _AuthStoryPanel extends StatelessWidget {
  const _AuthStoryPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.shieldNavy,
            Color(0xFF143560),
            AppColors.shieldBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.shieldNavy.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'SHIELD Customer Access',
              style: AppTypography.tiny.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Protected sign-in for the SHIELD customer workspace.',
            style: (compact ? AppTypography.h3 : AppTypography.h1).copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start from a dedicated sign-in window, persist the customer session on this device, and redirect unauthenticated visits away from the portal.',
            style: AppTypography.body.copyWith(
              color: AppColors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FeatureChip(
                icon: Icons.shield_outlined,
                title: 'Route protected',
                subtitle: 'Customer pages redirect when session is missing',
              ),
              _FeatureChip(
                icon: Icons.phone_iphone_outlined,
                title: 'Customer-first',
                subtitle: 'Mobile-number entry for the customer workspace',
              ),
              _FeatureChip(
                icon: Icons.autorenew_rounded,
                title: 'Sticky session',
                subtitle: 'Customer access survives app reloads on this device',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.small.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.tiny.copyWith(
                      color: AppColors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.formKey,
    required this.mobileController,
    required this.memberIdController,
    required this.isSubmitting,
    required this.errorText,
    required this.supportsLocalSignIn,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController mobileController;
  final TextEditingController memberIdController;
  final bool isSubmitting;
  final String? errorText;
  final bool supportsLocalSignIn;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shieldNavy.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer sign in', style: AppTypography.h3),
            const SizedBox(height: 8),
            Text(
              'Enter your mobile number to unlock the customer portal on this device.',
              style: AppTypography.body.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 20),
            _AuthField(
              controller: mobileController,
              label: 'Registered mobile number',
              hint: 'Enter 10-digit mobile number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.length < 10) {
                  return 'Enter a valid mobile number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _AuthField(
              controller: memberIdController,
              label: 'SHIELD member ID',
              hint: 'Optional membership or customer code',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.shieldBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      supportsLocalSignIn
                          ? 'This build uses a persisted customer session gate for the current local customer workspace.'
                          : 'Customer route protection is active, but local sign-in is disabled for the current build environment.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 14),
              Text(
                errorText!,
                style: AppTypography.small.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting || !supportsLocalSignIn
                    ? null
                    : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.shieldBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'Continue to customer portal',
                        style: AppTypography.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: AppColors.darkGray,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.shieldBlue,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
