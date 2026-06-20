import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonType { primary, secondary, outline, danger }

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
    final loadingIndicator = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: switch (type) {
          AppButtonType.primary || AppButtonType.danger => Colors.white,
          _ => AppColors.shieldBlue,
        },
      ),
    );

    return SizedBox(
      width: width,
      height: height ?? 54,
      child: switch (type) {
        AppButtonType.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? loadingIndicator
              : Text(
                  text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        AppButtonType.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.lightGray,
            side: BorderSide.none,
          ),
          child: isLoading
              ? loadingIndicator
              : Text(
                  text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.shieldNavy,
                  ),
                ),
        ),
        AppButtonType.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? loadingIndicator
              : Text(
                  text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        AppButtonType.danger => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: isLoading
              ? loadingIndicator
              : Text(
                  text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      },
    );
  }
}
