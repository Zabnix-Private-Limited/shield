import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/auth_error_messages.dart';
import '../../../../../shared/services/app_policy_links.dart';
import '../../../../../shared/services/portal_resolver.dart';
import '../../../../../shared/widgets/shield_brand_lockup.dart';
import '../../data/internal_auth_repository.dart';

class InternalLoginScreen extends StatefulWidget {
  const InternalLoginScreen({super.key});

  @override
  State<InternalLoginScreen> createState() => _InternalLoginScreenState();
}

class _InternalLoginScreenState extends State<InternalLoginScreen> {
  bool _submitting = false;
  String? _error;
  String _statusMessage =
      'Use your provisioned Google account to open the provider, CRM, and operational screens.';

  void _trace(String message) {
    debugPrint('[InternalLoginScreen] $message');
  }

  @override
  void initState() {
    super.initState();
    _resumeRedirectLogin();
  }

  Future<void> _resumeRedirectLogin() async {
    _trace('redirect resume check started');
    setState(() {
      _submitting = true;
      _error = null;
      _statusMessage = 'Finishing your secure Google sign-in...';
    });
    try {
      final resumed = await InternalAuthRepository.instance
          .resumeRedirectSignIn();
      if (!mounted) {
        return;
      }
      if (!resumed) {
        _trace('redirect resume found no pending Google session');
        setState(() {
          _submitting = false;
          _statusMessage =
              'Use your provisioned Google account to open the provider, CRM, and operational screens.';
        });
        return;
      }
      _trace('redirect resume completed; proceeding to resolved portal');
      _navigateToResolvedHome();
    } catch (error, stackTrace) {
      _trace('redirect resume failed: $error');
      debugPrintStack(
        label: '[InternalLoginScreen] redirect resume stack',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = AuthErrorMessages.resolve(
          error,
          flow: AuthFlow.internalGoogle,
        );
        _statusMessage =
            'Use your provisioned Google account to open the provider, CRM, and operational screens.';
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _statusMessage = 'Redirecting to Google for secure SHIELD sign-in...';
    });

    try {
      _trace('continue with Google pressed');
      final result = await InternalAuthRepository.instance.signInWithGoogle();
      if (!mounted) {
        return;
      }
      if (result == InternalAuthSignInResult.redirecting) {
        _trace('Google Sign-In switched to browser redirect flow');
        setState(() {
          _statusMessage = 'Redirecting to Google for secure SHIELD sign-in...';
        });
        return;
      }
      _trace('Google Sign-In completed inline; proceeding to resolved portal');
      _navigateToResolvedHome();
    } catch (error, stackTrace) {
      _trace('inline Google Sign-In failed: $error');
      debugPrintStack(
        label: '[InternalLoginScreen] inline login stack',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AuthErrorMessages.resolve(
          error,
          flow: AuthFlow.internalGoogle,
        );
        _statusMessage =
            'Use your provisioned Google account to open the provider, CRM, and operational screens.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _navigateToResolvedHome() {
    if (!mounted) {
      return;
    }
    final resolvedRoute = PortalResolver.resolvedHomeRoute();
    _trace(
      '8. Resolving portal after login role=${PortalResolver.current?.role.routeKey ?? 'unknown'}',
    );
    _trace('9. Navigating to portal route=$resolvedRoute');
    context.go(resolvedRoute);
  }

  @override
  Widget build(BuildContext context) {
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];
    final reasonMessage = switch (reason) {
      'session-expired' =>
        'Your previous SHIELD staff session expired. Please sign in again.',
      _ => null,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.divider),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140B1F33),
                    blurRadius: 32,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShieldBrandLockup(showTagline: true),
                    const SizedBox(height: 18),
                    Text('Internal Access', style: AppTypography.h3),
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage,
                      style: AppTypography.body.copyWith(
                        color: AppColors.gray,
                        height: 1.45,
                      ),
                    ),
                    if (reasonMessage != null) ...[
                      const SizedBox(height: 16),
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
                          style: AppTypography.small.copyWith(
                            color: AppColors.darkGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _handleLogin,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          _submitting
                              ? 'Secure sign-in in progress...'
                              : 'Continue with Google',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.shieldBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final opened =
                              await AppPolicyLinks.openPrivacyPolicy();
                          if (!context.mounted || opened) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to open the privacy policy.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                        ),
                        label: const Text('Privacy Policy'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: AppTypography.small.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
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
