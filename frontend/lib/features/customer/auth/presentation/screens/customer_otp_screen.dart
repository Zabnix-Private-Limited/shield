import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../data/customer_auth_repository.dart';

class CustomerOtpScreen extends StatefulWidget {
  const CustomerOtpScreen({super.key});

  @override
  State<CustomerOtpScreen> createState() => _CustomerOtpScreenState();
}

class _CustomerOtpScreenState extends State<CustomerOtpScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _ticker;
  bool _isSubmitting = false;
  String? _errorText;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    if (CustomerAuthRepository.instance.pendingPhoneNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/customer/login');
        }
      });
      return;
    }
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _ticker?.cancel();
    _remainingSeconds = 30;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorText = 'Enter the 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final outcome = await CustomerAuthRepository.instance.verifyOtp(otp);
      if (!mounted) {
        return;
      }
      if (outcome == CustomerAuthOutcome.authenticated) {
        context.go('/portal/customer/dashboard');
        return;
      }
      context.go('/customer/register');
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorText = error.message ?? 'OTP verification failed.';
      });
    } catch (error) {
      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _errorText = null;
    });
    try {
      await CustomerAuthRepository.instance.resendOtp();
      _startTimer();
    } catch (error) {
      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone =
        CustomerAuthRepository.instance.pendingPhoneNumber ?? '+91 ••••••••••';
    final digits = _otpController.text.padRight(6).split('');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/customer/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify your number', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    Text(
                      'OTP sent to',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(phone, style: AppTypography.h5),
                    const SizedBox(height: 26),
                    Stack(
                      children: [
                        Opacity(
                          opacity: 0.02,
                          child: TextField(
                            controller: _otpController,
                            focusNode: _focusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            maxLength: 6,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _verify(),
                          ),
                        ),
                        IgnorePointer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              final char = digits[index].trim();
                              return Container(
                                width: 52,
                                height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: char.isNotEmpty
                                        ? AppColors.shieldBlue
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: AppTypography.h4.copyWith(
                                    color: AppColors.shieldNavy,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorText!,
                        style: AppTypography.small.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Text("Didn't receive it?", style: AppTypography.body),
                    const SizedBox(height: 6),
                    _remainingSeconds > 0
                        ? Text(
                            'Resend in ${_remainingSeconds}s',
                            style: AppTypography.small.copyWith(
                              color: AppColors.gray,
                            ),
                          )
                        : TextButton(
                            onPressed: _resend,
                            child: Text(
                              'Resend OTP',
                              style: AppTypography.small.copyWith(
                                color: AppColors.shieldBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _verify,
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
                                'Verify',
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
            ),
          ),
        ),
      ),
    );
  }
}
