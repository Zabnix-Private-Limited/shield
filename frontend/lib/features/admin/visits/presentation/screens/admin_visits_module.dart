import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminVisitsModule extends StatelessWidget {
  const AdminVisitsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Operations / Visits',
      title: 'Visit operations calendar',
      description:
          'A master view of daily, weekly, and monthly visit execution across customers, agents, branches, and providers.',
      primaryAction: const AdminActionItem(label: 'Create visit', icon: Icons.event_available_outlined),
      secondaryAction: const AdminActionItem(label: 'Reschedule batch', icon: Icons.swap_horiz_outlined),
      child: const Column(
        children: [
          AdminSectionTabs(tabs: ['Today', 'Week', 'Month', 'Agenda', 'Provider Schedule']),
          SizedBox(height: 16),
          TwoColumnBody(
            leftTitle: 'Today agenda',
            leftSubtitle: 'Visit sequence with provider, branch, and customer context.',
            leftChild: AdminTimeline(
              items: [
                AdminTimelineItem(time: '10:30', title: 'Arun Thomas • Dermatology', description: 'Kochi Central • Dr. Asha Menon • booked by Rahul Das', accent: AdminColors.visits),
                AdminTimelineItem(time: '11:15', title: 'Lakshmi Nair • Lab panel', description: 'Thrissur Hub • fasting reminder already sent', accent: AdminColors.success),
                AdminTimelineItem(time: '12:00', title: 'Homecare visit at risk', description: 'Provider running late and customer requires re-confirmation', accent: AdminColors.warning),
                AdminTimelineItem(time: '02:45', title: 'Dental consult', description: 'Calicut North • records incomplete before visit', accent: AdminColors.danger),
              ],
            ),
            rightTitle: 'Capacity and filters',
            rightSubtitle: 'Provider load, branch congestion, and at-risk slots.',
            rightChild: Column(
              children: [
                AdminHealthRow(item: AdminHealthItem(label: 'Kochi Central', value: '82%', meta: 'provider utilization', color: AdminColors.success)),
                AdminHealthRow(item: AdminHealthItem(label: 'Calicut North', value: '97%', meta: 'slot congestion', color: AdminColors.danger)),
                AdminHealthRow(item: AdminHealthItem(label: 'Thrissur Hub', value: '76%', meta: 'healthy spread', color: AdminColors.visits)),
                AdminHealthRow(item: AdminHealthItem(label: 'Trivandrum City', value: '88%', meta: 'watch noon surge', color: AdminColors.warning)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
