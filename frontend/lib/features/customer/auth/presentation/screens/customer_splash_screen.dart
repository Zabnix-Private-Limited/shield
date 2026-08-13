import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/customer_auth_session.dart';
import '../../../../../shared/services/portal_resolver.dart';

class CustomerSplashScreen extends StatefulWidget {
  const CustomerSplashScreen({super.key});

  @override
  State<CustomerSplashScreen> createState() => _CustomerSplashScreenState();
}

class _CustomerSplashScreenState extends State<CustomerSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeNext());
  }

  Future<void> _routeNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) {
      return;
    }
    if (PortalResolver.current != null) {
      context.go(PortalResolver.resolvedHomeRoute());
      return;
    }
    if (CustomerAuthSession.instance.isAuthenticated) {
      context.go('/portal/customer/dashboard');
      return;
    }
    context.go('/customer/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shieldNavy.withValues(alpha: 0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logos/shield_mark.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield_outlined,
                      color: AppColors.shieldBlue,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Image.asset(
                  'assets/logos/shield_wordmark.png',
                  width: 320,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sahakar Healthcare Member Portal',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.shieldBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
