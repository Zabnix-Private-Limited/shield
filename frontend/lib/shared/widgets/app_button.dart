import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonType {
  primary,
  secondary,
  outline,
  danger,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 56,
      child: switch (type) {
        AppButtonType.primary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(text, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ),
        AppButtonType.secondary => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.lightGray,
            ),
            child: isLoading
                ? const CircularProgressIndicator()
                : Text(text, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.shieldNavy)),
          ),
        AppButtonType.outline => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const CircularProgressIndicator()
                : Text(text, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ),
        AppButtonType.danger => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(text, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
      },
    );
  }
}
