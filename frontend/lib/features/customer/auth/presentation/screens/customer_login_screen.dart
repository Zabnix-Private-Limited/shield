import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/auth_error_messages.dart';
import '../../../../../shared/services/app_policy_links.dart';
import '../../data/customer_auth_repository.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final result = await CustomerAuthRepository.instance
          .startPhoneVerification(_phoneController.text);
      if (!mounted) {
        return;
      }
      switch (result) {
        case CustomerPhoneVerificationStartResult.authenticated:
          context.go('/portal/customer/dashboard');
          break;
        case CustomerPhoneVerificationStartResult.registrationRequired:
          context.go('/customer/register');
          break;
        case CustomerPhoneVerificationStartResult.codeSent:
          context.go('/customer/otp');
          break;
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorText = AuthErrorMessages.resolve(
          error,
          flow: AuthFlow.customerLogin,
        );
      });
    } catch (error) {
      setState(() {
        _errorText = AuthErrorMessages.resolve(
          error,
          flow: AuthFlow.customerLogin,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];
    final reasonMessage = switch (reason) {
      'session-expired' =>
        'Your SHIELD member session expired. Please sign in again to continue.',
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Image.asset(
                        'assets/logos/shield_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Image.asset(
                      'assets/logos/shield_wordmark.png',
                      width: 320,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Secure access to your healthcare benefits.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: AppColors.gray),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Theme.of(context).platform == TargetPlatform.android ||
                              Theme.of(context).platform == TargetPlatform.iOS
                          ? 'On the SHIELD app, OTP verification stays in-app whenever Firebase can verify your device automatically.'
                          : 'Browser-based sign-in may occasionally require a quick anti-abuse verification before OTP can be sent.',
                      textAlign: TextAlign.center,
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                        height: 1.45,
                      ),
                    ),
                    if (reasonMessage != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          reasonMessage,
                          textAlign: TextAlign.center,
                          style: AppTypography.small.copyWith(
                            color: AppColors.darkGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mobile Number',
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: InputDecoration(
                        prefixText: '+91 ',
                        hintText: '98765 43210',
                        filled: true,
                        fillColor: AppColors.lightGray,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        final digits =
                            value?.replaceAll(RegExp(r'\D'), '') ?? '';
                        if (digits.length != 10) {
                          return 'Enter a valid 10-digit mobile number.';
                        }
                        return null;
                      },
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        style: AppTypography.small.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.shieldBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'By continuing you agree to the Terms & Privacy.',
                      textAlign: TextAlign.center,
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final opened = await AppPolicyLinks.openPrivacyPolicy();
                        if (!context.mounted || opened) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to open the privacy policy.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user_outlined, size: 18),
                      label: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
