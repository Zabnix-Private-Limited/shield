import 'package:flutter/material.dart';
import 'app_responsive.dart';

class AppPageFrame extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const AppPageFrame({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: AppResponsive.horizontalPadding(context),
          vertical: AppResponsive.verticalPadding(context),
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              maxWidth ?? AppResponsive.contentMaxWidth(context, large: 1240),
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
