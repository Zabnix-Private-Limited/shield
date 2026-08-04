import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';

/// Presentation-only tokens for every authenticated customer surface.
abstract final class CustomerDesignTokens {
  static const pageBackground = AppColors.lightGray;
  static const surface = AppColors.white;
  static const border = AppColors.divider;
  static const textPrimary = AppColors.shieldNavy;
  static const textSecondary = AppColors.gray;
  static const cash = Color(0xFF0F9F9A);
  static const reward = Color(0xFFE09A00);
  static const document = Color(0xFF7C3AED);
  static const commerce = Color(0xFFF97316);

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const space40 = 40.0;

  static const controlRadius = 14.0;
  static const cardRadius = 20.0;
  static const largeCardRadius = 24.0;
  static const pillRadius = 999.0;
  static const standardMotion = Duration(milliseconds: 240);
  static const fastMotion = Duration(milliseconds: 140);

  static TextStyle get pageTitle => AppTypography.h2.copyWith(
    color: textPrimary,
    fontWeight: FontWeight.w800,
  );
  static TextStyle get sectionTitle => AppTypography.h4.copyWith(
    color: textPrimary,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get caption =>
      AppTypography.tiny.copyWith(color: textSecondary);
}
