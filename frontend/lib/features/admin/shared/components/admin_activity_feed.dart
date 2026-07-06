import 'package:flutter/material.dart';

import '../models/admin_timeline_item.dart';
import 'admin_timeline.dart';

class AdminActivityFeed extends StatelessWidget {
  const AdminActivityFeed({super.key, required this.items});

  final List<AdminTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return AdminTimeline(items: items);
  }
}
