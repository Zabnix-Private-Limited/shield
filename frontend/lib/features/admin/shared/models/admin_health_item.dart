import 'package:flutter/material.dart';

class AdminHealthItem {
  const AdminHealthItem({
    required this.label,
    required this.value,
    required this.meta,
    required this.color,
  });

  final String label;
  final String value;
  final String meta;
  final Color color;
}
