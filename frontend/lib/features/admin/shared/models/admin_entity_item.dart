import 'package:flutter/material.dart';

class AdminEntityItem {
  const AdminEntityItem({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String status;
  final Color color;
}
