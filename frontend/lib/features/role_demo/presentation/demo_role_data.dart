import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/shield_role.dart';

class DemoMetric {
  final String label;
  final String value;
  final String note;

  const DemoMetric({
    required this.label,
    required this.value,
    required this.note,
  });

  factory DemoMetric.fromJson(Map<String, dynamic> json) {
    return DemoMetric(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class DemoListItem {
  final String title;
  final String subtitle;
  final String meta;
  final String status;

  const DemoListItem({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  factory DemoListItem.fromJson(Map<String, dynamic> json) {
    return DemoListItem(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      meta: (json['meta'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class DemoSectionData {
  final String key;
  final String title;
  final String summary;
  final List<String> actions;
  final List<DemoMetric> metrics;
  final List<DemoListItem> queueItems;
  final List<DemoListItem> recentItems;
  final List<DemoListItem> insightItems;

  const DemoSectionData({
    required this.key,
    required this.title,
    required this.summary,
    required this.actions,
    required this.metrics,
    required this.queueItems,
    required this.recentItems,
    required this.insightItems,
  });

  factory DemoSectionData.fromJson(Map<String, dynamic> json) {
    return DemoSectionData(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      actions: List<String>.from(json['actions'] ?? []),
      metrics: (json['metrics'] as List? ?? [])
          .map((m) => DemoMetric.fromJson(m as Map<String, dynamic>))
          .toList(),
      queueItems: (json['queueItems'] as List? ?? [])
          .map((q) => DemoListItem.fromJson(q as Map<String, dynamic>))
          .toList(),
      recentItems: (json['recentItems'] as List? ?? [])
          .map((r) => DemoListItem.fromJson(r as Map<String, dynamic>))
          .toList(),
      insightItems: (json['insightItems'] as List? ?? [])
          .map((i) => DemoListItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DemoRoleData {
  final SHIELDRole role;
  final String operatorName;
  final String headline;
  final String regionLabel;
  final IconData icon;
  final Color accentColor;
  final List<DemoSectionData> sections;

  const DemoRoleData({
    required this.role,
    required this.operatorName,
    required this.headline,
    required this.regionLabel,
    required this.icon,
    required this.accentColor,
    required this.sections,
  });

  DemoSectionData get defaultSection => sections.first;

  DemoSectionData sectionFor(String? key) {
    return sections.firstWhere(
      (section) => section.key == key,
      orElse: () => defaultSection,
    );
  }
}

DemoRoleData demoDataForRole(SHIELDRole role) {
  switch (role) {
    case SHIELDRole.customer:
      return DemoRoleData(
        role: role,
        operatorName: 'Nihal Rahman',
        headline: 'Personal healthcare wallet and records at a glance',
        regionLabel: 'Perinthalmanna member cluster',
        icon: Icons.person,
        accentColor: AppColors.shieldBlue,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Track membership, wallet balance, appointments, and recent medical documents from one compact home view.',
            actions: const ['View card', 'Book visit', 'Open wallet'],
            metrics: const [
              DemoMetric(
                label: 'Wallet balance',
                value: '₹5,450',
                note: 'After last pharmacy spend',
              ),
              DemoMetric(
                label: 'Upcoming visits',
                value: '3',
                note: 'Perinthalmanna and Manjeri',
              ),
              DemoMetric(
                label: 'Pending docs',
                value: '2',
                note: 'Awaiting validation',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Membership renewal ready',
                subtitle:
                    'Founding benefits retained for the Malappuram healthcare network.',
                meta: '20 Jun 2026',
                status: 'Open',
              ),
              DemoListItem(
                title: 'Prescription uploaded',
                subtitle:
                    'Hyper Pharmacy Melattur sent a digital prescription for review.',
                meta: '20 Jun 2026, 7:30 PM',
                status: 'Validated',
              ),
              DemoListItem(
                title: 'Appointment reminder',
                subtitle:
                    'Smart Clinic Manjeri consultation is scheduled for Sunday, June 21, 2026 morning.',
                meta: '21 Jun 2026',
                status: 'Confirmed',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Wallet credited',
                subtitle:
                    'Bonus benefit added after preventive care package completion.',
                meta: 'Perinthalmanna',
                status: 'Credit',
              ),
              DemoListItem(
                title: 'Lab report shared',
                subtitle:
                    'CBC and sugar panel are now available in your documents.',
                meta: 'Makkaraparamba',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Dental follow-up planned',
                subtitle:
                    'Scaling review booked for Friday, June 26, 2026 afternoon.',
                meta: 'Melattur',
                status: 'Scheduled',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most used location',
                subtitle:
                    'Perinthalmanna Hyper Pharmacy continues to be the primary visit point.',
                meta: '67% of visits',
                status: 'Insight',
              ),
              DemoListItem(
                title: 'Care pattern',
                subtitle:
                    'Preventive lab and pharmacy usage increased this quarter.',
                meta: 'Quarter trend',
                status: 'Up',
              ),
            ],
          ),
          DemoSectionData(
            key: 'wallet',
            title: 'Wallet',
            summary:
                'Review available balance, recent deductions, recharge requests, and care-linked savings using demo ledger data.',
            actions: const [
              'Raise recharge request',
              'Download statement',
              'View credit note',
            ],
            metrics: const [
              DemoMetric(
                label: 'Available balance',
                value: '₹5,450',
                note: 'Active demo ledger',
              ),
              DemoMetric(
                label: 'Monthly spend',
                value: '₹2,050',
                note: 'Pharmacy + clinic',
              ),
              DemoMetric(
                label: 'Credit facility',
                value: '₹3,000',
                note: 'Manager-approved',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Hyper Pharmacy purchase',
                subtitle:
                    'Family medicines billed to wallet with member discount applied.',
                meta: 'Perinthalmanna',
                status: 'Settled',
              ),
              DemoListItem(
                title: 'Consultation debit',
                subtitle:
                    'General medicine fee posted from Smart Clinic Manjeri.',
                meta: 'Manjeri',
                status: 'Settled',
              ),
              DemoListItem(
                title: 'Preventive camp bonus',
                subtitle:
                    'Wellness camp incentive pushed after attendance confirmation.',
                meta: 'Alanallur',
                status: 'Credit',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Discount captured',
                subtitle:
                    'Founding member pharmacy discount reflected in final amount.',
                meta: '₹180 saved',
                status: 'Applied',
              ),
              DemoListItem(
                title: 'Recharge request draft',
                subtitle:
                    'A manual top-up request is ready for SHIELD executive review.',
                meta: 'Customer initiated',
                status: 'Draft',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best savings location',
                subtitle:
                    'Perinthalmanna and Tirur branches show the strongest recurring discounts.',
                meta: 'Savings map',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Wallet advice',
                subtitle:
                    'Current balance comfortably covers the next two scheduled care events.',
                meta: 'Projection',
                status: 'Healthy',
              ),
            ],
          ),
          DemoSectionData(
            key: 'appointments',
            title: 'Appointments',
            summary:
                'See all consultations, lab visits, dental slots, and home-visit requests arranged across SHIELD partner locations.',
            actions: const ['Book consultation', 'Reschedule', 'Share slot'],
            metrics: const [
              DemoMetric(
                label: 'Confirmed',
                value: '2',
                note: '21 Jun and 26 Jun',
              ),
              DemoMetric(
                label: 'Pending',
                value: '1',
                note: 'Home visit review',
              ),
              DemoMetric(
                label: 'Completed this month',
                value: '4',
                note: 'Across 3 facilities',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'General medicine review',
                subtitle: 'Dr. Haneefa P will see you at 10:00 AM.',
                meta: 'Manjeri',
                status: '21 Jun 2026',
              ),
              DemoListItem(
                title: 'Dental scaling review',
                subtitle: 'Chair slot reserved for afternoon follow-up.',
                meta: 'Melattur',
                status: '26 Jun 2026',
              ),
              DemoListItem(
                title: 'Home BP check request',
                subtitle:
                    'Nurse allocation pending for Alanallur route coverage.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Lab visit completed',
                subtitle:
                    'CBC sample collected and routed for quick turnaround.',
                meta: 'Tirur',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Appointment reminder sent',
                subtitle: 'Push and SMS reminders delivered successfully.',
                meta: 'System',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Preferred slot',
                subtitle:
                    'Morning visits have the highest completion rate in this profile.',
                meta: 'Behavior trend',
                status: 'Insight',
              ),
              DemoListItem(
                title: 'Travel pattern',
                subtitle:
                    'Perinthalmanna and Manjeri remain the easiest service points for this member.',
                meta: 'Location fit',
                status: 'Strong',
              ),
            ],
          ),
          DemoSectionData(
            key: 'documents',
            title: 'Documents',
            summary:
                'Browse demo prescriptions, lab reports, dental records, and claim-ready files stored in the member timeline.',
            actions: const ['Upload file', 'Filter by type', 'Share PDF'],
            metrics: const [
              DemoMetric(
                label: 'Approved files',
                value: '12',
                note: 'Ready for viewing',
              ),
              DemoMetric(
                label: 'In review',
                value: '2',
                note: 'Manual validation pending',
              ),
              DemoMetric(
                label: 'Providers',
                value: '5',
                note: 'Across the care network',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Prescription PDF',
                subtitle:
                    'Uploaded by Hyper Pharmacy Melattur after evening medicine issue.',
                meta: 'Prescription',
                status: 'Approved',
              ),
              DemoListItem(
                title: 'CBC report',
                subtitle: 'Digital extraction completed with human validation.',
                meta: 'Lab report',
                status: 'Validated',
              ),
              DemoListItem(
                title: 'Dental X-ray',
                subtitle: 'Image received and classified under dental history.',
                meta: 'Dental record',
                status: 'Processing',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Document timeline updated',
                subtitle:
                    'Each file is now grouped by provider and service date.',
                meta: 'UX state',
                status: 'Visible',
              ),
              DemoListItem(
                title: 'OCR fallback used',
                subtitle:
                    'A scanned image from Makkaraparamba required manual review.',
                meta: 'Engine log',
                status: 'Handled',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most frequent type',
                subtitle:
                    'Prescriptions remain the highest-volume customer document category.',
                meta: 'Usage mix',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Retention note',
                subtitle:
                    'All approved demo files are shown as securely retained in the archive.',
                meta: 'Compliance',
                status: 'Good',
              ),
            ],
          ),
          DemoSectionData(
            key: 'profile',
            title: 'Profile',
            summary:
                'Present a complete member profile with locality, contacts, membership type, and care preferences.',
            actions: const [
              'Edit details',
              'View member ID',
              'Download profile',
            ],
            metrics: const [
              DemoMetric(
                label: 'Membership type',
                value: 'Founding',
                note: 'Legacy RC member',
              ),
              DemoMetric(
                label: 'Primary branch',
                value: 'Perinthalmanna',
                note: 'Most visits',
              ),
              DemoMetric(
                label: 'Emergency contacts',
                value: '2',
                note: 'Stored in profile',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Address verified',
                subtitle:
                    'Perinthalmanna cluster address marked current for service delivery.',
                meta: 'Profile status',
                status: 'Verified',
              ),
              DemoListItem(
                title: 'Contact preference',
                subtitle:
                    'Push + SMS enabled for appointment and wallet alerts.',
                meta: 'Communication',
                status: 'Active',
              ),
              DemoListItem(
                title: 'Consent profile',
                subtitle:
                    'Document sharing allowed across authorized SHIELD facilities.',
                meta: 'Privacy',
                status: 'Enabled',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Membership card viewed',
                subtitle:
                    'Digital privilege card accessed from profile section.',
                meta: '13-20 Jun 2026',
                status: 'Viewed',
              ),
              DemoListItem(
                title: 'Phone verified',
                subtitle:
                    'OTP-based verification remains valid for the current device.',
                meta: 'Security',
                status: 'Current',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Profile completeness',
                subtitle:
                    'This demo profile shows near-complete medical and contact coverage.',
                meta: '94% complete',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Service fit',
                subtitle:
                    'Nearby pharmacy and clinic access make this member a high-engagement user.',
                meta: 'Retention signal',
                status: 'Positive',
              ),
            ],
          ),
          DemoSectionData(
            key: 'membership',
            title: 'Membership',
            summary:
                'Present the active SHIELD membership, digital privilege card, plan benefits, and approval lifecycle from a customer-friendly view.',
            actions: const [
              'Open privilege card',
              'View benefits',
              'Download membership PDF',
            ],
            metrics: const [
              DemoMetric(
                label: 'Membership type',
                value: 'Founding Member',
                note: 'Active in June 2026',
              ),
              DemoMetric(
                label: 'Membership ID',
                value: 'SHLD-2026-123456',
                note: 'QR-linked',
              ),
              DemoMetric(
                label: 'Renewal window',
                value: '15 days',
                note: 'Before 1 Jan 2027',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Digital privilege card ready',
                subtitle:
                    'The customer card with QR token is visible for branch verification and pharmacy use.',
                meta: '20 Jun 2026',
                status: 'Active',
              ),
              DemoListItem(
                title: 'Founding benefits visible',
                subtitle:
                    'Legacy member privileges are shown clearly for Perinthalmanna cluster services.',
                meta: 'Benefit pack',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Renewal reminder queued',
                subtitle:
                    'The next membership reminder is prepared ahead of the next cycle.',
                meta: 'Automation',
                status: 'Scheduled',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Approval trail stored',
                subtitle:
                    'Membership activation reason and timestamp were preserved for support and audit visibility.',
                meta: 'History',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Card viewed from profile',
                subtitle:
                    'The member opened the digital privilege card from the app.',
                meta: 'Member action',
                status: 'Viewed',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Key trust signal',
                subtitle:
                    'The membership page is one of the strongest management-demo screens because it combines identity, entitlement, and verification.',
                meta: 'Demo strength',
                status: 'Major',
              ),
              DemoListItem(
                title: 'Design note',
                subtitle:
                    'The privilege card should stay bold and instantly scannable on both mobile and desktop.',
                meta: 'UX priority',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'prescriptions',
            title: 'Prescriptions',
            summary:
                'Review active, previous, and uploaded prescriptions with linked pharmacy actions, expiry checks, and refill context.',
            actions: const [
              'Upload prescription',
              'Open pharmacy mapping',
              'Share PDF',
            ],
            metrics: const [
              DemoMetric(
                label: 'Active prescriptions',
                value: '3',
                note: 'June 2026 set',
              ),
              DemoMetric(
                label: 'Needs validation',
                value: '1',
                note: 'Handwritten upload',
              ),
              DemoMetric(
                label: 'Refill-ready',
                value: '2',
                note: 'Mapped to pharmacy',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Dr. Haneefa refill note',
                subtitle:
                    'Chronic medication refill is ready for Perinthalmanna Hyper Pharmacy issue.',
                meta: '21 Jun 2026',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Melattur handwritten upload',
                subtitle:
                    'The OCR result is available but still needs pharmacist confirmation.',
                meta: 'Upload review',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Expiry warning',
                subtitle:
                    'One previous prescription is shown as expired to prevent reuse at the counter.',
                meta: 'Safety',
                status: 'Blocked',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Medicine mapping done',
                subtitle:
                    'Primary medicine lines were linked to available pharmacy SKUs for smoother branch processing.',
                meta: 'Data linked',
                status: 'Mapped',
              ),
              DemoListItem(
                title: 'Refill history opened',
                subtitle:
                    'The member can review previous refill dates and branch usage.',
                meta: 'History',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best customer utility',
                subtitle:
                    'Prescription visibility reduces repeated manual explanation at pharmacy counters and strengthens confidence in the digital workflow.',
                meta: 'Care continuity',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Operational caveat',
                subtitle:
                    'Handwritten dosage details still deserve obvious validation states in the UI.',
                meta: 'Clarity',
                status: 'Needed',
              ),
            ],
          ),
          DemoSectionData(
            key: 'recharge',
            title: 'Recharge',
            summary:
                'Simulate wallet recharge requests, promotional credit visibility, and branch-assisted top-up flows in a customer-facing screen.',
            actions: const [
              'Request top-up',
              'View recharge methods',
              'Track request status',
            ],
            metrics: const [
              DemoMetric(
                label: 'Draft request',
                value: '₹2,000',
                note: 'Prepared on 20 Jun 2026',
              ),
              DemoMetric(
                label: 'Promo credits this month',
                value: '₹650',
                note: 'Camp + referral benefits',
              ),
              DemoMetric(
                label: 'Average approval time',
                value: '18 min',
                note: 'Branch-assisted demo',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Manual top-up request',
                subtitle:
                    'A wallet recharge request is ready for SHIELD executive review after branch cash collection.',
                meta: 'Melattur',
                status: 'Draft',
              ),
              DemoListItem(
                title: 'Promotional credit visible',
                subtitle:
                    'Wellness camp bonus and pharmacy loyalty credits are grouped clearly in the recharge view.',
                meta: 'June 2026',
                status: 'Shown',
              ),
              DemoListItem(
                title: 'Recharge instruction card',
                subtitle:
                    'The customer can see the branch-assisted flow before submitting a recharge request.',
                meta: 'Help panel',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Previous top-up settled',
                subtitle:
                    'An earlier Perinthalmanna recharge was completed and moved into ledger history.',
                meta: 'History',
                status: 'Settled',
              ),
              DemoListItem(
                title: 'Notification sent',
                subtitle:
                    'Recharge acknowledgement was delivered to the member immediately after request creation.',
                meta: 'Alert',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Explainer value',
                subtitle:
                    'Recharge pages make the ledger-based wallet feel tangible to non-technical reviewers.',
                meta: 'Management story',
                status: 'Helpful',
              ),
              DemoListItem(
                title: 'Future integration fit',
                subtitle:
                    'The current dummy screen leaves space for online payment methods later without changing the core layout.',
                meta: 'Scalable',
                status: 'Good',
              ),
            ],
          ),
          DemoSectionData(
            key: 'book-appointment',
            title: 'Book Appointment',
            summary:
                'Guide the member through branch, service, doctor, and slot selection for clinic, dental, and home-visit bookings.',
            actions: const ['Choose branch', 'Pick doctor', 'Confirm slot'],
            metrics: const [
              DemoMetric(
                label: 'Suggested slots',
                value: '6',
                note: '21-26 Jun 2026',
              ),
              DemoMetric(
                label: 'Branches',
                value: '4',
                note: 'Clinic + dental + home care',
              ),
              DemoMetric(
                label: 'Fastest branch',
                value: 'Perinthalmanna',
                note: 'Most options available',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'General medicine slot',
                subtitle:
                    'Sunday, June 21, 2026 at 10:00 AM is shown as the fastest available doctor review.',
                meta: 'Manjeri',
                status: 'Suggested',
              ),
              DemoListItem(
                title: 'Dental recall slot',
                subtitle:
                    'Friday, June 26, 2026 afternoon remains open for preventive review.',
                meta: 'Melattur',
                status: 'Open',
              ),
              DemoListItem(
                title: 'Home visit route check',
                subtitle:
                    'Alanallur nurse coverage is shown with route-planning note before final confirmation.',
                meta: 'Home care',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Booking draft retained',
                subtitle:
                    'The member can leave and return without losing the selected branch and service.',
                meta: 'UX state',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Reminder preview shown',
                subtitle:
                    'Push and SMS reminders are previewed before booking confirmation.',
                meta: 'Communication',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Workflow payoff',
                subtitle:
                    'Booking screens help tie membership, service access, and notifications into one clear story for management.',
                meta: 'Cross-module value',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Design principle',
                subtitle:
                    'Booking should always show branch, service, and next reminder in one glanceable summary.',
                meta: 'UX guide',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'settings',
            title: 'Settings',
            summary:
                'Manage profile preferences, alert channels, privacy choices, and app-level display behavior for the customer workspace.',
            actions: const [
              'Edit preferences',
              'Notification channels',
              'Privacy controls',
            ],
            metrics: const [
              DemoMetric(
                label: 'Push alerts',
                value: 'Enabled',
                note: 'Wallet + appointment',
              ),
              DemoMetric(
                label: 'SMS alerts',
                value: 'Enabled',
                note: 'OTP + reminders',
              ),
              DemoMetric(
                label: 'Consent profile',
                value: 'Shared care',
                note: 'Authorized providers only',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Notification preference',
                subtitle:
                    'Appointment and wallet alerts remain enabled for June 2026 activity tracking.',
                meta: 'Alerts',
                status: 'On',
              ),
              DemoListItem(
                title: 'Document sharing consent',
                subtitle:
                    'The member allows approved SHIELD providers to view validated reports and prescriptions.',
                meta: 'Privacy',
                status: 'Enabled',
              ),
              DemoListItem(
                title: 'Language preference',
                subtitle:
                    'English-first demo copy is active with room for Malayalam support later.',
                meta: 'Accessibility',
                status: 'Configured',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'OTP device remembered',
                subtitle:
                    'The current login device remains verified for this demo session.',
                meta: 'Security',
                status: 'Current',
              ),
              DemoListItem(
                title: 'Settings preview saved',
                subtitle:
                    'Preference changes were retained without touching backend integrations.',
                meta: 'Demo mode',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Trust factor',
                subtitle:
                    'A settings page completes the feeling that the customer app is a real product, not only a dashboard mockup.',
                meta: 'Product polish',
                status: 'Important',
              ),
              DemoListItem(
                title: 'Future-proofing',
                subtitle:
                    'These controls can later map directly to notification, privacy, and device APIs without redesigning the screen.',
                meta: 'Scalable',
                status: 'Positive',
              ),
            ],
          ),
          DemoSectionData(
            key: 'notifications',
            title: 'Notifications',
            summary:
                'Track wallet alerts, appointment reminders, report availability, and membership updates from the local cluster.',
            actions: const [
              'Mark all read',
              'Filter alerts',
              'Notification settings',
            ],
            metrics: const [
              DemoMetric(label: 'Unread', value: '4', note: 'Actionable now'),
              DemoMetric(
                label: 'This week',
                value: '17',
                note: 'Across all channels',
              ),
              DemoMetric(
                label: 'Delivery success',
                value: '98%',
                note: 'Push + SMS',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Appointment on 21 Jun 2026',
                subtitle:
                    'Reminder sent for Smart Clinic Manjeri morning consultation.',
                meta: 'Push + SMS',
                status: 'Unread',
              ),
              DemoListItem(
                title: 'Wallet credit posted',
                subtitle: 'Preventive-care bonus added after camp completion.',
                meta: 'Wallet',
                status: 'Unread',
              ),
              DemoListItem(
                title: 'Report available',
                subtitle: 'CBC report is ready to open from the documents tab.',
                meta: 'Lab report',
                status: 'Unread',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Membership renewal notice',
                subtitle:
                    'Founding member benefits were auto-carried into the new cycle.',
                meta: 'Membership',
                status: 'Read',
              ),
              DemoListItem(
                title: 'Document approved',
                subtitle: 'Prescription validation completed successfully.',
                meta: 'Documents',
                status: 'Read',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best channel',
                subtitle:
                    'Push notifications outperform SMS for same-day healthcare actions.',
                meta: 'Engagement trend',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Alert pattern',
                subtitle:
                    'Wallet and appointment events drive the most repeat opens.',
                meta: 'Open behavior',
                status: 'High',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.pharmacyStaff:
      return DemoRoleData(
        role: role,
        operatorName: 'Jaseem K',
        headline:
            'Front-counter pharmacy operations across the hyper pharmacy network',
        regionLabel: 'Perinthalmanna, Melattur, Tirur branches',
        icon: Icons.local_pharmacy,
        accentColor: AppColors.shieldGreen,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Monitor queue load, customer verification traffic, bill uploads, and pharmacy transaction throughput across branch counters.',
            actions: const ['Open counter', 'Verify customer', 'Upload bill'],
            metrics: const [
              DemoMetric(
                label: 'Customers today',
                value: '48',
                note: 'Across 3 counters',
              ),
              DemoMetric(
                label: 'Bills uploaded',
                value: '26',
                note: 'Extraction-ready',
              ),
              DemoMetric(
                label: 'Verification success',
                value: '96%',
                note: 'QR + OTP',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Counter queue building',
                subtitle:
                    'Five SHIELD members are waiting for verification at Counter 2.',
                meta: 'Perinthalmanna',
                status: 'Live',
              ),
              DemoListItem(
                title: 'Prescription image review',
                subtitle:
                    'One scanned prescription needs manual approval before sale.',
                meta: 'Melattur',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Stock-linked discount check',
                subtitle:
                    'Wallet discount calculation needs override for one senior member.',
                meta: 'Tirur',
                status: 'Attention',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Successful bill extraction',
                subtitle:
                    'Medicine line items parsed and matched to product masters.',
                meta: 'Hyper Pharmacy',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Wallet deduction posted',
                subtitle:
                    'Member purchase was settled directly from SHIELD balance.',
                meta: 'Counter 4',
                status: 'Settled',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Peak hour',
                subtitle:
                    '11 AM to 1 PM remains the heaviest verification window.',
                meta: 'Ops trend',
                status: 'Peak',
              ),
              DemoListItem(
                title: 'Most active branch',
                subtitle:
                    'Perinthalmanna is handling the largest SHIELD member volume today.',
                meta: 'Branch ranking',
                status: 'Top',
              ),
            ],
          ),
          DemoSectionData(
            key: 'customers',
            title: 'Customer Search',
            summary:
                'Search members by mobile, QR, or membership number before processing pharmacy transactions.',
            actions: const ['QR lookup', 'Search by mobile', 'Open profile'],
            metrics: const [
              DemoMetric(
                label: 'Searches today',
                value: '61',
                note: 'Fast member lookup',
              ),
              DemoMetric(
                label: 'New walk-ins',
                value: '9',
                note: 'Potential conversions',
              ),
              DemoMetric(
                label: 'Repeat members',
                value: '37',
                note: 'Known profiles',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Founding member profile with active wallet and two pending prescriptions.',
                meta: 'Perinthalmanna',
                status: 'Active',
              ),
              DemoListItem(
                title: 'Fathima Sherin',
                subtitle:
                    'Member prefers Melattur branch and has one approval pending.',
                meta: 'Melattur',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Shanib K',
                subtitle:
                    'Profile exists but membership activation is not complete yet.',
                meta: 'Manjeri',
                status: 'Hold',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Search latency stable',
                subtitle:
                    'All demo customer lookups are rendering under the expected UI budget.',
                meta: 'UX check',
                status: 'Good',
              ),
              DemoListItem(
                title: 'QR fallback used',
                subtitle: 'Manual mobile search handled a damaged card scan.',
                meta: 'Counter 1',
                status: 'Handled',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best identifier',
                subtitle:
                    'Mobile lookup is still the fastest working flow for front-counter staff.',
                meta: 'Workflow',
                status: 'Preferred',
              ),
              DemoListItem(
                title: 'Missed opportunity',
                subtitle:
                    'Pending members should be routed to SHIELD executive follow-up from this page.',
                meta: 'Conversion',
                status: 'Flagged',
              ),
            ],
          ),
          DemoSectionData(
            key: 'verification',
            title: 'Verification',
            summary:
                'Handle QR scans, OTP verification, membership checks, and counter-level eligibility confirmation.',
            actions: const ['Scan QR', 'Send OTP', 'Escalate issue'],
            metrics: const [
              DemoMetric(label: 'QR scans', value: '22', note: 'Today'),
              DemoMetric(
                label: 'OTP requests',
                value: '18',
                note: 'Phone fallback',
              ),
              DemoMetric(
                label: 'Failed verifications',
                value: '2',
                note: 'Manual check needed',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'QR mismatch',
                subtitle: 'Card token mismatch needs customer identity review.',
                meta: 'Counter 3',
                status: 'Escalated',
              ),
              DemoListItem(
                title: 'OTP delivered',
                subtitle:
                    'Verification code sent successfully to a founding member.',
                meta: 'Melattur',
                status: 'Waiting',
              ),
              DemoListItem(
                title: 'Membership cross-check',
                subtitle: 'One inactive membership was flagged before billing.',
                meta: 'Tirur',
                status: 'Protected',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Identity confirmed',
                subtitle:
                    'Photo-free OTP verification completed without delay.',
                meta: 'Perinthalmanna',
                status: 'Passed',
              ),
              DemoListItem(
                title: 'Counter note saved',
                subtitle:
                    'Staff note attached for a repeat verification exception.',
                meta: 'Audit trail',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Verification quality',
                subtitle:
                    'OTP fallback is reliable, but QR adoption is growing fastest in repeat members.',
                meta: 'Adoption trend',
                status: 'Up',
              ),
              DemoListItem(
                title: 'Risk note',
                subtitle:
                    'Manual review flows should stay visible when wallet-linked discounts are applied.',
                meta: 'Control',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'bills',
            title: 'Bill Uploads',
            summary:
                'Manage pharmacy bill intake, extraction review, item validation, and invoice finalization using dummy records.',
            actions: const ['Upload PDF', 'Review extraction', 'Post purchase'],
            metrics: const [
              DemoMetric(
                label: 'Uploads pending',
                value: '6',
                note: 'Awaiting review',
              ),
              DemoMetric(label: 'Auto-classified', value: '19', note: 'Today'),
              DemoMetric(
                label: 'Line items parsed',
                value: '148',
                note: 'Demo dataset',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Invoice PMNA-447',
                subtitle:
                    'Medicine list extracted from PDF and discount matched to member plan.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Invoice MTR-118',
                subtitle:
                    'One product code needs manual correction before posting.',
                meta: 'Melattur',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Invoice TRR-067',
                subtitle:
                    'Scanned file required OCR fallback for accurate totals.',
                meta: 'Tirur',
                status: 'Validated',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Original file retained',
                subtitle:
                    'Archive copy stored alongside extracted data for audit completeness.',
                meta: 'Compliance',
                status: 'Stored',
              ),
              DemoListItem(
                title: 'Posting completed',
                subtitle:
                    'Bill moved into purchase history with wallet settlement details.',
                meta: 'Sales flow',
                status: 'Done',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'File quality',
                subtitle:
                    'Digital PDFs continue to outperform scanned images for speed and accuracy.',
                meta: 'Extraction signal',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Operator note',
                subtitle:
                    'Bills with combo packs need clearer UI grouping in a later integration phase.',
                meta: 'UX note',
                status: 'Noted',
              ),
            ],
          ),
          DemoSectionData(
            key: 'prescriptions',
            title: 'Prescription Intake',
            summary:
                'Capture, classify, and validate doctor-issued prescriptions before the pharmacy team posts medicines against them.',
            actions: const [
              'Upload prescription',
              'Classify file',
              'Link medicines',
            ],
            metrics: const [
              DemoMetric(
                label: 'Active prescriptions',
                value: '14',
                note: 'Today',
              ),
              DemoMetric(
                label: 'Needs review',
                value: '3',
                note: 'Low-confidence files',
              ),
              DemoMetric(
                label: 'Linked sales',
                value: '11',
                note: 'Matched to bills',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Dr. Haneefa prescription',
                subtitle:
                    'Valid for chronic medication refill with one substitute note.',
                meta: 'Manjeri',
                status: 'Approved',
              ),
              DemoListItem(
                title: 'Scanned handwritten note',
                subtitle:
                    'OCR result requires pharmacist validation before issue.',
                meta: 'Alanallur',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Repeat refill check',
                subtitle:
                    'Previous prescription linked to current wallet deduction flow.',
                meta: 'Perinthalmanna',
                status: 'Mapped',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Drug mapping completed',
                subtitle: 'Primary medicines linked to available product SKUs.',
                meta: 'Inventory tie-in',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Expiry enforced',
                subtitle:
                    'One outdated prescription was blocked from processing.',
                meta: 'Control',
                status: 'Blocked',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most common issue',
                subtitle:
                    'Handwritten dosage lines remain the main source of manual review.',
                meta: 'Quality insight',
                status: 'Common',
              ),
              DemoListItem(
                title: 'Speed gain',
                subtitle:
                    'Digital prescriptions from Manjeri clinic move through the cleanest workflow.',
                meta: 'Best path',
                status: 'Fast',
              ),
            ],
          ),
          DemoSectionData(
            key: 'qr-scan',
            title: 'QR Scan',
            summary:
                'Handle member lookup through QR scan, membership number fallback, and counter-level verification for pharmacy workflows.',
            actions: const [
              'Open scanner',
              'Enter member ID',
              'View token log',
            ],
            metrics: const [
              DemoMetric(
                label: 'Scans today',
                value: '22',
                note: '20 Jun 2026',
              ),
              DemoMetric(
                label: 'Fallback lookups',
                value: '6',
                note: 'Membership number',
              ),
              DemoMetric(
                label: 'Success rate',
                value: '95%',
                note: 'Counter average',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Card scan ready',
                subtitle:
                    'Camera scan flow is presented with a clean overlay for member verification.',
                meta: 'Counter 2',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Membership ID fallback',
                subtitle:
                    'A damaged QR card can still be verified through manual membership number entry.',
                meta: 'Fallback',
                status: 'Available',
              ),
              DemoListItem(
                title: 'Verification proof panel',
                subtitle:
                    'The staff can view branch, wallet eligibility, and membership status side by side after a scan.',
                meta: 'Review',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Duplicate retry handled',
                subtitle:
                    'One repeat scan was merged into a single counter event for audit clarity.',
                meta: 'Scanner log',
                status: 'Cleaned',
              ),
              DemoListItem(
                title: 'Manual entry completed',
                subtitle:
                    'A Melattur member was verified using membership number after a blurred QR read.',
                meta: 'Melattur',
                status: 'Verified',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Doc alignment',
                subtitle:
                    'An explicit QR page closes one of the clearest UI-spec gaps for the pharmacy role.',
                meta: 'Spec coverage',
                status: 'Closed',
              ),
              DemoListItem(
                title: 'UX rule',
                subtitle:
                    'Manual membership-number entry should always stay on the same screen as camera scan fallback.',
                meta: 'Design note',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'history',
            title: 'Branch History',
            summary:
                'Review shift activity, transaction patterns, document handling, and member interactions by branch and counter.',
            actions: const [
              'Export shift log',
              'Filter branch',
              'Counter comparison',
            ],
            metrics: const [
              DemoMetric(
                label: 'Shift transactions',
                value: '84',
                note: 'Current day',
              ),
              DemoMetric(
                label: 'Average bill',
                value: '₹842',
                note: 'Member transactions',
              ),
              DemoMetric(
                label: 'Manual interventions',
                value: '7',
                note: 'Review cases',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Counter 2 performance',
                subtitle:
                    'High throughput with clean document completion ratio.',
                meta: 'Perinthalmanna',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Evening rush review',
                subtitle:
                    'Melattur branch saw the highest post-6 PM member inflow.',
                meta: 'Shift note',
                status: 'Observed',
              ),
              DemoListItem(
                title: 'Tirur exception log',
                subtitle:
                    'Two verification delays recorded for network retry follow-up.',
                meta: 'Ops issue',
                status: 'Tracked',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Operator summary saved',
                subtitle: 'Daily wrap-up exported for management review.',
                meta: 'End of day',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Promo usage spike',
                subtitle:
                    'Preventive-care voucher redemptions increased in the last week.',
                meta: 'Campaign impact',
                status: 'Up',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best repeat conversion',
                subtitle:
                    'Perinthalmanna branch leads in return visits within 30 days.',
                meta: 'Retention insight',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Operational gap',
                subtitle:
                    'Manual document review volume is concentrated in scanned uploads.',
                meta: 'Process bottleneck',
                status: 'Visible',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.clinicStaff:
      return DemoRoleData(
        role: role,
        operatorName: 'Dr. Faseela',
        headline:
            'Clinic-side patient coordination, consultations, and reports in one care console',
        regionLabel: 'Manjeri and Perinthalmanna smart clinic network',
        icon: Icons.local_hospital,
        accentColor: AppColors.info,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Track today’s patient load, consultations, reports, and clinic task flow across SHIELD-connected smart clinics.',
            actions: const [
              'Open queue',
              'Start consultation',
              'Upload report',
            ],
            metrics: const [
              DemoMetric(
                label: 'Patients today',
                value: '32',
                note: 'Booked + walk-in',
              ),
              DemoMetric(
                label: 'Consultations done',
                value: '18',
                note: 'Morning shift',
              ),
              DemoMetric(
                label: 'Reports pending',
                value: '6',
                note: 'Awaiting upload',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Morning OP queue',
                subtitle:
                    'Seven SHIELD members are waiting for general medicine review.',
                meta: 'Manjeri',
                status: 'Live',
              ),
              DemoListItem(
                title: 'Report upload backlog',
                subtitle:
                    'Three lab files still need validation before member release.',
                meta: 'Perinthalmanna',
                status: 'Attention',
              ),
              DemoListItem(
                title: 'Home visit request',
                subtitle: 'Care coordinator asked for same-day triage review.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Consultation completed',
                subtitle: 'Diagnosis and care note posted to patient timeline.',
                meta: 'Dr. Haneefa P',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Document shared',
                subtitle:
                    'PDF report pushed to member documents after doctor approval.',
                meta: 'Clinic flow',
                status: 'Shared',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Peak load',
                subtitle:
                    'Mid-morning remains the busiest period for SHIELD patient arrivals.',
                meta: 'Clinic trend',
                status: 'Peak',
              ),
              DemoListItem(
                title: 'Fastest workflow',
                subtitle:
                    'Digital report uploads from Perinthalmanna clear faster than scanned ones.',
                meta: 'Quality signal',
                status: 'Better',
              ),
            ],
          ),
          DemoSectionData(
            key: 'patients',
            title: 'Patient Records',
            summary:
                'Access member histories, visit reasons, medication context, and recent documents before clinical review.',
            actions: const ['Search patient', 'Open timeline', 'Add note'],
            metrics: const [
              DemoMetric(
                label: 'Active follow-ups',
                value: '14',
                note: 'This week',
              ),
              DemoMetric(
                label: 'New patients',
                value: '5',
                note: 'Needing onboarding',
              ),
              DemoMetric(
                label: 'History complete',
                value: '89%',
                note: 'Records linked',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Chronic medication follow-up with pharmacy and lab history linked.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Fathima Sherin',
                subtitle:
                    'Recurrent headache review with one recent CBC report attached.',
                meta: 'Melattur',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Shanib K',
                subtitle:
                    'Pending membership activation but clinically visible for triage notes.',
                meta: 'Manjeri',
                status: 'Limited',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Timeline merged',
                subtitle:
                    'Previous pharmacy purchases now visible beside consultation history.',
                meta: 'Data view',
                status: 'Linked',
              ),
              DemoListItem(
                title: 'Clinical note saved',
                subtitle: 'Staff note added ahead of the doctor review.',
                meta: 'Preparation',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most useful context',
                subtitle:
                    'Recent prescriptions and wallet-assisted pharmacy history help speed reviews.',
                meta: 'Clinical workflow',
                status: 'Helpful',
              ),
              DemoListItem(
                title: 'Gap to fill',
                subtitle:
                    'Home visit outcomes should surface more prominently in future detail views.',
                meta: 'UX gap',
                status: 'Noted',
              ),
            ],
          ),
          DemoSectionData(
            key: 'appointments',
            title: 'Appointments',
            summary:
                'Manage clinic slots, doctor schedules, follow-up bookings, and no-show recovery from a single scheduling view.',
            actions: const ['Create slot', 'Confirm visit', 'Mark no-show'],
            metrics: const [
              DemoMetric(label: 'Today’s slots', value: '27', note: 'Booked'),
              DemoMetric(
                label: 'Follow-ups due',
                value: '8',
                note: 'This week',
              ),
              DemoMetric(
                label: 'No-show risk',
                value: '3',
                note: 'Need reminder',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'General medicine queue',
                subtitle: 'Back-to-back consultations lined up through noon.',
                meta: 'Manjeri',
                status: 'On time',
              ),
              DemoListItem(
                title: 'Diabetes follow-up',
                subtitle:
                    'Member requested shift from Tirur to Perinthalmanna branch.',
                meta: 'Reschedule',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Home care assessment',
                subtitle:
                    'Travel route validation needed before slot confirmation.',
                meta: 'Alanallur',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Reminder sent',
                subtitle:
                    'Push and SMS were triggered for June 21\'s first three visits.',
                meta: 'Automation',
                status: 'Sent',
              ),
              DemoListItem(
                title: 'Consultation closed',
                subtitle: 'Completed appointment moved into patient history.',
                meta: 'Workflow',
                status: 'Done',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most punctual branch',
                subtitle:
                    'Perinthalmanna has the strongest same-day attendance pattern.',
                meta: 'Ops metric',
                status: 'Best',
              ),
              DemoListItem(
                title: 'Reminder impact',
                subtitle:
                    'The second reminder one hour before visit appears to reduce no-shows.',
                meta: 'Engagement',
                status: 'Useful',
              ),
            ],
          ),
          DemoSectionData(
            key: 'consultations',
            title: 'Consultations',
            summary:
                'Capture diagnosis, doctor notes, treatment guidance, and linked prescriptions using a doctor-friendly demo page.',
            actions: const [
              'Start note',
              'Save diagnosis',
              'Issue prescription',
            ],
            metrics: const [
              DemoMetric(
                label: 'Consult notes today',
                value: '18',
                note: 'Saved',
              ),
              DemoMetric(
                label: 'Prescriptions issued',
                value: '11',
                note: 'Same-day',
              ),
              DemoMetric(
                label: 'Escalated cases',
                value: '2',
                note: 'Need specialist',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Chronic care review',
                subtitle:
                    'Blood pressure and sugar follow-up with medicine refill advice.',
                meta: 'Perinthalmanna',
                status: 'In progress',
              ),
              DemoListItem(
                title: 'Acute fever case',
                subtitle:
                    'Short consultation note awaiting final diagnosis entry.',
                meta: 'Manjeri',
                status: 'Draft',
              ),
              DemoListItem(
                title: 'Referral note',
                subtitle:
                    'Patient flagged for advanced imaging outside the current clinic scope.',
                meta: 'Escalation',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Prescription linked',
                subtitle:
                    'Issued medicine list is visible to pharmacy-side staff immediately.',
                meta: 'Integrated demo',
                status: 'Linked',
              ),
              DemoListItem(
                title: 'Doctor note approved',
                subtitle: 'Clinical summary published to member timeline.',
                meta: 'Patient view',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Note quality',
                subtitle:
                    'Structured diagnosis fields make the follow-up workflow cleaner for staff.',
                meta: 'Usability',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Future improvement',
                subtitle:
                    'Template-based care plans would speed repeated chronic care consultations.',
                meta: 'Enhancement',
                status: 'Candidate',
              ),
            ],
          ),
          DemoSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Upload and validate lab or consultation reports before releasing them to the patient document timeline.',
            actions: const ['Upload PDF', 'Review OCR', 'Approve release'],
            metrics: const [
              DemoMetric(
                label: 'Reports today',
                value: '13',
                note: 'Queued or released',
              ),
              DemoMetric(
                label: 'OCR fallback',
                value: '3',
                note: 'Scanned uploads',
              ),
              DemoMetric(
                label: 'Released to members',
                value: '9',
                note: 'Approved',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'CBC report upload',
                subtitle:
                    'Digital PDF extracted cleanly with confidence above threshold.',
                meta: 'Tirur',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Scanned consultation summary',
                subtitle:
                    'Needs manual field confirmation before archive release.',
                meta: 'Manjeri',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Home visit report',
                subtitle:
                    'Nurse notes converted to a member-readable PDF bundle.',
                meta: 'Alanallur',
                status: 'Prepared',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Member notified',
                subtitle:
                    'Push alert sent after doctor approval of lab results.',
                meta: 'Notification',
                status: 'Sent',
              ),
              DemoListItem(
                title: 'Processing log saved',
                subtitle:
                    'Stage-wise document trail captured for audit visibility.',
                meta: 'Audit',
                status: 'Stored',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Turnaround leader',
                subtitle:
                    'Structured digital lab reports clear fastest for member release.',
                meta: 'Speed insight',
                status: 'Fast',
              ),
              DemoListItem(
                title: 'Validation hotspot',
                subtitle:
                    'Scanned consultation summaries remain the most error-prone report type.',
                meta: 'Quality insight',
                status: 'Attention',
              ),
            ],
          ),
          DemoSectionData(
            key: 'home-visits',
            title: 'Home Visits',
            summary:
                'Schedule, assign, and document home-visit care for members who need clinical services near home.',
            actions: const ['Create visit', 'Assign staff', 'Close visit'],
            metrics: const [
              DemoMetric(label: 'Requested', value: '4', note: 'This week'),
              DemoMetric(label: 'Assigned', value: '3', note: 'Route planned'),
              DemoMetric(label: 'Completed', value: '9', note: 'Month to date'),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Alanallur BP follow-up',
                subtitle:
                    'Nurse assignment pending due to route bundling with another case.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Makkaraparamba post-discharge review',
                subtitle:
                    'Doctor wants an at-home check after recent clinic visit.',
                meta: 'Makkaraparamba',
                status: 'Assigned',
              ),
              DemoListItem(
                title: 'Tirur elder care visit',
                subtitle:
                    'Medication adherence check scheduled with caregiver present.',
                meta: 'Tirur',
                status: 'Confirmed',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Visit note uploaded',
                subtitle:
                    'Home visit outcome pushed to patient timeline and care history.',
                meta: 'Field team',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Travel bundle optimized',
                subtitle: 'Two nearby visits grouped into one route plan.',
                meta: 'Ops support',
                status: 'Optimized',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'High-value service',
                subtitle:
                    'Home visits appear to reduce missed follow-ups in rural pockets.',
                meta: 'Retention effect',
                status: 'Positive',
              ),
              DemoListItem(
                title: 'Coordination need',
                subtitle:
                    'Route planning should eventually link directly with appointment management.',
                meta: 'Workflow gap',
                status: 'Future',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.dentalStaff:
      return DemoRoleData(
        role: role,
        operatorName: 'Dr. Asna Basheer',
        headline:
            'Dental workflow for appointments, procedures, reports, and treatment continuity',
        regionLabel: 'Melattur and Perinthalmanna dental care desks',
        icon: Icons.medical_services,
        accentColor: AppColors.warning,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Review chair utilization, treatment queue, pending reports, and repeat dental follow-ups from one view.',
            actions: const ['Open chair queue', 'Add treatment', 'Upload scan'],
            metrics: const [
              DemoMetric(
                label: 'Patients today',
                value: '19',
                note: 'Scheduled + urgent',
              ),
              DemoMetric(
                label: 'Procedures done',
                value: '11',
                note: 'Current shift',
              ),
              DemoMetric(
                label: 'Follow-ups due',
                value: '5',
                note: 'Within 7 days',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Scaling follow-up queue',
                subtitle:
                    'Three members waiting with prior digital history attached.',
                meta: 'Melattur',
                status: 'Live',
              ),
              DemoListItem(
                title: 'X-ray review pending',
                subtitle:
                    'Uploaded image needs dentist sign-off before member release.',
                meta: 'Perinthalmanna',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Crown treatment plan',
                subtitle:
                    'Cost and stage plan to be explained after consultation.',
                meta: 'Manjeri referral',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Treatment note saved',
                subtitle:
                    'Procedure detail posted to the member’s dental history.',
                meta: 'Chair 2',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Recall reminder queued',
                subtitle:
                    'Routine check reminder prepared for three-month outreach.',
                meta: 'CRM bridge',
                status: 'Queued',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Chair efficiency',
                subtitle:
                    'Morning slots are performing with the highest on-time start rate.',
                meta: 'Ops insight',
                status: 'Good',
              ),
              DemoListItem(
                title: 'Return pattern',
                subtitle:
                    'Members from Perinthalmanna show the strongest repeat preventive visits.',
                meta: 'Retention signal',
                status: 'High',
              ),
            ],
          ),
          DemoSectionData(
            key: 'patients',
            title: 'Patient Records',
            summary:
                'Open member dental history, imaging, procedure notes, and pending treatment plans before chair-side work.',
            actions: const [
              'Find patient',
              'Open dental history',
              'Attach image',
            ],
            metrics: const [
              DemoMetric(
                label: 'Open cases',
                value: '23',
                note: 'Tracked plans',
              ),
              DemoMetric(label: 'Image sets', value: '17', note: 'Accessible'),
              DemoMetric(
                label: 'Treatment plans',
                value: '8',
                note: 'In progress',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Fathima Sherin',
                subtitle:
                    'Scaling complete, review due with photos and notes attached.',
                meta: 'Melattur',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Tooth sensitivity follow-up with medicine history available.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Shanib K',
                subtitle:
                    'Pending membership but emergency dental note allowed for triage.',
                meta: 'Manjeri',
                status: 'Limited',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'X-ray linked',
                subtitle:
                    'Imaging now sits beside treatment notes for easier review.',
                meta: 'Dental record',
                status: 'Linked',
              ),
              DemoListItem(
                title: 'Plan updated',
                subtitle:
                    'Two-stage treatment estimate revised after clinical review.',
                meta: 'Case note',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'History usefulness',
                subtitle:
                    'Procedure photos improve continuity more than plain text notes alone.',
                meta: 'Clinical UX',
                status: 'Helpful',
              ),
              DemoListItem(
                title: 'Data gap',
                subtitle:
                    'Billing-ready dental package summaries would strengthen management demo depth.',
                meta: 'Opportunity',
                status: 'Future',
              ),
            ],
          ),
          DemoSectionData(
            key: 'appointments',
            title: 'Appointments',
            summary:
                'Coordinate chair schedules, procedure durations, review slots, and repeat care reminders for dental patients.',
            actions: const ['Add slot', 'Reschedule chair', 'Confirm review'],
            metrics: const [
              DemoMetric(label: 'Chair bookings', value: '16', note: 'Today'),
              DemoMetric(label: 'Delayed starts', value: '1', note: 'Minor'),
              DemoMetric(
                label: 'Recall bookings',
                value: '6',
                note: 'This week',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Scaling review',
                subtitle: 'Short slot blocked for afternoon follow-up.',
                meta: 'Melattur',
                status: 'Confirmed',
              ),
              DemoListItem(
                title: 'Filling consultation',
                subtitle: 'Patient requested a later chair after work hours.',
                meta: 'Perinthalmanna',
                status: 'Reschedule',
              ),
              DemoListItem(
                title: 'Treatment plan discussion',
                subtitle:
                    'Case review appointment reserved for family counseling.',
                meta: 'Manjeri',
                status: 'Booked',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Chair schedule synced',
                subtitle:
                    'Reception and dentist views now reflect the same sequence.',
                meta: 'Desk flow',
                status: 'Aligned',
              ),
              DemoListItem(
                title: 'Reminder sent',
                subtitle:
                    'Upcoming review patients received push notifications.',
                meta: 'Notification',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best slot length',
                subtitle:
                    'Twenty-minute reviews create the cleanest utilization pattern.',
                meta: 'Scheduling insight',
                status: 'Optimal',
              ),
              DemoListItem(
                title: 'No-show reduction',
                subtitle:
                    'Recall reminders are helping members return for preventive checkups.',
                meta: 'Care continuity',
                status: 'Working',
              ),
            ],
          ),
          DemoSectionData(
            key: 'treatments',
            title: 'Treatments',
            summary:
                'Record procedures, materials, dentist notes, and chair-side outcomes with a clean treatment workflow.',
            actions: const ['Create procedure', 'Save notes', 'Link report'],
            metrics: const [
              DemoMetric(
                label: 'Procedures today',
                value: '11',
                note: 'Captured',
              ),
              DemoMetric(label: 'Treatment plans', value: '8', note: 'Active'),
              DemoMetric(
                label: 'Urgent cases',
                value: '2',
                note: 'Same-day care',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Scaling and polishing',
                subtitle:
                    'Completed with instructions posted to after-care notes.',
                meta: 'Melattur',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Filling recommendation',
                subtitle:
                    'Procedure suggested after cavity review; plan awaiting acceptance.',
                meta: 'Perinthalmanna',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Sensitivity case',
                subtitle:
                    'Observation note saved with medicine and revisit advice.',
                meta: 'Alanallur',
                status: 'Tracked',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Treatment stage updated',
                subtitle: 'Case advanced from diagnosis to approved plan.',
                meta: 'Case flow',
                status: 'Updated',
              ),
              DemoListItem(
                title: 'Post-care note shared',
                subtitle:
                    'Member can review home-care advice from the documents section.',
                meta: 'Patient handoff',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Procedure mix',
                subtitle:
                    'Preventive visits are still the biggest volume driver in the demo.',
                meta: 'Case mix',
                status: 'Majority',
              ),
              DemoListItem(
                title: 'Future add-on',
                subtitle:
                    'A chair-material usage panel would enrich the operational story later.',
                meta: 'Enhancement',
                status: 'Idea',
              ),
            ],
          ),
          DemoSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Handle dental images, scan uploads, procedure PDFs, and release-ready records for member history.',
            actions: const ['Upload image', 'Approve record', 'Archive report'],
            metrics: const [
              DemoMetric(label: 'Files uploaded', value: '9', note: 'Today'),
              DemoMetric(
                label: 'Images processing',
                value: '2',
                note: 'Classification running',
              ),
              DemoMetric(label: 'Released', value: '6', note: 'Member-visible'),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Dental X-ray image',
                subtitle:
                    'Classified and mapped to treatment history after upload.',
                meta: 'Perinthalmanna',
                status: 'Validated',
              ),
              DemoListItem(
                title: 'Procedure summary PDF',
                subtitle: 'Ready to release after dentist note review.',
                meta: 'Melattur',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Scanned estimate sheet',
                subtitle: 'OCR confidence low, manual check requested.',
                meta: 'Manjeri',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Archive copy retained',
                subtitle:
                    'Original file kept alongside structured extraction data.',
                meta: 'Compliance',
                status: 'Stored',
              ),
              DemoListItem(
                title: 'Member alert queued',
                subtitle:
                    'Notification prepared for approved dental image release.',
                meta: 'Comms',
                status: 'Queued',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Image quality signal',
                subtitle:
                    'Direct digital uploads from the chairside device perform best.',
                meta: 'Workflow insight',
                status: 'Best',
              ),
              DemoListItem(
                title: 'Friction point',
                subtitle:
                    'Paper estimates need a cleaner upload path in the next phase.',
                meta: 'Process gap',
                status: 'Visible',
              ),
            ],
          ),
          DemoSectionData(
            key: 'history',
            title: 'Treatment History',
            summary:
                'Summarize revisit frequency, treatment continuity, completed procedures, and preventive-care patterns.',
            actions: const [
              'Filter timeline',
              'Export history',
              'Open patient file',
            ],
            metrics: const [
              DemoMetric(
                label: 'Completed plans',
                value: '21',
                note: 'Quarter to date',
              ),
              DemoMetric(
                label: 'Repeat preventive visits',
                value: '12',
                note: 'High retention',
              ),
              DemoMetric(
                label: 'Pending reviews',
                value: '4',
                note: 'Next 10 days',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Three-month recall cohort',
                subtitle:
                    'Members due for preventive review are lined up for outreach.',
                meta: 'CRM feed',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Completed treatment summary',
                subtitle:
                    'A full case timeline is visible for management demo review.',
                meta: 'Perinthalmanna',
                status: 'Compiled',
              ),
              DemoListItem(
                title: 'Open continuity gap',
                subtitle:
                    'One referred patient has not returned after first consultation.',
                meta: 'Melattur',
                status: 'Follow-up',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'History export generated',
                subtitle:
                    'Demo treatment history rendered as a shareable PDF summary.',
                meta: 'Export',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Retention insight updated',
                subtitle:
                    'Preventive-care revisits continue to improve in the active cluster.',
                meta: 'Trend',
                status: 'Positive',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most loyal location',
                subtitle:
                    'Perinthalmanna members show the best preventive revisit cadence.',
                meta: 'Retention leader',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Operational takeaway',
                subtitle:
                    'Dental history is clearer when chair notes and images stay on the same page.',
                meta: 'UX lesson',
                status: 'Important',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.crmExecutive:
      return DemoRoleData(
        role: role,
        operatorName: 'Safna M',
        headline:
            'Relationship management for follow-ups, complaints, tasks, and member retention',
        regionLabel: 'Malappuram SHIELD customer engagement desk',
        icon: Icons.support_agent,
        accentColor: AppColors.shieldNavy,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Watch open tasks, follow-up load, complaint status, and campaign performance across the active member base.',
            actions: const ['Create task', 'Open complaint', 'Start outreach'],
            metrics: const [
              DemoMetric(label: 'Tasks today', value: '28', note: 'Assigned'),
              DemoMetric(
                label: 'Open complaints',
                value: '7',
                note: 'Need action',
              ),
              DemoMetric(
                label: 'Follow-ups due',
                value: '12',
                note: 'Same day',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Missed appointment recovery',
                subtitle:
                    'Three members need same-day outreach after skipped visits.',
                meta: 'Manjeri',
                status: 'Urgent',
              ),
              DemoListItem(
                title: 'Wallet confusion complaint',
                subtitle:
                    'Customer asked for a clearer explanation of pharmacy deductions.',
                meta: 'Perinthalmanna',
                status: 'Open',
              ),
              DemoListItem(
                title: 'Wellness camp invitation list',
                subtitle:
                    'Campaign segment is ready for Alanallur and Melattur outreach.',
                meta: 'Campaign',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Follow-up closed',
                subtitle: 'Member confirmed next consultation after call-back.',
                meta: 'CRM action',
                status: 'Closed',
              ),
              DemoListItem(
                title: 'Complaint escalated',
                subtitle:
                    'One reversal request was sent to SHIELD executive queue.',
                meta: 'Cross-team',
                status: 'Escalated',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'High-value cohort',
                subtitle:
                    'Members with recent pharmacy use and pending visits are most responsive.',
                meta: 'Segment insight',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Complaint pattern',
                subtitle:
                    'Most issues come from delayed explanations, not failed service delivery.',
                meta: 'Root cause',
                status: 'Useful',
              ),
            ],
          ),
          DemoSectionData(
            key: 'customers',
            title: 'Customer List',
            summary:
                'Browse engagement-ready customer profiles with service recency, locality, and follow-up need indicators.',
            actions: const ['Search member', 'Open timeline', 'Tag segment'],
            metrics: const [
              DemoMetric(
                label: 'Active members',
                value: '412',
                note: 'Demo dataset',
              ),
              DemoMetric(
                label: 'At-risk members',
                value: '36',
                note: 'Low activity',
              ),
              DemoMetric(
                label: 'High-engagement',
                value: '84',
                note: 'Frequent users',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Active pharmacy and clinic usage; candidate for preventive plan upsell.',
                meta: 'Perinthalmanna',
                status: 'Warm',
              ),
              DemoListItem(
                title: 'Fathima Sherin',
                subtitle: 'Recent dental follow-up and high document usage.',
                meta: 'Melattur',
                status: 'Engaged',
              ),
              DemoListItem(
                title: 'Shanib K',
                subtitle:
                    'Pending membership completion and needs activation follow-up.',
                meta: 'Manjeri',
                status: 'Needs care',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Segment updated',
                subtitle:
                    'Members grouped by branch engagement and care frequency.',
                meta: 'CRM data',
                status: 'Updated',
              ),
              DemoListItem(
                title: 'Customer note added',
                subtitle: 'Preferred contact time saved for next outreach.',
                meta: 'Profile note',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most responsive town',
                subtitle:
                    'Tirur members respond fastest to appointment reminder follow-ups.',
                meta: 'Engagement trend',
                status: 'Best',
              ),
              DemoListItem(
                title: 'Conversion opportunity',
                subtitle:
                    'Pending members near Perinthalmanna can likely be activated quickly.',
                meta: 'Growth angle',
                status: 'Strong',
              ),
            ],
          ),
          DemoSectionData(
            key: 'tasks',
            title: 'Tasks',
            summary:
                'Assign and track CRM work items such as call-backs, campaign outreach, issue resolution, and retention nudges.',
            actions: const ['New task', 'Reassign', 'Close task'],
            metrics: const [
              DemoMetric(label: 'Open tasks', value: '28', note: 'Today'),
              DemoMetric(label: 'Due now', value: '9', note: 'Actionable'),
              DemoMetric(label: 'Completed', value: '17', note: 'This week'),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Call no-show patient',
                subtitle:
                    'Check whether the member wants a rescheduled clinic slot.',
                meta: 'Manjeri',
                status: 'Due',
              ),
              DemoListItem(
                title: 'Explain wallet deduction',
                subtitle:
                    'Resolve confusion on recent pharmacy transaction breakdown.',
                meta: 'Perinthalmanna',
                status: 'Due',
              ),
              DemoListItem(
                title: 'Promote wellness camp',
                subtitle:
                    'Invite inactive members from Alanallur and Makkaraparamba.',
                meta: 'Campaign',
                status: 'Queued',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Task closed',
                subtitle:
                    'Member confirmed document access after guided support.',
                meta: 'Support flow',
                status: 'Closed',
              ),
              DemoListItem(
                title: 'Owner changed',
                subtitle: 'Escalated issue moved to a senior CRM executive.',
                meta: 'Workflow',
                status: 'Reassigned',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best task type',
                subtitle:
                    'Follow-up reminder calls are closing faster than broad campaign work.',
                meta: 'Ops insight',
                status: 'Fast',
              ),
              DemoListItem(
                title: 'Suggested improvement',
                subtitle:
                    'Task cards should eventually display wallet and appointment context together.',
                meta: 'Product note',
                status: 'Future',
              ),
            ],
          ),
          DemoSectionData(
            key: 'follow-ups',
            title: 'Follow-Ups',
            summary:
                'Manage member callbacks, revisit nudges, unresolved care journeys, and post-visit check-ins.',
            actions: const [
              'Add follow-up',
              'Mark reached',
              'Reschedule follow-up',
            ],
            metrics: const [
              DemoMetric(
                label: 'Scheduled today',
                value: '12',
                note: 'Outbound',
              ),
              DemoMetric(label: 'Reached', value: '7', note: 'So far'),
              DemoMetric(label: 'Need retry', value: '3', note: 'No answer'),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Post-consultation check-in',
                subtitle:
                    'Call member after Manjeri visit to confirm medicine pickup.',
                meta: 'Customer care',
                status: 'Due',
              ),
              DemoListItem(
                title: 'Activation reminder',
                subtitle:
                    'Pending member from Melattur needs enrollment completion guidance.',
                meta: 'Growth',
                status: 'Due',
              ),
              DemoListItem(
                title: 'Dental review follow-up',
                subtitle:
                    'Confirm that recall appointment still works for Friday, June 26, 2026.',
                meta: 'Melattur',
                status: 'Scheduled',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Follow-up logged',
                subtitle: 'Conversation summary saved with next step and date.',
                meta: 'CRM note',
                status: 'Stored',
              ),
              DemoListItem(
                title: 'Escalation raised',
                subtitle:
                    'Home visit concern handed over to clinic operations.',
                meta: 'Cross-team',
                status: 'Raised',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best timing',
                subtitle:
                    'Afternoon callbacks perform better than morning outreach for working members.',
                meta: 'Contact behavior',
                status: 'Improved',
              ),
              DemoListItem(
                title: 'High-retention pattern',
                subtitle:
                    'Follow-up calls after first pharmacy wallet use help keep members active.',
                meta: 'Retention signal',
                status: 'Strong',
              ),
            ],
          ),
          DemoSectionData(
            key: 'complaints',
            title: 'Complaints',
            summary:
                'Track complaint intake, resolution progress, ownership, and member communication around issues.',
            actions: const ['New complaint', 'Escalate', 'Resolve case'],
            metrics: const [
              DemoMetric(label: 'Open cases', value: '7', note: 'Current'),
              DemoMetric(
                label: 'Resolved this week',
                value: '11',
                note: 'Closed',
              ),
              DemoMetric(
                label: 'Avg resolution',
                value: '1.8 days',
                note: 'Demo SLA',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Wallet deduction confusion',
                subtitle:
                    'Member wants branch-wise itemization of medicine charges.',
                meta: 'Perinthalmanna',
                status: 'Open',
              ),
              DemoListItem(
                title: 'Delayed report visibility',
                subtitle: 'Lab file approved late after upload from Tirur.',
                meta: 'Tirur',
                status: 'Investigating',
              ),
              DemoListItem(
                title: 'Appointment delay complaint',
                subtitle:
                    'Wait time exceeded expected window at clinic reception.',
                meta: 'Manjeri',
                status: 'Assigned',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Complaint closed',
                subtitle:
                    'Branch manager called the member and offered a resolution.',
                meta: 'Service recovery',
                status: 'Resolved',
              ),
              DemoListItem(
                title: 'Internal note added',
                subtitle:
                    'Timeline updated with resolution steps for audit traceability.',
                meta: 'Audit support',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most common issue',
                subtitle:
                    'Service explanation gaps are more frequent than hard service failures.',
                meta: 'Root cause',
                status: 'Common',
              ),
              DemoListItem(
                title: 'Best recovery path',
                subtitle:
                    'Same-day human callback produces the highest complaint closure satisfaction.',
                meta: 'Resolution pattern',
                status: 'Effective',
              ),
            ],
          ),
          DemoSectionData(
            key: 'campaigns',
            title: 'Campaigns',
            summary:
                'Preview branch-level outreach lists, retention offers, and service-promotion campaigns using dummy audience segments.',
            actions: const [
              'Create campaign',
              'Preview audience',
              'Schedule outreach',
            ],
            metrics: const [
              DemoMetric(
                label: 'Live campaigns',
                value: '4',
                note: 'Demo mode',
              ),
              DemoMetric(
                label: 'Audience size',
                value: '126',
                note: 'Combined',
              ),
              DemoMetric(
                label: 'Expected reach',
                value: '81%',
                note: 'Contactable members',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Wellness camp outreach',
                subtitle:
                    'Target inactive members near Alanallur and Makkaraparamba.',
                meta: 'Preventive care',
                status: 'Draft',
              ),
              DemoListItem(
                title: 'Pharmacy repeat-purchase push',
                subtitle:
                    'Encourage return visits in Perinthalmanna and Tirur branches.',
                meta: 'Retention',
                status: 'Scheduled',
              ),
              DemoListItem(
                title: 'Dental recall drive',
                subtitle: 'Invite members due for preventive dental reviews.',
                meta: 'Melattur',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Audience filtered',
                subtitle:
                    'Low-activity members separated from high-engagement clusters.',
                meta: 'Segmentation',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Message draft saved',
                subtitle:
                    'Short healthcare-first copy prepared for push and SMS.',
                meta: 'Campaign prep',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best campaign angle',
                subtitle:
                    'Practical reminders and savings messages outperform generic promotions.',
                meta: 'Message learning',
                status: 'Proven',
              ),
              DemoListItem(
                title: 'Branch opportunity',
                subtitle:
                    'Perinthalmanna cluster has the highest potential for repeat pharmacy campaigns.',
                meta: 'Growth insight',
                status: 'Top',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.shieldExecutive:
      return DemoRoleData(
        role: role,
        operatorName: 'Rashid P',
        headline:
            'Operational control for member approvals, membership lifecycle, wallet adjustments, and reversals',
        regionLabel: 'Central SHIELD operations desk',
        icon: Icons.verified_user,
        accentColor: AppColors.shieldBlue,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Watch pending approvals, membership actions, wallet adjustment requests, and branch escalations from a single operations board.',
            actions: const [
              'Review approval',
              'Adjust wallet',
              'Open reversal',
            ],
            metrics: const [
              DemoMetric(
                label: 'Pending approvals',
                value: '14',
                note: 'New members',
              ),
              DemoMetric(
                label: 'Wallet requests',
                value: '6',
                note: 'Manual actions',
              ),
              DemoMetric(
                label: 'Reversal cases',
                value: '3',
                note: 'Awaiting decision',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Founding member validation',
                subtitle:
                    'RC-linked member record is ready for activation review.',
                meta: 'Perinthalmanna',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Wallet top-up request',
                subtitle:
                    'Manual recharge request raised from Melattur branch.',
                meta: 'Branch ops',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Pharmacy reversal appeal',
                subtitle:
                    'Counter staff wants a mistaken deduction reversed after verification.',
                meta: 'Tirur',
                status: 'Urgent',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Membership approved',
                subtitle: 'Digital card generation completed after activation.',
                meta: 'Operations',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Adjustment posted',
                subtitle:
                    'Promotional credit manually added with audit visibility.',
                meta: 'Wallet ops',
                status: 'Completed',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Busiest pipeline',
                subtitle:
                    'Member approval remains the heaviest daily operations queue.',
                meta: 'Workload insight',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Control point',
                subtitle:
                    'Reversal reviews need branch context and transaction proof side by side.',
                meta: 'Process note',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'approvals',
            title: 'Customer Approvals',
            summary:
                'Review new member applications, validate identity details, and activate records for downstream wallet and card creation.',
            actions: const ['Approve member', 'Request change', 'Suspend case'],
            metrics: const [
              DemoMetric(
                label: 'In review',
                value: '14',
                note: 'Current queue',
              ),
              DemoMetric(
                label: 'Approved today',
                value: '8',
                note: 'Activation done',
              ),
              DemoMetric(
                label: 'Need clarification',
                value: '2',
                note: 'Incomplete profiles',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Shanib K application',
                subtitle:
                    'Basic profile is present but founding eligibility needs confirmation.',
                meta: 'Manjeri',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Family enrollment',
                subtitle:
                    'Multi-member record from Alanallur awaiting final mobile validation.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Legacy RC migration',
                subtitle:
                    'Profile imported with old loyalty data ready for cleanup.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Approval note saved',
                subtitle:
                    'Why the member was approved was added for audit clarity.',
                meta: 'Ops note',
                status: 'Stored',
              ),
              DemoListItem(
                title: 'Status history posted',
                subtitle:
                    'Draft to active transition recorded in the member timeline.',
                meta: 'Audit trail',
                status: 'Tracked',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Fastest approval branch',
                subtitle:
                    'Perinthalmanna referrals are arriving with the cleanest data quality.',
                meta: 'Source quality',
                status: 'Best',
              ),
              DemoListItem(
                title: 'Common blocker',
                subtitle:
                    'Unverified mobile numbers remain the main delay in same-day activation.',
                meta: 'Root cause',
                status: 'Common',
              ),
            ],
          ),
          DemoSectionData(
            key: 'memberships',
            title: 'Memberships',
            summary:
                'Manage founding versus standard memberships, card generation, lifecycle changes, and branch-level plan visibility.',
            actions: const [
              'Activate card',
              'Suspend membership',
              'Generate QR',
            ],
            metrics: const [
              DemoMetric(
                label: 'Founding members',
                value: '238',
                note: 'Demo count',
              ),
              DemoMetric(
                label: 'Standard members',
                value: '174',
                note: 'Demo count',
              ),
              DemoMetric(
                label: 'Cards generated',
                value: '401',
                note: 'Digital',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Card generation pending',
                subtitle:
                    'Member profile approved but digital card not yet issued.',
                meta: 'Melattur',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Standard plan activation',
                subtitle:
                    'Fee marked collected, awaiting final activate click.',
                meta: 'Tirur',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Suspension review',
                subtitle:
                    'Temporary hold requested because of profile mismatch.',
                meta: 'Manjeri',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'QR token issued',
                subtitle:
                    'Privilege card is now available inside customer-facing views.',
                meta: 'Membership flow',
                status: 'Issued',
              ),
              DemoListItem(
                title: 'Lifecycle event saved',
                subtitle: 'Activation timestamp written to membership history.',
                meta: 'Audit support',
                status: 'Stored',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Founding member story',
                subtitle:
                    'Legacy RC migration remains a strong narrative point for management demos.',
                meta: 'Business context',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'UX improvement',
                subtitle:
                    'Membership status filters should stay prominent in future admin builds.',
                meta: 'Future note',
                status: 'Helpful',
              ),
            ],
          ),
          DemoSectionData(
            key: 'wallet-ops',
            title: 'Wallet Operations',
            summary:
                'Approve recharges, manual adjustments, promotional credits, and exception handling with clear audit context.',
            actions: const ['Add credit', 'Approve recharge', 'View ledger'],
            metrics: const [
              DemoMetric(
                label: 'Requests today',
                value: '6',
                note: 'Manual queue',
              ),
              DemoMetric(label: 'Credits posted', value: '4', note: 'Same day'),
              DemoMetric(
                label: 'Exception holds',
                value: '1',
                note: 'Needs manager',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Manual top-up request',
                subtitle:
                    'Branch asked for a member recharge after offline cash collection.',
                meta: 'Melattur',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Promotional credit',
                subtitle:
                    'Preventive camp bonus to be posted to selected members.',
                meta: 'Alanallur',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Negative adjustment hold',
                subtitle:
                    'Chargeback request requires manager confirmation before posting.',
                meta: 'Perinthalmanna',
                status: 'Blocked',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Ledger visible',
                subtitle:
                    'All dummy wallet adjustments are reflected with before/after context.',
                meta: 'Control view',
                status: 'Clear',
              ),
              DemoListItem(
                title: 'Notification sent',
                subtitle:
                    'Member alert triggered after wallet credit approval.',
                meta: 'Customer comms',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'High-friction step',
                subtitle:
                    'Manual recharge review is where the UI needs the clearest audit explanation.',
                meta: 'Risk control',
                status: 'Important',
              ),
              DemoListItem(
                title: 'Operational value',
                subtitle:
                    'Wallet operations pages help management understand the ledger-based model quickly.',
                meta: 'Demo value',
                status: 'Strong',
              ),
            ],
          ),
          DemoSectionData(
            key: 'reversals',
            title: 'Reversals',
            summary:
                'Inspect disputed transactions, supporting notes, and branch evidence before approving or rejecting reversals.',
            actions: const [
              'Approve reversal',
              'Reject request',
              'Request proof',
            ],
            metrics: const [
              DemoMetric(
                label: 'Open reversal cases',
                value: '3',
                note: 'Current queue',
              ),
              DemoMetric(
                label: 'Approved this week',
                value: '5',
                note: 'Closed',
              ),
              DemoMetric(
                label: 'Need branch proof',
                value: '1',
                note: 'Incomplete',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Pharmacy double-scan case',
                subtitle: 'Member was charged twice after a counter retry.',
                meta: 'Tirur',
                status: 'Investigate',
              ),
              DemoListItem(
                title: 'Wrong member deduction',
                subtitle:
                    'Branch note suggests the sale was posted to the wrong wallet.',
                meta: 'Perinthalmanna',
                status: 'Urgent',
              ),
              DemoListItem(
                title: 'Cancelled consultation fee',
                subtitle:
                    'No-show fee was deducted despite same-day branch cancellation.',
                meta: 'Manjeri',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Decision logged',
                subtitle:
                    'Previous reversal decision shows approver note and reason.',
                meta: 'Audit trail',
                status: 'Stored',
              ),
              DemoListItem(
                title: 'Member informed',
                subtitle:
                    'Push notification prepared for accepted reversal outcome.',
                meta: 'Comms',
                status: 'Ready',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most common reversal cause',
                subtitle:
                    'Counter-level transaction duplication is the main exception case in demo data.',
                meta: 'Pattern',
                status: 'Common',
              ),
              DemoListItem(
                title: 'Control improvement',
                subtitle:
                    'Side-by-side bill, wallet, and verification history would strengthen review confidence.',
                meta: 'Product note',
                status: 'Future',
              ),
            ],
          ),
          DemoSectionData(
            key: 'support',
            title: 'Support Cases',
            summary:
                'See escalations from branch staff and CRM, then route them to the right operational owner with notes.',
            actions: const ['Assign owner', 'Add note', 'Close issue'],
            metrics: const [
              DemoMetric(label: 'Escalations', value: '9', note: 'Open'),
              DemoMetric(
                label: 'Cross-team handoffs',
                value: '4',
                note: 'Today',
              ),
              DemoMetric(
                label: 'Closed this week',
                value: '18',
                note: 'Resolved',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Pending activation issue',
                subtitle:
                    'CRM flagged a member whose card was not generated after approval.',
                meta: 'Manjeri',
                status: 'Open',
              ),
              DemoListItem(
                title: 'Wallet confusion handoff',
                subtitle: 'Branch and CRM notes bundled into one support case.',
                meta: 'Perinthalmanna',
                status: 'Assigned',
              ),
              DemoListItem(
                title: 'Document visibility complaint',
                subtitle:
                    'Customer cannot find a newly approved report in the app.',
                meta: 'Tirur',
                status: 'Review',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Support note merged',
                subtitle:
                    'Escalation history now shows all prior branch comments.',
                meta: 'Case detail',
                status: 'Merged',
              ),
              DemoListItem(
                title: 'Issue closed',
                subtitle:
                    'Customer confirmed that the missing card is now visible.',
                meta: 'Resolution',
                status: 'Closed',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Cross-team hotspot',
                subtitle:
                    'Membership and wallet exceptions create the most support handoffs.',
                meta: 'Ops learning',
                status: 'Frequent',
              ),
              DemoListItem(
                title: 'Clarity need',
                subtitle:
                    'Support cases benefit when branch location is visible everywhere in the UI.',
                meta: 'UX lesson',
                status: 'Useful',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.manager:
      return DemoRoleData(
        role: role,
        operatorName: 'Shameer Ali',
        headline:
            'Management overview for approvals, reports, credit exposure, and service performance',
        regionLabel: 'Regional operations and performance dashboard',
        icon: Icons.analytics,
        accentColor: AppColors.success,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Scan high-level member growth, revenue movement, service usage, and pending approvals from a leadership view.',
            actions: const [
              'Open analytics',
              'Review approvals',
              'View report pack',
            ],
            metrics: const [
              DemoMetric(
                label: 'Active members',
                value: '412',
                note: 'Demo tenant',
              ),
              DemoMetric(
                label: 'Monthly revenue',
                value: '₹8.4L',
                note: 'Combined services',
              ),
              DemoMetric(
                label: 'Pending decisions',
                value: '9',
                note: 'Need manager eye',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Credit override request',
                subtitle:
                    'One high-value member needs extended facility approval.',
                meta: 'Perinthalmanna',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Branch performance review',
                subtitle:
                    'Tirur branch saw improved pharmacy conversion this week.',
                meta: 'Ops review',
                status: 'Open',
              ),
              DemoListItem(
                title: 'Retention dip watch',
                subtitle:
                    'Alanallur cluster has lower repeat service usage than expected.',
                meta: 'Management alert',
                status: 'Watch',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Report pack generated',
                subtitle:
                    'Weekly membership, wallet, and service trend summary is ready.',
                meta: 'Reporting',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Approval completed',
                subtitle:
                    'Manager approved a branch-level wallet exception case.',
                meta: 'Decision log',
                status: 'Done',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Growth leader',
                subtitle:
                    'Perinthalmanna remains the strongest multi-service cluster in the demo.',
                meta: 'Branch ranking',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Focus area',
                subtitle:
                    'Alanallur and Makkaraparamba need stronger recall and outreach coverage.',
                meta: 'Actionable insight',
                status: 'Focus',
              ),
            ],
          ),
          DemoSectionData(
            key: 'approvals',
            title: 'Approvals',
            summary:
                'Review manager-level approvals including credit overrides, high-risk wallet operations, and operational escalations.',
            actions: const ['Approve request', 'Reject', 'Escalate further'],
            metrics: const [
              DemoMetric(label: 'Credit approvals', value: '4', note: 'Open'),
              DemoMetric(
                label: 'Wallet overrides',
                value: '3',
                note: 'Need decision',
              ),
              DemoMetric(
                label: 'Branch escalations',
                value: '2',
                note: 'Operational',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Credit extension',
                subtitle:
                    'Long-term member requests temporary additional healthcare credit.',
                meta: 'Manjeri',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Negative adjustment approval',
                subtitle:
                    'SHIELD executive requires manager sign-off for balance reduction.',
                meta: 'Perinthalmanna',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'High-value reversal',
                subtitle:
                    'A large pharmacy reversal is waiting for final approval.',
                meta: 'Tirur',
                status: 'Urgent',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Decision logged',
                subtitle: 'Approval note captured with financial rationale.',
                meta: 'Audit support',
                status: 'Stored',
              ),
              DemoListItem(
                title: 'Case returned',
                subtitle:
                    'Branch was asked to submit clearer proof before approval.',
                meta: 'Workflow',
                status: 'Returned',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Approval mix',
                subtitle:
                    'Credit-related decisions are the most sensitive management reviews.',
                meta: 'Risk pattern',
                status: 'Highest',
              ),
              DemoListItem(
                title: 'Design ask',
                subtitle:
                    'Managers benefit from a compact branch and member context summary in each case.',
                meta: 'UX note',
                status: 'Needed',
              ),
            ],
          ),
          DemoSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Access role-oriented report packs for memberships, wallet use, branch performance, and operational quality.',
            actions: const ['Export PDF', 'Export Excel', 'Schedule report'],
            metrics: const [
              DemoMetric(label: 'Report packs', value: '7', note: 'Available'),
              DemoMetric(
                label: 'Exports today',
                value: '5',
                note: 'Leadership use',
              ),
              DemoMetric(
                label: 'Data freshness',
                value: '15 min',
                note: 'Demo SLA',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Membership summary',
                subtitle:
                    'Founding versus standard member mix by active branch.',
                meta: 'Executive pack',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Wallet utilization',
                subtitle: 'Spend and recharge patterns across the member base.',
                meta: 'Finance lens',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Document operations report',
                subtitle:
                    'Processing backlog and approval performance by source.',
                meta: 'Ops lens',
                status: 'Queued',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'CSV export generated',
                subtitle:
                    'Branch-wise service usage exported for external review.',
                meta: 'Data export',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Weekly dashboard snapshot',
                subtitle: 'A static pack was saved for management meeting use.',
                meta: 'Meeting prep',
                status: 'Prepared',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most useful pack',
                subtitle:
                    'Combined membership and wallet views tell the clearest business story.',
                meta: 'Management insight',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Next enhancement',
                subtitle:
                    'A care-path funnel would help connect membership to service usage more clearly.',
                meta: 'Opportunity',
                status: 'Future',
              ),
            ],
          ),
          DemoSectionData(
            key: 'analytics',
            title: 'Analytics',
            summary:
                'Inspect branch trends, service mix, member retention patterns, and operational bottlenecks through demo insights.',
            actions: const [
              'Compare branches',
              'Filter service',
              'Open segment',
            ],
            metrics: const [
              DemoMetric(
                label: 'Retention rate',
                value: '78%',
                note: 'Demo average',
              ),
              DemoMetric(
                label: 'Repeat purchase rate',
                value: '64%',
                note: 'Pharmacy-heavy',
              ),
              DemoMetric(
                label: 'Avg service depth',
                value: '2.7',
                note: 'Per active member',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Perinthalmanna outperformance',
                subtitle:
                    'Strongest combined pharmacy, clinic, and document engagement.',
                meta: 'Cluster insight',
                status: 'Lead',
              ),
              DemoListItem(
                title: 'Alanallur watchlist',
                subtitle:
                    'Lower repeat service usage suggests a follow-up gap.',
                meta: 'Retention watch',
                status: 'Watch',
              ),
              DemoListItem(
                title: 'Tirur growth curve',
                subtitle:
                    'Service frequency is rising after member activation improvements.',
                meta: 'Positive trend',
                status: 'Up',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Segment updated',
                subtitle:
                    'Low-engagement cohort now highlights members without a recent follow-up.',
                meta: 'Analytics model',
                status: 'Updated',
              ),
              DemoListItem(
                title: 'Trend summary saved',
                subtitle: 'Branch comparison snapshot prepared for review.',
                meta: 'Management deck',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Key business link',
                subtitle:
                    'Member retention improves where pharmacy and clinic usage happen together.',
                meta: 'Cross-service insight',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Operational lesson',
                subtitle:
                    'Document delays slightly reduce repeat digital engagement after clinic visits.',
                meta: 'Process effect',
                status: 'Observed',
              ),
            ],
          ),
          DemoSectionData(
            key: 'credit',
            title: 'Credit Oversight',
            summary:
                'Review member credit limits, utilization, approval requests, and collection risk from a management perspective.',
            actions: const [
              'Approve limit',
              'Pause account',
              'Review utilization',
            ],
            metrics: const [
              DemoMetric(
                label: 'Active credit accounts',
                value: '38',
                note: 'Demo count',
              ),
              DemoMetric(label: 'Utilization', value: '61%', note: 'Current'),
              DemoMetric(
                label: 'Overdue watch',
                value: '4',
                note: 'Need follow-up',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Credit limit increase request',
                subtitle:
                    'Regular member seeks temporary extension for treatment bundle.',
                meta: 'Perinthalmanna',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Utilization nearing cap',
                subtitle:
                    'One member is close to full use and may need pause rules.',
                meta: 'Manjeri',
                status: 'Watch',
              ),
              DemoListItem(
                title: 'Settlement follow-up',
                subtitle:
                    'CRM support required for one overdue recovery conversation.',
                meta: 'Tirur',
                status: 'Action',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Approval granted',
                subtitle:
                    'Credit case approved with note on utilization history.',
                meta: 'Decision',
                status: 'Approved',
              ),
              DemoListItem(
                title: 'Collection note added',
                subtitle: 'Recovery follow-up date saved for the CRM team.',
                meta: 'Cross-team',
                status: 'Tagged',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Healthy signal',
                subtitle:
                    'Members with repeat preventive service usage show lower credit stress.',
                meta: 'Risk insight',
                status: 'Positive',
              ),
              DemoListItem(
                title: 'Guardrail',
                subtitle:
                    'Credit oversight pages should always show branch and membership type together.',
                meta: 'Decision aid',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'retention',
            title: 'Retention',
            summary:
                'Focus on repeat visits, service continuity, and locality-based engagement opportunities across the network.',
            actions: const ['Open segment', 'Trigger CRM', 'Branch compare'],
            metrics: const [
              DemoMetric(
                label: 'Repeat members',
                value: '264',
                note: '30-day activity',
              ),
              DemoMetric(
                label: 'Dormant members',
                value: '36',
                note: 'Need reactivation',
              ),
              DemoMetric(
                label: 'Recall success',
                value: '71%',
                note: 'Follow-up driven',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Dormant member cohort',
                subtitle:
                    'Alanallur and Makkaraparamba show the highest inactivity pockets.',
                meta: 'Retention risk',
                status: 'Open',
              ),
              DemoListItem(
                title: 'High-loyalty cohort',
                subtitle:
                    'Perinthalmanna members with wallet usage remain highly sticky.',
                meta: 'Best group',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Dental recall opportunity',
                subtitle:
                    'Preventive-care revisits can improve long-term engagement in Melattur.',
                meta: 'Campaign idea',
                status: 'Promising',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Retention list shared',
                subtitle:
                    'CRM received a targeted call list for low-activity members.',
                meta: 'Action',
                status: 'Sent',
              ),
              DemoListItem(
                title: 'Branch summary refreshed',
                subtitle:
                    'Repeat visit trends updated after the last week of demo activity.',
                meta: 'Insight pack',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Retention formula',
                subtitle:
                    'Members who touch two or more SHIELD services stay active more reliably.',
                meta: 'Core insight',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Near-term lever',
                subtitle:
                    'Appointment follow-ups and pharmacy campaigns are the fastest reactivation tools.',
                meta: 'Action plan',
                status: 'Clear',
              ),
            ],
          ),
        ],
      );
    case SHIELDRole.superAdmin:
      return DemoRoleData(
        role: role,
        operatorName: 'Ameen Basith',
        headline:
            'System-wide administration for users, roles, businesses, audit, and platform configuration',
        regionLabel: 'Unified SHIELD admin console',
        icon: Icons.admin_panel_settings,
        accentColor: AppColors.error,
        sections: [
          DemoSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'View users, roles, businesses, permission health, and system events from the top-level admin control room.',
            actions: const ['Add user', 'Open audit', 'Check system'],
            metrics: const [
              DemoMetric(label: 'Users', value: '86', note: 'All roles'),
              DemoMetric(label: 'Businesses', value: '5', note: 'Configured'),
              DemoMetric(
                label: 'Audit events today',
                value: '428',
                note: 'Tracked',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Role mapping review',
                subtitle:
                    'One branch user was placed in the wrong department permission set.',
                meta: 'Security admin',
                status: 'Review',
              ),
              DemoListItem(
                title: 'System setting draft',
                subtitle:
                    'Notification channel defaults prepared for rollout confirmation.',
                meta: 'Config',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Audit spike noticed',
                subtitle:
                    'Higher-than-usual wallet adjustment activity flagged for quick review.',
                meta: 'Audit watch',
                status: 'Watch',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'User created',
                subtitle:
                    'New pharmacy staff account provisioned for Tirur branch.',
                meta: 'Admin action',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Permission bundle updated',
                subtitle: 'Role grants refreshed for CRM executive operations.',
                meta: 'Access control',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Governance value',
                subtitle:
                    'A clear admin view helps the management demo show SHIELD as one platform, not disconnected tools.',
                meta: 'Storytelling',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Security reminder',
                subtitle:
                    'Audit visibility is the strongest differentiator for this admin demo layer.',
                meta: 'Control insight',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'users',
            title: 'Users',
            summary:
                'Create and manage staff accounts, role assignments, business mapping, and account statuses using dummy records.',
            actions: const ['Create user', 'Disable user', 'Reset access'],
            metrics: const [
              DemoMetric(label: 'Active users', value: '79', note: 'Enabled'),
              DemoMetric(label: 'Disabled', value: '7', note: 'Inactive'),
              DemoMetric(
                label: 'New this month',
                value: '12',
                note: 'Onboarded',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Tirur pharmacy onboarding',
                subtitle:
                    'New staff profile is ready for role and branch assignment.',
                meta: 'User setup',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Dormant CRM account',
                subtitle:
                    'Account should be disabled after last working day confirmation.',
                meta: 'Lifecycle',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Shared-device access issue',
                subtitle:
                    'One clinic user asked for a session reset after branch handover.',
                meta: 'Support',
                status: 'Open',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Role changed',
                subtitle:
                    'Branch coordinator updated from staff to manager visibility tier.',
                meta: 'Access update',
                status: 'Applied',
              ),
              DemoListItem(
                title: 'Device session cleared',
                subtitle: 'Old login tokens revoked for security hygiene.',
                meta: 'Auth admin',
                status: 'Done',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Most active user group',
                subtitle:
                    'Pharmacy staff accounts generate the highest daily platform interaction.',
                meta: 'Usage mix',
                status: 'Top',
              ),
              DemoListItem(
                title: 'Admin note',
                subtitle:
                    'Business and department should remain visible in every user row for clarity.',
                meta: 'UX note',
                status: 'Helpful',
              ),
            ],
          ),
          DemoSectionData(
            key: 'roles',
            title: 'Roles & Permissions',
            summary:
                'Inspect role bundles, permission groups, and cross-business access policy for each SHIELD role.',
            actions: const ['Edit role', 'Assign permissions', 'Clone bundle'],
            metrics: const [
              DemoMetric(label: 'Roles', value: '8', note: 'Platform roles'),
              DemoMetric(
                label: 'Permission groups',
                value: '24',
                note: 'Demo bundles',
              ),
              DemoMetric(
                label: 'Policy exceptions',
                value: '1',
                note: 'Needs review',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Clinic role visibility check',
                subtitle:
                    'Ensure clinic staff cannot open dental-only records.',
                meta: 'ABAC review',
                status: 'Review',
              ),
              DemoListItem(
                title: 'CRM bundle cleanup',
                subtitle:
                    'Customer profile visibility requires a narrower permission set.',
                meta: 'Access design',
                status: 'Pending',
              ),
              DemoListItem(
                title: 'Manager override rights',
                subtitle:
                    'Credit approval actions being reviewed for consistency.',
                meta: 'Governance',
                status: 'Open',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Permission set saved',
                subtitle:
                    'A draft update to SHIELD executive rights was retained in demo mode.',
                meta: 'Role admin',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Policy note added',
                subtitle:
                    'ABAC dependency documented in the role details panel.',
                meta: 'Documentation',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Critical concept',
                subtitle:
                    'Role pages help explain the difference between broad access and record visibility.',
                meta: 'Security story',
                status: 'Clear',
              ),
              DemoListItem(
                title: 'Future step',
                subtitle:
                    'A permission diff view would make governance reviews even easier later.',
                meta: 'Enhancement',
                status: 'Useful',
              ),
            ],
          ),
          DemoSectionData(
            key: 'businesses',
            title: 'Businesses',
            summary:
                'Manage business units, departments, branch identities, and service-provider structure across the SHIELD network.',
            actions: const ['Add business', 'Create department', 'Edit branch'],
            metrics: const [
              DemoMetric(label: 'Businesses', value: '5', note: 'Configured'),
              DemoMetric(
                label: 'Departments',
                value: '14',
                note: 'Across branches',
              ),
              DemoMetric(
                label: 'Active providers',
                value: '12',
                note: 'Demo list',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'New Tirur setup',
                subtitle:
                    'Branch identity draft ready for provider and department mapping.',
                meta: 'Expansion prep',
                status: 'Draft',
              ),
              DemoListItem(
                title: 'Alanallur care desk',
                subtitle:
                    'Home-care support department proposed under clinic operations.',
                meta: 'Department design',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Makkaraparamba routing note',
                subtitle:
                    'Service-provider linkage needs cleanup for outreach reporting.',
                meta: 'Data structure',
                status: 'Attention',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Department updated',
                subtitle:
                    'CRM unit linked correctly to the central engagement team.',
                meta: 'Org mapping',
                status: 'Updated',
              ),
              DemoListItem(
                title: 'Provider label revised',
                subtitle:
                    'Branch naming aligned to SHIELD demo copy across the app.',
                meta: 'Branding',
                status: 'Aligned',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Best platform story',
                subtitle:
                    'Business configuration proves SHIELD can span pharmacies, clinics, dental, and outreach under one model.',
                meta: 'Architecture story',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Modeling reminder',
                subtitle:
                    'Provider and department structure should stay simple for early demos.',
                meta: 'Scope control',
                status: 'Wise',
              ),
            ],
          ),
          DemoSectionData(
            key: 'audit',
            title: 'Audit Logs',
            summary:
                'Review immutable audit activity across logins, approvals, wallet operations, document actions, and admin changes.',
            actions: const ['Filter logs', 'Export trail', 'Inspect event'],
            metrics: const [
              DemoMetric(
                label: 'Events today',
                value: '428',
                note: 'All domains',
              ),
              DemoMetric(
                label: 'Critical actions',
                value: '39',
                note: 'High visibility',
              ),
              DemoMetric(
                label: 'Export requests',
                value: '2',
                note: 'Leadership review',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Wallet adjustment audit',
                subtitle: 'Track who changed a member balance and why.',
                meta: 'Finance control',
                status: 'Visible',
              ),
              DemoListItem(
                title: 'Approval trail',
                subtitle:
                    'Customer activation decision with full actor and timestamp chain.',
                meta: 'Membership',
                status: 'Visible',
              ),
              DemoListItem(
                title: 'Role update event',
                subtitle:
                    'Permission change captured with old/new state for review.',
                meta: 'Admin control',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Export generated',
                subtitle:
                    'Filtered audit slice prepared for management review.',
                meta: 'Compliance',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Event inspection opened',
                subtitle:
                    'Detailed event view helps explain append-only tracking.',
                meta: 'Demo flow',
                status: 'Viewed',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Strong differentiator',
                subtitle:
                    'Audit visibility is one of the most convincing enterprise demo elements.',
                meta: 'Product strength',
                status: 'Major',
              ),
              DemoListItem(
                title: 'Future note',
                subtitle:
                    'Entity snapshots and filters should stay fast even as logs scale.',
                meta: 'Scalability thought',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'system',
            title: 'System Settings',
            summary:
                'Review top-level platform configuration such as notification defaults, file settings, and security preferences in demo form.',
            actions: const ['Edit setting', 'Preview policy', 'Save draft'],
            metrics: const [
              DemoMetric(
                label: 'Config groups',
                value: '9',
                note: 'Demo sections',
              ),
              DemoMetric(
                label: 'Draft changes',
                value: '2',
                note: 'Not applied',
              ),
              DemoMetric(
                label: 'Security profile',
                value: 'Healthy',
                note: 'Demo status',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Notification defaults',
                subtitle:
                    'Push + SMS remain enabled for OTP and appointment reminders.',
                meta: 'Communications',
                status: 'Configured',
              ),
              DemoListItem(
                title: 'File policy review',
                subtitle:
                    'Document upload size and allowed file types are visible to admins.',
                meta: 'Storage control',
                status: 'Review',
              ),
              DemoListItem(
                title: 'Session rules',
                subtitle:
                    'Refresh token duration and login behavior shown in settings UI.',
                meta: 'Security',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Draft saved',
                subtitle:
                    'A system settings preview was saved without affecting demo behavior.',
                meta: 'Configuration',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Security note updated',
                subtitle:
                    'TLS and audit requirements summarized in the system overview.',
                meta: 'Governance',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Management takeaway',
                subtitle:
                    'System settings complete the story that SHIELD is configurable, not hard-coded.',
                meta: 'Enterprise signal',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Design guardrail',
                subtitle:
                    'Settings should stay readable and grouped, not turn into a wall of switches.',
                meta: 'UX caution',
                status: 'Important',
              ),
            ],
          ),
          DemoSectionData(
            key: 'membership-plans',
            title: 'Membership Plans',
            summary:
                'Configure founding and standard membership plans, fees, benefits, and renewal rules in an admin-focused planning screen.',
            actions: const ['Add plan', 'Edit benefit', 'Preview card'],
            metrics: const [
              DemoMetric(
                label: 'Plans',
                value: '2',
                note: 'Founding + standard',
              ),
              DemoMetric(
                label: 'Active benefits',
                value: '11',
                note: 'Visible in demo',
              ),
              DemoMetric(
                label: 'Draft changes',
                value: '1',
                note: 'Awaiting review',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Founding member plan',
                subtitle:
                    'Legacy RC migration benefits are summarized with card and wallet eligibility notes.',
                meta: 'Core plan',
                status: 'Active',
              ),
              DemoListItem(
                title: 'Standard member plan',
                subtitle:
                    'General enrollment fee and digital privilege card package are shown for new customers.',
                meta: 'Enrollment',
                status: 'Active',
              ),
              DemoListItem(
                title: 'Renewal wording update',
                subtitle:
                    'A draft copy change is prepared for the next management review.',
                meta: 'Content draft',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Benefit preview opened',
                subtitle:
                    'Admin can check how plan changes would appear in the customer app.',
                meta: 'Cross-view',
                status: 'Viewed',
              ),
              DemoListItem(
                title: 'Rule note saved',
                subtitle:
                    'A renewal rule explanation was retained inside the plan details panel.',
                meta: 'Governance',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Important closure',
                subtitle:
                    'This page closes the biggest remaining admin gap from the UI spec after users, roles, and settings.',
                meta: 'Spec fit',
                status: 'Major',
              ),
              DemoListItem(
                title: 'Narrative strength',
                subtitle:
                    'Membership plans help management connect frontend polish to the core business model of SHIELD.',
                meta: 'Product story',
                status: 'Strong',
              ),
            ],
          ),
          DemoSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Centralize exports and admin-facing reporting packs for membership, wallet, CRM, document, and operational review.',
            actions: const ['Generate pack', 'Export CSV', 'Schedule report'],
            metrics: const [
              DemoMetric(
                label: 'Available packs',
                value: '8',
                note: 'Admin catalog',
              ),
              DemoMetric(
                label: 'Exports today',
                value: '5',
                note: '20 Jun 2026',
              ),
              DemoMetric(
                label: 'Most used',
                value: 'Membership report',
                note: 'Leadership review',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Membership report',
                subtitle:
                    'Founding versus standard member distribution is ready for leadership export.',
                meta: 'Core report',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Document processing pack',
                subtitle:
                    'Processing backlog and approval throughput are grouped in one admin view.',
                meta: 'Ops report',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'CRM summary',
                subtitle:
                    'Follow-up, complaint, and retention activity can be exported from a single reporting card.',
                meta: 'CRM report',
                status: 'Queued',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'CSV export generated',
                subtitle:
                    'A branch-wise service sheet was prepared for external management review.',
                meta: 'Export',
                status: 'Done',
              ),
              DemoListItem(
                title: 'Report schedule draft',
                subtitle:
                    'Weekly operational packs were prepared in demo mode without automation dependencies.',
                meta: 'Schedule',
                status: 'Draft',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Admin completeness',
                subtitle:
                    'Reports make the admin workspace feel operationally complete instead of purely configurational.',
                meta: 'Coverage',
                status: 'Strong',
              ),
              DemoListItem(
                title: 'Future alignment',
                subtitle:
                    'The current cards map cleanly to the reporting and analytics modules described in the docs.',
                meta: 'Architecture fit',
                status: 'Good',
              ),
            ],
          ),
          DemoSectionData(
            key: 'notification-center',
            title: 'Notification Center',
            summary:
                'Review outbound alerts, templates, channel defaults, and recent delivery history across all platform roles.',
            actions: const ['Open template', 'Filter channel', 'Preview alert'],
            metrics: const [
              DemoMetric(
                label: 'Alerts today',
                value: '164',
                note: 'Push + SMS + in-app',
              ),
              DemoMetric(
                label: 'Delivery success',
                value: '98%',
                note: 'Demo aggregate',
              ),
              DemoMetric(
                label: 'Templates',
                value: '12',
                note: 'Role-aware copy',
              ),
            ],
            queueItems: const [
              DemoListItem(
                title: 'Appointment reminder template',
                subtitle:
                    'June 21 visit reminders are visible with both push and SMS preview states.',
                meta: 'Customer alerts',
                status: 'Active',
              ),
              DemoListItem(
                title: 'Complaint escalation alert',
                subtitle:
                    'CRM and SHIELD support templates are grouped with actor and destination labels.',
                meta: 'Ops alert',
                status: 'Ready',
              ),
              DemoListItem(
                title: 'Membership approval message',
                subtitle:
                    'Card-issued and activation confirmations are shown in the admin history panel.',
                meta: 'Lifecycle',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              DemoListItem(
                title: 'Template preview saved',
                subtitle:
                    'An updated OTP and reminder copy set was retained for future rollout.',
                meta: 'Template',
                status: 'Saved',
              ),
              DemoListItem(
                title: 'Delivery log inspected',
                subtitle:
                    'Recent notification history was filtered by role and channel for management demo use.',
                meta: 'Audit view',
                status: 'Viewed',
              ),
            ],
            insightItems: const [
              DemoListItem(
                title: 'Cross-role value',
                subtitle:
                    'A notification center ties together login, appointments, approvals, CRM, and wallet actions in one admin lens.',
                meta: 'Platform story',
                status: 'Major',
              ),
              DemoListItem(
                title: 'Design guardrail',
                subtitle:
                    'Delivery history should stay readable through grouped states rather than long undifferentiated timelines.',
                meta: 'UX caution',
                status: 'Important',
              ),
            ],
          ),
        ],
      );
  }
}
