import 'package:flutter/material.dart';

class AdminMetric {
  const AdminMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final Color color;
  final IconData icon;
}
