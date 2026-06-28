import 'package:flutter/widgets.dart';

class TurnstileChallenge extends StatelessWidget {
  final String siteKey;
  final ValueChanged<String?> onTokenChanged;
  final ValueChanged<String>? onError;

  const TurnstileChallenge({
    super.key,
    required this.siteKey,
    required this.onTokenChanged,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
