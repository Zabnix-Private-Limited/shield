import 'package:flutter/material.dart';

import 'error_card.dart';

class NetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorCard(
      title: 'Network unavailable',
      message:
          'We could not reach SHIELD right now. Check the connection and try again.',
      onRetry: onRetry,
    );
  }
}
