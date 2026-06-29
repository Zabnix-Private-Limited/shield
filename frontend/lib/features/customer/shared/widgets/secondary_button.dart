import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_button.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      type: AppButtonType.secondary,
      isLoading: isLoading,
      width: width,
    );
  }
}
