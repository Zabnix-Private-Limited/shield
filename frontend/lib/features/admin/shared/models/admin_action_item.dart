import 'package:flutter/material.dart';

class AdminActionItem {
  const AdminActionItem({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}
