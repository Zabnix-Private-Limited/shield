import 'package:flutter/material.dart';

import '../../../customer/auth/presentation/screens/customer_login_screen.dart';

class CustomerSignInScreen extends StatelessWidget {
  const CustomerSignInScreen({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  Widget build(BuildContext context) {
    return const CustomerLoginScreen();
  }
}
