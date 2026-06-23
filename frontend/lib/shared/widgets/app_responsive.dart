import 'package:flutter/material.dart';

class AppResponsive {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wide = 1440;
  static const double customerPortalMaxWidth = 480;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phone;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static double customerViewportWidth(double availableWidth) {
    if (availableWidth <= customerPortalMaxWidth) return availableWidth;
    return customerPortalMaxWidth;
  }

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wide) return 40;
    if (width >= desktop) return 32;
    if (width >= tablet) return 24;
    return 16;
  }

  static double verticalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 28;
    if (width >= tablet) return 24;
    return 16;
  }

  static double contentMaxWidth(BuildContext context, {double large = 1180}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wide) return large;
    if (width >= desktop) return 1120;
    if (width >= tablet) return 980;
    return width;
  }

  static int adaptiveGridCount(
    BuildContext context, {
    int phoneCount = 1,
    int tabletCount = 2,
    int desktopCount = 3,
    int wideCount = 4,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wide) return wideCount;
    if (width >= desktop) return desktopCount;
    if (width >= tablet) return tabletCount;
    return phoneCount;
  }
}
