import 'package:flutter/material.dart';

class AdminTimelineItem {
  const AdminTimelineItem({
    required this.time,
    required this.title,
    required this.description,
    required this.accent,
  });

  final String time;
  final String title;
  final String description;
  final Color accent;
}
