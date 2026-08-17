import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonType { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
  final String text;
  final FutureOr<void> Function()? onPressed;
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _localLoading = false;

  void _handlePress() async {
    if (widget.isLoading || _localLoading || widget.onPressed == null) return;
    final result = widget.onPressed!();
    if (result is Future) {
      setState(() => _localLoading = true);
      try {
        await result;
      } finally {
        if (mounted) {
          setState(() => _localLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLoading = widget.isLoading || _localLoading;
    final effectiveOnPressed = (widget.onPressed == null || effectiveLoading)
        ? null
        : _handlePress;

    final loadingIndicator = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: switch (widget.type) {
          AppButtonType.primary || AppButtonType.danger => Colors.white,
          _ => AppColors.shieldBlue,
        },
      ),
    );

    return SizedBox(
      width: widget.width,
      height: widget.height ?? 54,
      child: switch (widget.type) {
        AppButtonType.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          child: effectiveLoading
              ? loadingIndicator
              : Text(
                  widget.text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        AppButtonType.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.lightGray,
            side: BorderSide.none,
          ),
          child: effectiveLoading
              ? loadingIndicator
              : Text(
                  widget.text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.shieldNavy,
                  ),
                ),
        ),
        AppButtonType.outline => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: effectiveLoading
              ? loadingIndicator
              : Text(
                  widget.text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        AppButtonType.danger => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: effectiveLoading
              ? loadingIndicator
              : Text(
                  widget.text,
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
