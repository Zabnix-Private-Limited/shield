import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../shared/services/auth_redirect_notice.dart';

class RouteRecoveryScreen extends StatefulWidget {
  const RouteRecoveryScreen({
    super.key,
    required this.title,
    required this.message,
    required this.targetRoute,
    required this.targetLabel,
  });

  final String title;
  final String message;
  final String targetRoute;
  final String targetLabel;

  @override
  State<RouteRecoveryScreen> createState() => _RouteRecoveryScreenState();
}

class _RouteRecoveryScreenState extends State<RouteRecoveryScreen> {
  Timer? _redirectTimer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _goNext();
        return;
      }
      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _goNext() {
    AuthRedirectNotice.instance.clear();
    if (!mounted) {
      return;
    }
    context.go(widget.targetRoute);
  }

  @override
  Widget build(BuildContext context) {
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.shieldNavy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(widget.title, style: AppTypography.h3),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      style: AppTypography.body.copyWith(
                        color: AppColors.gray,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Redirecting in $_secondsRemaining seconds.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _goNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.shieldBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(widget.targetLabel),
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
