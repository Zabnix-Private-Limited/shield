// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.shieldBlue,
      brightness: Brightness.light,
      primary: AppColors.shieldBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.shieldLightBlue,
      surface: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.lightGray,
    cardColor: AppColors.white,
    dividerColor: AppColors.divider,
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displayLarge: AppTypography.h1,
      displayMedium: AppTypography.h2,
      displaySmall: AppTypography.h3,
      headlineMedium: AppTypography.h4,
      titleMedium: AppTypography.h5,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.small,
      bodySmall: AppTypography.tiny,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.shieldBlue,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.shieldBlue),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.shieldBlue,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.divider,
        disabledForegroundColor: AppColors.gray,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.shieldBlue,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.shieldBlue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      labelStyle: AppTypography.small,
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: AppColors.divider,
      labelColor: AppColors.shieldBlue,
      unselectedLabelColor: AppColors.gray,
      labelStyle: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: AppTypography.small.copyWith(
        fontWeight: FontWeight.w600,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.shieldBlue.withValues(alpha: 0.12),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      splashFactory: NoSplash.splashFactory,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white.withValues(alpha: 0.96),
      indicatorColor: AppColors.shieldBlue.withValues(alpha: 0.12),
      elevation: 0,
      height: 74,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return AppTypography.tiny.copyWith(
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          color: active ? AppColors.shieldBlue : AppColors.gray,
        );
      }),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white.withValues(alpha: 0.95),
      foregroundColor: AppColors.shieldNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTypography.h4,
      centerTitle: false,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.shieldBlue,
      foregroundColor: AppColors.white,
    ),
  );
}
