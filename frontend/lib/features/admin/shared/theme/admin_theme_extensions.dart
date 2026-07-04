import 'package:flutter/material.dart';

import 'admin_colors.dart';
import 'admin_spacing.dart';
import 'admin_typography.dart';

extension AdminThemeX on BuildContext {
  ThemeData get adminTheme => Theme.of(this);
}

class AdminThemeTokens {
  const AdminThemeTokens._();

  static const colors = AdminColors;
  static const spacing = AdminSpacing;
  static const typography = AdminTypography;
}
