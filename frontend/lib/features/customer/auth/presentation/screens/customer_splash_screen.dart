import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/customer_auth_session.dart';

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
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.shieldBlue, AppColors.shieldGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 22),
                Text('SHIELD', style: AppTypography.h2),
                const SizedBox(height: 6),
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
