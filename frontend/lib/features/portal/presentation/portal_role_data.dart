import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/shield_role.dart';

class PortalMetric {
  final String label;
  final String value;
  final String note;

  const PortalMetric({
    required this.label,
    required this.value,
    required this.note,
  });

  factory PortalMetric.fromJson(Map<String, dynamic> json) {
    return PortalMetric(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class PortalListItem {
  final String title;
  final String subtitle;
  final String meta;
  final String status;

  const PortalListItem({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  factory PortalListItem.fromJson(Map<String, dynamic> json) {
    return PortalListItem(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      meta: (json['meta'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class PortalSectionData {
  final String key;
  final String title;
  final String summary;
  final List<String> actions;
  final List<PortalMetric> metrics;
  final List<PortalListItem> queueItems;
  final List<PortalListItem> recentItems;
  final List<PortalListItem> insightItems;

  const PortalSectionData({
    required this.key,
    required this.title,
    required this.summary,
    required this.actions,
    required this.metrics,
    required this.queueItems,
    required this.recentItems,
    required this.insightItems,
  });

  factory PortalSectionData.fromJson(Map<String, dynamic> json) {
    return PortalSectionData(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      actions: List<String>.from(json['actions'] ?? []),
      metrics: (json['metrics'] as List? ?? [])
          .map((m) => PortalMetric.fromJson(m as Map<String, dynamic>))
          .toList(),
      queueItems: (json['queueItems'] as List? ?? [])
          .map((q) => PortalListItem.fromJson(q as Map<String, dynamic>))
          .toList(),
      recentItems: (json['recentItems'] as List? ?? [])
          .map((r) => PortalListItem.fromJson(r as Map<String, dynamic>))
          .toList(),
      insightItems: (json['insightItems'] as List? ?? [])
          .map((i) => PortalListItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PortalRoleData {
  final SHIELDRole role;
  final String operatorName;
  final String headline;
  final String regionLabel;
  final IconData icon;
  final Color accentColor;
  final List<PortalSectionData> sections;

  const PortalRoleData({
    required this.role,
    required this.operatorName,
    required this.headline,
    required this.regionLabel,
    required this.icon,
    required this.accentColor,
    required this.sections,
  });

  PortalSectionData get defaultSection => sections.first;

  PortalSectionData sectionFor(String? key) {
    return sections.firstWhere(
      (section) => section.key == key,
      orElse: () => defaultSection,
    );
  }
}

PortalRoleData portalDataForRole(SHIELDRole role) {
  switch (role) {
    case SHIELDRole.customer:
      return PortalRoleData(
        role: role,
        operatorName: 'Nihal Rahman',
        headline: 'Personal healthcare wallet and records at a glance',
        regionLabel: 'Perinthalmanna member cluster',
        icon: Icons.person,
        accentColor: AppColors.shieldBlue,
        sections: [
          PortalSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Track membership, wallet balance, appointments, and recent medical documents from one compact home view.',
            actions: const ['View card', 'Book visit', 'Open wallet'],
            metrics: const [
              PortalMetric(
                label: 'Wallet balance',
                value: '₹5,450',
                note: 'After last pharmacy spend',
              ),
              PortalMetric(
                label: 'Upcoming visits',
                value: '3',
                note: 'Perinthalmanna and Manjeri',
              ),
              PortalMetric(
                label: 'Pending docs',
                value: '2',
                note: 'Awaiting validation',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Membership renewal ready',
                subtitle:
                    'Founding benefits retained for the Malappuram healthcare network.',
                meta: '20 Jun 2026',
                status: 'Open',
              ),
              PortalListItem(
                title: 'Prescription uploaded',
                subtitle:
                    'Hyper Pharmacy Melattur sent a digital prescription for review.',
                meta: '20 Jun 2026, 7:30 PM',
                status: 'Validated',
              ),
              PortalListItem(
                title: 'Appointment reminder',
                subtitle:
                    'Smart Clinic Manjeri consultation is scheduled for Sunday, June 21, 2026 morning.',
                meta: '21 Jun 2026',
                status: 'Confirmed',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Wallet credited',
                subtitle:
                    'Bonus benefit added after preventive care package completion.',
                meta: 'Perinthalmanna',
                status: 'Credit',
              ),
              PortalListItem(
                title: 'Lab report shared',
                subtitle:
                    'CBC and sugar panel are now available in your documents.',
                meta: 'Makkaraparamba',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Dental follow-up planned',
                subtitle:
                    'Scaling review booked for Friday, June 26, 2026 afternoon.',
                meta: 'Melattur',
                status: 'Scheduled',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most used location',
                subtitle:
                    'Perinthalmanna Hyper Pharmacy continues to be the primary visit point.',
                meta: '67% of visits',
                status: 'Insight',
              ),
              PortalListItem(
                title: 'Care pattern',
                subtitle:
                    'Preventive lab and pharmacy usage increased this quarter.',
                meta: 'Quarter trend',
                status: 'Up',
              ),
            ],
          ),
          PortalSectionData(
            key: 'wallet',
            title: 'Wallet',
            summary:
                'Review available balance, recent deductions, recharge requests, and care-linked savings using portal ledger data.',
            actions: const [
              'Raise recharge request',
              'Download statement',
              'View credit note',
            ],
            metrics: const [
              PortalMetric(
                label: 'Available balance',
                value: '₹5,450',
                note: 'Active portal ledger',
              ),
              PortalMetric(
                label: 'Monthly spend',
                value: '₹2,050',
                note: 'Pharmacy + clinic',
              ),
              PortalMetric(
                label: 'Credit facility',
                value: '₹3,000',
                note: 'Manager-approved',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Hyper Pharmacy purchase',
                subtitle:
                    'Family medicines billed to wallet with member discount applied.',
                meta: 'Perinthalmanna',
                status: 'Settled',
              ),
              PortalListItem(
                title: 'Consultation debit',
                subtitle:
                    'General medicine fee posted from Smart Clinic Manjeri.',
                meta: 'Manjeri',
                status: 'Settled',
              ),
              PortalListItem(
                title: 'Preventive camp bonus',
                subtitle:
                    'Wellness camp incentive pushed after attendance confirmation.',
                meta: 'Alanallur',
                status: 'Credit',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Discount captured',
                subtitle:
                    'Founding member pharmacy discount reflected in final amount.',
                meta: '₹180 saved',
                status: 'Applied',
              ),
              PortalListItem(
                title: 'Recharge request draft',
                subtitle:
                    'A manual top-up request is ready for SHIELD executive review.',
                meta: 'Customer initiated',
                status: 'Draft',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best savings location',
                subtitle:
                    'Perinthalmanna and Tirur branches show the strongest recurring discounts.',
                meta: 'Savings map',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Wallet advice',
                subtitle:
                    'Current balance comfortably covers the next two scheduled care events.',
                meta: 'Projection',
                status: 'Healthy',
              ),
            ],
          ),
          PortalSectionData(
            key: 'services',
            title: 'Services',
            summary:
                'Explore and book pharmacy, lab, homecare, and consultations across branches.',
            actions: const ['Order medicine', 'Book test', 'Consult doctor'],
            metrics: const [
              PortalMetric(
                label: 'Active services',
                value: '4',
                note: 'Near your primary branch',
              ),
              PortalMetric(
                label: 'Regular items',
                value: '12',
                note: 'In past invoices',
              ),
              PortalMetric(
                label: 'Upcoming bookings',
                value: '1',
                note: 'Dental consultation',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Pharmacy Refill Ready',
                subtitle: 'Chronic dosage prescription was updated at Perinthalmanna.',
                meta: 'Pharmacy',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Specialist Available Today',
                subtitle: 'Dr. Haneefa P (General Medicine) is available this evening.',
                meta: 'Doctor',
                status: 'Open',
              ),
            ],
            recentItems: const [],
            insightItems: const [],
          ),
          PortalSectionData(
            key: 'appointments',
            title: 'Appointments',
            summary:
                'See all consultations, lab visits, dental slots, and home-visit requests arranged across SHIELD partner locations.',
            actions: const ['Book consultation', 'Reschedule', 'Share slot'],
            metrics: const [
              PortalMetric(
                label: 'Confirmed',
                value: '2',
                note: '21 Jun and 26 Jun',
              ),
              PortalMetric(
                label: 'Pending',
                value: '1',
                note: 'Home visit review',
              ),
              PortalMetric(
                label: 'Completed this month',
                value: '4',
                note: 'Across 3 facilities',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'General medicine review',
                subtitle: 'Dr. Haneefa P will see you at 10:00 AM.',
                meta: 'Manjeri',
                status: '21 Jun 2026',
              ),
              PortalListItem(
                title: 'Dental scaling review',
                subtitle: 'Chair slot reserved for afternoon follow-up.',
                meta: 'Melattur',
                status: '26 Jun 2026',
              ),
              PortalListItem(
                title: 'Home BP check request',
                subtitle:
                    'Nurse allocation pending for Alanallur route coverage.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Lab visit completed',
                subtitle:
                    'CBC sample collected and routed for quick turnaround.',
                meta: 'Tirur',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Appointment reminder sent',
                subtitle: 'Push and SMS reminders delivered successfully.',
                meta: 'System',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Preferred slot',
                subtitle:
                    'Morning visits have the highest completion rate in this profile.',
                meta: 'Behavior trend',
                status: 'Insight',
              ),
              PortalListItem(
                title: 'Travel pattern',
                subtitle:
                    'Perinthalmanna and Manjeri remain the easiest service points for this member.',
                meta: 'Location fit',
                status: 'Strong',
              ),
            ],
          ),
          PortalSectionData(
            key: 'documents',
            title: 'Documents',
            summary:
                'Browse portal prescriptions, lab reports, dental records, and claim-ready files stored in the member timeline.',
            actions: const ['Upload file', 'Filter by type', 'Share PDF'],
            metrics: const [
              PortalMetric(
                label: 'Approved files',
                value: '12',
                note: 'Ready for viewing',
              ),
              PortalMetric(
                label: 'In review',
                value: '2',
                note: 'Manual validation pending',
              ),
              PortalMetric(
                label: 'Providers',
                value: '5',
                note: 'Across the care network',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Prescription PDF',
                subtitle:
                    'Uploaded by Hyper Pharmacy Melattur after evening medicine issue.',
                meta: 'Prescription',
                status: 'Approved',
              ),
              PortalListItem(
                title: 'CBC report',
                subtitle: 'Digital extraction completed with human validation.',
                meta: 'Lab report',
                status: 'Validated',
              ),
              PortalListItem(
                title: 'Dental X-ray',
                subtitle: 'Image received and classified under dental history.',
                meta: 'Dental record',
                status: 'Processing',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Document timeline updated',
                subtitle:
                    'Each file is now grouped by provider and service date.',
                meta: 'UX state',
                status: 'Visible',
              ),
              PortalListItem(
                title: 'OCR fallback used',
                subtitle:
                    'A scanned image from Makkaraparamba required manual review.',
                meta: 'Engine log',
                status: 'Handled',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most frequent type',
                subtitle:
                    'Prescriptions remain the highest-volume customer document category.',
                meta: 'Usage mix',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Retention note',
                subtitle:
                    'All approved portal files are shown as securely retained in the archive.',
                meta: 'Compliance',
                status: 'Good',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Membership type',
                value: 'Founding',
                note: 'Legacy RC member',
              ),
              PortalMetric(
                label: 'Primary branch',
                value: 'Perinthalmanna',
                note: 'Most visits',
              ),
              PortalMetric(
                label: 'Emergency contacts',
                value: '2',
                note: 'Stored in profile',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Address verified',
                subtitle:
                    'Perinthalmanna cluster address marked current for service delivery.',
                meta: 'Profile status',
                status: 'Verified',
              ),
              PortalListItem(
                title: 'Contact preference',
                subtitle:
                    'Push + SMS enabled for appointment and wallet alerts.',
                meta: 'Communication',
                status: 'Active',
              ),
              PortalListItem(
                title: 'Consent profile',
                subtitle:
                    'Document sharing allowed across authorized SHIELD facilities.',
                meta: 'Privacy',
                status: 'Enabled',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Membership card viewed',
                subtitle:
                    'Digital privilege card accessed from profile section.',
                meta: '13-20 Jun 2026',
                status: 'Viewed',
              ),
              PortalListItem(
                title: 'Phone verified',
                subtitle:
                    'OTP-based verification remains valid for the current device.',
                meta: 'Security',
                status: 'Current',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Profile completeness',
                subtitle:
                    'This portal profile shows near-complete medical and contact coverage.',
                meta: '94% complete',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Service fit',
                subtitle:
                    'Nearby pharmacy and clinic access make this member a high-engagement user.',
                meta: 'Retention signal',
                status: 'Positive',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Membership type',
                value: 'Founding Member',
                note: 'Active in June 2026',
              ),
              PortalMetric(
                label: 'Membership ID',
                value: 'SHLD-2026-123456',
                note: 'QR-linked',
              ),
              PortalMetric(
                label: 'Renewal window',
                value: '15 days',
                note: 'Before 1 Jan 2027',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Digital privilege card ready',
                subtitle:
                    'The customer card with QR token is visible for branch verification and pharmacy use.',
                meta: '20 Jun 2026',
                status: 'Active',
              ),
              PortalListItem(
                title: 'Founding benefits visible',
                subtitle:
                    'Legacy member privileges are shown clearly for Perinthalmanna cluster services.',
                meta: 'Benefit pack',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Renewal reminder queued',
                subtitle:
                    'The next membership reminder is prepared ahead of the next cycle.',
                meta: 'Automation',
                status: 'Scheduled',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Approval trail stored',
                subtitle:
                    'Membership activation reason and timestamp were preserved for support and audit visibility.',
                meta: 'History',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Card viewed from profile',
                subtitle:
                    'The member opened the digital privilege card from the app.',
                meta: 'Member action',
                status: 'Viewed',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Key trust signal',
                subtitle:
                    'The membership page is one of the strongest management-portal screens because it combines identity, entitlement, and verification.',
                meta: 'Portal strength',
                status: 'Major',
              ),
              PortalListItem(
                title: 'Design note',
                subtitle:
                    'The privilege card should stay bold and instantly scannable on both mobile and desktop.',
                meta: 'UX priority',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Active prescriptions',
                value: '3',
                note: 'June 2026 set',
              ),
              PortalMetric(
                label: 'Needs validation',
                value: '1',
                note: 'Handwritten upload',
              ),
              PortalMetric(
                label: 'Refill-ready',
                value: '2',
                note: 'Mapped to pharmacy',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Dr. Haneefa refill note',
                subtitle:
                    'Chronic medication refill is ready for Perinthalmanna Hyper Pharmacy issue.',
                meta: '21 Jun 2026',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Melattur handwritten upload',
                subtitle:
                    'The OCR result is available but still needs pharmacist confirmation.',
                meta: 'Upload review',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Expiry warning',
                subtitle:
                    'One previous prescription is shown as expired to prevent reuse at the counter.',
                meta: 'Safety',
                status: 'Blocked',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Medicine mapping done',
                subtitle:
                    'Primary medicine lines were linked to available pharmacy SKUs for smoother branch processing.',
                meta: 'Data linked',
                status: 'Mapped',
              ),
              PortalListItem(
                title: 'Refill history opened',
                subtitle:
                    'The member can review previous refill dates and branch usage.',
                meta: 'History',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best customer utility',
                subtitle:
                    'Prescription visibility reduces repeated manual explanation at pharmacy counters and strengthens confidence in the digital workflow.',
                meta: 'Care continuity',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Operational caveat',
                subtitle:
                    'Handwritten dosage details still deserve obvious validation states in the UI.',
                meta: 'Clarity',
                status: 'Needed',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Draft request',
                value: '₹2,000',
                note: 'Prepared on 20 Jun 2026',
              ),
              PortalMetric(
                label: 'Promo credits this month',
                value: '₹650',
                note: 'Camp + referral benefits',
              ),
              PortalMetric(
                label: 'Average approval time',
                value: '18 min',
                note: 'Branch-assisted portal',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Manual top-up request',
                subtitle:
                    'A wallet recharge request is ready for SHIELD executive review after branch cash collection.',
                meta: 'Melattur',
                status: 'Draft',
              ),
              PortalListItem(
                title: 'Promotional credit visible',
                subtitle:
                    'Wellness camp bonus and pharmacy loyalty credits are grouped clearly in the recharge view.',
                meta: 'June 2026',
                status: 'Shown',
              ),
              PortalListItem(
                title: 'Recharge instruction card',
                subtitle:
                    'The customer can see the branch-assisted flow before submitting a recharge request.',
                meta: 'Help panel',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Previous top-up settled',
                subtitle:
                    'An earlier Perinthalmanna recharge was completed and moved into ledger history.',
                meta: 'History',
                status: 'Settled',
              ),
              PortalListItem(
                title: 'Notification sent',
                subtitle:
                    'Recharge acknowledgement was delivered to the member immediately after request creation.',
                meta: 'Alert',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Explainer value',
                subtitle:
                    'Recharge pages make the ledger-based wallet feel tangible to non-technical reviewers.',
                meta: 'Management story',
                status: 'Helpful',
              ),
              PortalListItem(
                title: 'Future integration fit',
                subtitle:
                    'The current dummy screen leaves space for online payment methods later without changing the core layout.',
                meta: 'Scalable',
                status: 'Good',
              ),
            ],
          ),
          PortalSectionData(
            key: 'book-appointment',
            title: 'Book Appointment',
            summary:
                'Guide the member through branch, service, doctor, and slot selection for clinic, dental, and home-visit bookings.',
            actions: const ['Choose branch', 'Pick doctor', 'Confirm slot'],
            metrics: const [
              PortalMetric(
                label: 'Suggested slots',
                value: '6',
                note: '21-26 Jun 2026',
              ),
              PortalMetric(
                label: 'Branches',
                value: '4',
                note: 'Clinic + dental + home care',
              ),
              PortalMetric(
                label: 'Fastest branch',
                value: 'Perinthalmanna',
                note: 'Most options available',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'General medicine slot',
                subtitle:
                    'Sunday, June 21, 2026 at 10:00 AM is shown as the fastest available doctor review.',
                meta: 'Manjeri',
                status: 'Suggested',
              ),
              PortalListItem(
                title: 'Dental recall slot',
                subtitle:
                    'Friday, June 26, 2026 afternoon remains open for preventive review.',
                meta: 'Melattur',
                status: 'Open',
              ),
              PortalListItem(
                title: 'Home visit route check',
                subtitle:
                    'Alanallur nurse coverage is shown with route-planning note before final confirmation.',
                meta: 'Home care',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Booking draft retained',
                subtitle:
                    'The member can leave and return without losing the selected branch and service.',
                meta: 'UX state',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Reminder preview shown',
                subtitle:
                    'Push and SMS reminders are previewed before booking confirmation.',
                meta: 'Communication',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Workflow payoff',
                subtitle:
                    'Booking screens help tie membership, service access, and notifications into one clear story for management.',
                meta: 'Cross-module value',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Design principle',
                subtitle:
                    'Booking should always show branch, service, and next reminder in one glanceable summary.',
                meta: 'UX guide',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'settings',
            title: 'Settings',
            summary:
                'Manage profile preferences, alert channels, privacy choices, and app-level display behavior for the customer portal.',
            actions: const [
              'Edit preferences',
              'Notification channels',
              'Privacy controls',
            ],
            metrics: const [
              PortalMetric(
                label: 'Push alerts',
                value: 'Enabled',
                note: 'Wallet + appointment',
              ),
              PortalMetric(
                label: 'SMS alerts',
                value: 'Enabled',
                note: 'OTP + reminders',
              ),
              PortalMetric(
                label: 'Consent profile',
                value: 'Shared care',
                note: 'Authorized providers only',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Notification preference',
                subtitle:
                    'Appointment and wallet alerts remain enabled for June 2026 activity tracking.',
                meta: 'Alerts',
                status: 'On',
              ),
              PortalListItem(
                title: 'Document sharing consent',
                subtitle:
                    'The member allows approved SHIELD providers to view validated reports and prescriptions.',
                meta: 'Privacy',
                status: 'Enabled',
              ),
              PortalListItem(
                title: 'Language preference',
                subtitle:
                    'English-first portal copy is active with room for Malayalam support later.',
                meta: 'Accessibility',
                status: 'Configured',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'OTP device remembered',
                subtitle:
                    'The current device remains verified for this portal session.',
                meta: 'Security',
                status: 'Current',
              ),
              PortalListItem(
                title: 'Settings preview saved',
                subtitle:
                    'Preference changes were retained without touching backend integrations.',
                meta: 'Portal mode',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Trust factor',
                subtitle:
                    'A settings page completes the feeling that the customer app is a real product, not only a dashboard mockup.',
                meta: 'Product polish',
                status: 'Important',
              ),
              PortalListItem(
                title: 'Future-proofing',
                subtitle:
                    'These controls can later map directly to notification, privacy, and device APIs without redesigning the screen.',
                meta: 'Scalable',
                status: 'Positive',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(label: 'Unread', value: '4', note: 'Actionable now'),
              PortalMetric(
                label: 'This week',
                value: '17',
                note: 'Across all channels',
              ),
              PortalMetric(
                label: 'Delivery success',
                value: '98%',
                note: 'Push + SMS',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Appointment on 21 Jun 2026',
                subtitle:
                    'Reminder sent for Smart Clinic Manjeri morning consultation.',
                meta: 'Push + SMS',
                status: 'Unread',
              ),
              PortalListItem(
                title: 'Wallet credit posted',
                subtitle: 'Preventive-care bonus added after camp completion.',
                meta: 'Wallet',
                status: 'Unread',
              ),
              PortalListItem(
                title: 'Report available',
                subtitle: 'CBC report is ready to open from the documents tab.',
                meta: 'Lab report',
                status: 'Unread',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Membership renewal notice',
                subtitle:
                    'Founding member benefits were auto-carried into the new cycle.',
                meta: 'Membership',
                status: 'Read',
              ),
              PortalListItem(
                title: 'Document approved',
                subtitle: 'Prescription validation completed successfully.',
                meta: 'Documents',
                status: 'Read',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best channel',
                subtitle:
                    'Push notifications outperform SMS for same-day healthcare actions.',
                meta: 'Engagement trend',
                status: 'Top',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Jaseem K',
        headline:
            'Front-counter pharmacy operations across the hyper pharmacy network',
        regionLabel: 'Perinthalmanna, Melattur, Tirur branches',
        icon: Icons.local_pharmacy,
        accentColor: AppColors.shieldGreen,
        sections: [
          PortalSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Monitor queue load, customer verification traffic, bill uploads, and pharmacy transaction throughput across branch counters.',
            actions: const ['Open counter', 'Verify customer', 'Upload bill'],
            metrics: const [
              PortalMetric(
                label: 'Customers today',
                value: '48',
                note: 'Across 3 counters',
              ),
              PortalMetric(
                label: 'Bills uploaded',
                value: '26',
                note: 'Extraction-ready',
              ),
              PortalMetric(
                label: 'Verification success',
                value: '96%',
                note: 'QR + OTP',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Counter queue building',
                subtitle:
                    'Five SHIELD members are waiting for verification at Counter 2.',
                meta: 'Perinthalmanna',
                status: 'Live',
              ),
              PortalListItem(
                title: 'Prescription image review',
                subtitle:
                    'One scanned prescription needs manual approval before sale.',
                meta: 'Melattur',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Stock-linked discount check',
                subtitle:
                    'Wallet discount calculation needs override for one senior member.',
                meta: 'Tirur',
                status: 'Attention',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Successful bill extraction',
                subtitle:
                    'Medicine line items parsed and matched to product masters.',
                meta: 'Hyper Pharmacy',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Wallet deduction posted',
                subtitle:
                    'Member purchase was settled directly from SHIELD balance.',
                meta: 'Counter 4',
                status: 'Settled',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Peak hour',
                subtitle:
                    '11 AM to 1 PM remains the heaviest verification window.',
                meta: 'Ops trend',
                status: 'Peak',
              ),
              PortalListItem(
                title: 'Most active branch',
                subtitle:
                    'Perinthalmanna is handling the largest SHIELD member volume today.',
                meta: 'Branch ranking',
                status: 'Top',
              ),
            ],
          ),
          PortalSectionData(
            key: 'customers',
            title: 'Customer Search',
            summary:
                'Search members by mobile, QR, or membership number before processing pharmacy transactions.',
            actions: const ['QR lookup', 'Search by mobile', 'Open profile'],
            metrics: const [
              PortalMetric(
                label: 'Searches today',
                value: '61',
                note: 'Fast member lookup',
              ),
              PortalMetric(
                label: 'New walk-ins',
                value: '9',
                note: 'Potential conversions',
              ),
              PortalMetric(
                label: 'Repeat members',
                value: '37',
                note: 'Known profiles',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Founding member profile with active wallet and two pending prescriptions.',
                meta: 'Perinthalmanna',
                status: 'Active',
              ),
              PortalListItem(
                title: 'Fathima Sherin',
                subtitle:
                    'Member prefers Melattur branch and has one approval pending.',
                meta: 'Melattur',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Shanib K',
                subtitle:
                    'Profile exists but membership activation is not complete yet.',
                meta: 'Manjeri',
                status: 'Hold',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Search latency stable',
                subtitle:
                    'All portal customer lookups are rendering under the expected UI budget.',
                meta: 'UX check',
                status: 'Good',
              ),
              PortalListItem(
                title: 'QR fallback used',
                subtitle: 'Manual mobile search handled a damaged card scan.',
                meta: 'Counter 1',
                status: 'Handled',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best identifier',
                subtitle:
                    'Mobile lookup is still the fastest working flow for front-counter staff.',
                meta: 'Workflow',
                status: 'Preferred',
              ),
              PortalListItem(
                title: 'Missed opportunity',
                subtitle:
                    'Pending members should be routed to SHIELD executive follow-up from this page.',
                meta: 'Conversion',
                status: 'Flagged',
              ),
            ],
          ),
          PortalSectionData(
            key: 'verification',
            title: 'Verification',
            summary:
                'Handle QR scans, OTP verification, membership checks, and counter-level eligibility confirmation.',
            actions: const ['Scan QR', 'Send OTP', 'Escalate issue'],
            metrics: const [
              PortalMetric(label: 'QR scans', value: '22', note: 'Today'),
              PortalMetric(
                label: 'OTP requests',
                value: '18',
                note: 'Phone fallback',
              ),
              PortalMetric(
                label: 'Failed verifications',
                value: '2',
                note: 'Manual check needed',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'QR mismatch',
                subtitle: 'Card token mismatch needs customer identity review.',
                meta: 'Counter 3',
                status: 'Escalated',
              ),
              PortalListItem(
                title: 'OTP delivered',
                subtitle:
                    'Verification code sent successfully to a founding member.',
                meta: 'Melattur',
                status: 'Waiting',
              ),
              PortalListItem(
                title: 'Membership cross-check',
                subtitle: 'One inactive membership was flagged before billing.',
                meta: 'Tirur',
                status: 'Protected',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Identity confirmed',
                subtitle:
                    'Photo-free OTP verification completed without delay.',
                meta: 'Perinthalmanna',
                status: 'Passed',
              ),
              PortalListItem(
                title: 'Counter note saved',
                subtitle:
                    'Staff note attached for a repeat verification exception.',
                meta: 'Audit trail',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Verification quality',
                subtitle:
                    'OTP fallback is reliable, but QR adoption is growing fastest in repeat members.',
                meta: 'Adoption trend',
                status: 'Up',
              ),
              PortalListItem(
                title: 'Risk note',
                subtitle:
                    'Manual review flows should stay visible when wallet-linked discounts are applied.',
                meta: 'Control',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'bills',
            title: 'Bill Uploads',
            summary:
                'Manage pharmacy bill intake, extraction review, item validation, and invoice finalization using dummy records.',
            actions: const ['Upload PDF', 'Review extraction', 'Post purchase'],
            metrics: const [
              PortalMetric(
                label: 'Uploads pending',
                value: '6',
                note: 'Awaiting review',
              ),
              PortalMetric(label: 'Auto-classified', value: '19', note: 'Today'),
              PortalMetric(
                label: 'Line items parsed',
                value: '148',
                note: 'Portal dataset',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Invoice PMNA-447',
                subtitle:
                    'Medicine list extracted from PDF and discount matched to member plan.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Invoice MTR-118',
                subtitle:
                    'One product code needs manual correction before posting.',
                meta: 'Melattur',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Invoice TRR-067',
                subtitle:
                    'Scanned file required OCR fallback for accurate totals.',
                meta: 'Tirur',
                status: 'Validated',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Original file retained',
                subtitle:
                    'Archive copy stored alongside extracted data for audit completeness.',
                meta: 'Compliance',
                status: 'Stored',
              ),
              PortalListItem(
                title: 'Posting completed',
                subtitle:
                    'Bill moved into purchase history with wallet settlement details.',
                meta: 'Sales flow',
                status: 'Done',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'File quality',
                subtitle:
                    'Digital PDFs continue to outperform scanned images for speed and accuracy.',
                meta: 'Extraction signal',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Operator note',
                subtitle:
                    'Bills with combo packs need clearer UI grouping in a later integration phase.',
                meta: 'UX note',
                status: 'Noted',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Active prescriptions',
                value: '14',
                note: 'Today',
              ),
              PortalMetric(
                label: 'Needs review',
                value: '3',
                note: 'Low-confidence files',
              ),
              PortalMetric(
                label: 'Linked sales',
                value: '11',
                note: 'Matched to bills',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Dr. Haneefa prescription',
                subtitle:
                    'Valid for chronic medication refill with one substitute note.',
                meta: 'Manjeri',
                status: 'Approved',
              ),
              PortalListItem(
                title: 'Scanned handwritten note',
                subtitle:
                    'OCR result requires pharmacist validation before issue.',
                meta: 'Alanallur',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Repeat refill check',
                subtitle:
                    'Previous prescription linked to current wallet deduction flow.',
                meta: 'Perinthalmanna',
                status: 'Mapped',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Drug mapping completed',
                subtitle: 'Primary medicines linked to available product SKUs.',
                meta: 'Inventory tie-in',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Expiry enforced',
                subtitle:
                    'One outdated prescription was blocked from processing.',
                meta: 'Control',
                status: 'Blocked',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most common issue',
                subtitle:
                    'Handwritten dosage lines remain the main source of manual review.',
                meta: 'Quality insight',
                status: 'Common',
              ),
              PortalListItem(
                title: 'Speed gain',
                subtitle:
                    'Digital prescriptions from Manjeri clinic move through the cleanest workflow.',
                meta: 'Best path',
                status: 'Fast',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Scans today',
                value: '22',
                note: '20 Jun 2026',
              ),
              PortalMetric(
                label: 'Fallback lookups',
                value: '6',
                note: 'Membership number',
              ),
              PortalMetric(
                label: 'Success rate',
                value: '95%',
                note: 'Counter average',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Card scan ready',
                subtitle:
                    'Camera scan flow is presented with a clean overlay for member verification.',
                meta: 'Counter 2',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Membership ID fallback',
                subtitle:
                    'A damaged QR card can still be verified through manual membership number entry.',
                meta: 'Fallback',
                status: 'Available',
              ),
              PortalListItem(
                title: 'Verification proof panel',
                subtitle:
                    'The staff can view branch, wallet eligibility, and membership status side by side after a scan.',
                meta: 'Review',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Duplicate retry handled',
                subtitle:
                    'One repeat scan was merged into a single counter event for audit clarity.',
                meta: 'Scanner log',
                status: 'Cleaned',
              ),
              PortalListItem(
                title: 'Manual entry completed',
                subtitle:
                    'A Melattur member was verified using membership number after a blurred QR read.',
                meta: 'Melattur',
                status: 'Verified',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Doc alignment',
                subtitle:
                    'An explicit QR page closes one of the clearest UI-spec gaps for the pharmacy role.',
                meta: 'Spec coverage',
                status: 'Closed',
              ),
              PortalListItem(
                title: 'UX rule',
                subtitle:
                    'Manual membership-number entry should always stay on the same screen as camera scan fallback.',
                meta: 'Design note',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Shift transactions',
                value: '84',
                note: 'Current day',
              ),
              PortalMetric(
                label: 'Average bill',
                value: '₹842',
                note: 'Member transactions',
              ),
              PortalMetric(
                label: 'Manual interventions',
                value: '7',
                note: 'Review cases',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Counter 2 performance',
                subtitle:
                    'High throughput with clean document completion ratio.',
                meta: 'Perinthalmanna',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Evening rush review',
                subtitle:
                    'Melattur branch saw the highest post-6 PM member inflow.',
                meta: 'Shift note',
                status: 'Observed',
              ),
              PortalListItem(
                title: 'Tirur exception log',
                subtitle:
                    'Two verification delays recorded for network retry follow-up.',
                meta: 'Ops issue',
                status: 'Tracked',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Operator summary saved',
                subtitle: 'Daily wrap-up exported for management review.',
                meta: 'End of day',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Promo usage spike',
                subtitle:
                    'Preventive-care voucher redemptions increased in the last week.',
                meta: 'Campaign impact',
                status: 'Up',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best repeat conversion',
                subtitle:
                    'Perinthalmanna branch leads in return visits within 30 days.',
                meta: 'Retention insight',
                status: 'Top',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Dr. Faseela',
        headline:
            'Clinic-side patient coordination, consultations, and reports in one care console',
        regionLabel: 'Manjeri and Perinthalmanna smart clinic network',
        icon: Icons.local_hospital,
        accentColor: AppColors.info,
        sections: [
          PortalSectionData(
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
              PortalMetric(
                label: 'Patients today',
                value: '32',
                note: 'Booked + walk-in',
              ),
              PortalMetric(
                label: 'Consultations done',
                value: '18',
                note: 'Morning shift',
              ),
              PortalMetric(
                label: 'Reports pending',
                value: '6',
                note: 'Awaiting upload',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Morning OP queue',
                subtitle:
                    'Seven SHIELD members are waiting for general medicine review.',
                meta: 'Manjeri',
                status: 'Live',
              ),
              PortalListItem(
                title: 'Report upload backlog',
                subtitle:
                    'Three lab files still need validation before member release.',
                meta: 'Perinthalmanna',
                status: 'Attention',
              ),
              PortalListItem(
                title: 'Home visit request',
                subtitle: 'Care coordinator asked for same-day triage review.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Consultation completed',
                subtitle: 'Diagnosis and care note posted to patient timeline.',
                meta: 'Dr. Haneefa P',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Document shared',
                subtitle:
                    'PDF report pushed to member documents after doctor approval.',
                meta: 'Clinic flow',
                status: 'Shared',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Peak load',
                subtitle:
                    'Mid-morning remains the busiest period for SHIELD patient arrivals.',
                meta: 'Clinic trend',
                status: 'Peak',
              ),
              PortalListItem(
                title: 'Fastest workflow',
                subtitle:
                    'Digital report uploads from Perinthalmanna clear faster than scanned ones.',
                meta: 'Quality signal',
                status: 'Better',
              ),
            ],
          ),
          PortalSectionData(
            key: 'patients',
            title: 'Patient Records',
            summary:
                'Access member histories, visit reasons, medication context, and recent documents before clinical review.',
            actions: const ['Search patient', 'Open timeline', 'Add note'],
            metrics: const [
              PortalMetric(
                label: 'Active follow-ups',
                value: '14',
                note: 'This week',
              ),
              PortalMetric(
                label: 'New patients',
                value: '5',
                note: 'Needing onboarding',
              ),
              PortalMetric(
                label: 'History complete',
                value: '89%',
                note: 'Records linked',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Chronic medication follow-up with pharmacy and lab history linked.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Fathima Sherin',
                subtitle:
                    'Recurrent headache review with one recent CBC report attached.',
                meta: 'Melattur',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Shanib K',
                subtitle:
                    'Pending membership activation but clinically visible for triage notes.',
                meta: 'Manjeri',
                status: 'Limited',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Timeline merged',
                subtitle:
                    'Previous pharmacy purchases now visible beside consultation history.',
                meta: 'Data view',
                status: 'Linked',
              ),
              PortalListItem(
                title: 'Clinical note saved',
                subtitle: 'Staff note added ahead of the doctor review.',
                meta: 'Preparation',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most useful context',
                subtitle:
                    'Recent prescriptions and wallet-assisted pharmacy history help speed reviews.',
                meta: 'Clinical workflow',
                status: 'Helpful',
              ),
              PortalListItem(
                title: 'Gap to fill',
                subtitle:
                    'Home visit outcomes should surface more prominently in future detail views.',
                meta: 'UX gap',
                status: 'Noted',
              ),
            ],
          ),
          PortalSectionData(
            key: 'appointments',
            title: 'Appointments',
            summary:
                'Manage clinic slots, doctor schedules, follow-up bookings, and no-show recovery from a single scheduling view.',
            actions: const ['Create slot', 'Confirm visit', 'Mark no-show'],
            metrics: const [
              PortalMetric(label: 'Today’s slots', value: '27', note: 'Booked'),
              PortalMetric(
                label: 'Follow-ups due',
                value: '8',
                note: 'This week',
              ),
              PortalMetric(
                label: 'No-show risk',
                value: '3',
                note: 'Need reminder',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'General medicine queue',
                subtitle: 'Back-to-back consultations lined up through noon.',
                meta: 'Manjeri',
                status: 'On time',
              ),
              PortalListItem(
                title: 'Diabetes follow-up',
                subtitle:
                    'Member requested shift from Tirur to Perinthalmanna branch.',
                meta: 'Reschedule',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Home care assessment',
                subtitle:
                    'Travel route validation needed before slot confirmation.',
                meta: 'Alanallur',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Reminder sent',
                subtitle:
                    'Push and SMS were triggered for June 21\'s first three visits.',
                meta: 'Automation',
                status: 'Sent',
              ),
              PortalListItem(
                title: 'Consultation closed',
                subtitle: 'Completed appointment moved into patient history.',
                meta: 'Workflow',
                status: 'Done',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most punctual branch',
                subtitle:
                    'Perinthalmanna has the strongest same-day attendance pattern.',
                meta: 'Ops metric',
                status: 'Best',
              ),
              PortalListItem(
                title: 'Reminder impact',
                subtitle:
                    'The second reminder one hour before visit appears to reduce no-shows.',
                meta: 'Engagement',
                status: 'Useful',
              ),
            ],
          ),
          PortalSectionData(
            key: 'consultations',
            title: 'Consultations',
            summary:
                'Capture diagnosis, doctor notes, treatment guidance, and linked prescriptions using a doctor-friendly portal page.',
            actions: const [
              'Start note',
              'Save diagnosis',
              'Issue prescription',
            ],
            metrics: const [
              PortalMetric(
                label: 'Consult notes today',
                value: '18',
                note: 'Saved',
              ),
              PortalMetric(
                label: 'Prescriptions issued',
                value: '11',
                note: 'Same-day',
              ),
              PortalMetric(
                label: 'Escalated cases',
                value: '2',
                note: 'Need specialist',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Chronic care review',
                subtitle:
                    'Blood pressure and sugar follow-up with medicine refill advice.',
                meta: 'Perinthalmanna',
                status: 'In progress',
              ),
              PortalListItem(
                title: 'Acute fever case',
                subtitle:
                    'Short consultation note awaiting final diagnosis entry.',
                meta: 'Manjeri',
                status: 'Draft',
              ),
              PortalListItem(
                title: 'Referral note',
                subtitle:
                    'Patient flagged for advanced imaging outside the current clinic scope.',
                meta: 'Escalation',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Prescription linked',
                subtitle:
                    'Issued medicine list is visible to pharmacy-side staff immediately.',
                meta: 'Integrated portal',
                status: 'Linked',
              ),
              PortalListItem(
                title: 'Doctor note approved',
                subtitle: 'Clinical summary published to member timeline.',
                meta: 'Patient view',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Note quality',
                subtitle:
                    'Structured diagnosis fields make the follow-up workflow cleaner for staff.',
                meta: 'Usability',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Future improvement',
                subtitle:
                    'Template-based care plans would speed repeated chronic care consultations.',
                meta: 'Enhancement',
                status: 'Candidate',
              ),
            ],
          ),
          PortalSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Upload and validate lab or consultation reports before releasing them to the patient document timeline.',
            actions: const ['Upload PDF', 'Review OCR', 'Approve release'],
            metrics: const [
              PortalMetric(
                label: 'Reports today',
                value: '13',
                note: 'Queued or released',
              ),
              PortalMetric(
                label: 'OCR fallback',
                value: '3',
                note: 'Scanned uploads',
              ),
              PortalMetric(
                label: 'Released to members',
                value: '9',
                note: 'Approved',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'CBC report upload',
                subtitle:
                    'Digital PDF extracted cleanly with confidence above threshold.',
                meta: 'Tirur',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Scanned consultation summary',
                subtitle:
                    'Needs manual field confirmation before archive release.',
                meta: 'Manjeri',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Home visit report',
                subtitle:
                    'Nurse notes converted to a member-readable PDF bundle.',
                meta: 'Alanallur',
                status: 'Prepared',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Member notified',
                subtitle:
                    'Push alert sent after doctor approval of lab results.',
                meta: 'Notification',
                status: 'Sent',
              ),
              PortalListItem(
                title: 'Processing log saved',
                subtitle:
                    'Stage-wise document trail captured for audit visibility.',
                meta: 'Audit',
                status: 'Stored',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Turnaround leader',
                subtitle:
                    'Structured digital lab reports clear fastest for member release.',
                meta: 'Speed insight',
                status: 'Fast',
              ),
              PortalListItem(
                title: 'Validation hotspot',
                subtitle:
                    'Scanned consultation summaries remain the most error-prone report type.',
                meta: 'Quality insight',
                status: 'Attention',
              ),
            ],
          ),
          PortalSectionData(
            key: 'home-visits',
            title: 'Home Visits',
            summary:
                'Schedule, assign, and document home-visit care for members who need clinical services near home.',
            actions: const ['Create visit', 'Assign staff', 'Close visit'],
            metrics: const [
              PortalMetric(label: 'Requested', value: '4', note: 'This week'),
              PortalMetric(label: 'Assigned', value: '3', note: 'Route planned'),
              PortalMetric(label: 'Completed', value: '9', note: 'Month to date'),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Alanallur BP follow-up',
                subtitle:
                    'Nurse assignment pending due to route bundling with another case.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Makkaraparamba post-discharge review',
                subtitle:
                    'Doctor wants an at-home check after recent clinic visit.',
                meta: 'Makkaraparamba',
                status: 'Assigned',
              ),
              PortalListItem(
                title: 'Tirur elder care visit',
                subtitle:
                    'Medication adherence check scheduled with caregiver present.',
                meta: 'Tirur',
                status: 'Confirmed',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Visit note uploaded',
                subtitle:
                    'Home visit outcome pushed to patient timeline and care history.',
                meta: 'Field team',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Travel bundle optimized',
                subtitle: 'Two nearby visits grouped into one route plan.',
                meta: 'Ops support',
                status: 'Optimized',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'High-value service',
                subtitle:
                    'Home visits appear to reduce missed follow-ups in rural pockets.',
                meta: 'Retention effect',
                status: 'Positive',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Dr. Asna Basheer',
        headline:
            'Dental workflow for appointments, procedures, reports, and treatment continuity',
        regionLabel: 'Melattur and Perinthalmanna dental care desks',
        icon: Icons.medical_services,
        accentColor: AppColors.warning,
        sections: [
          PortalSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Review chair utilization, treatment queue, pending reports, and repeat dental follow-ups from one view.',
            actions: const ['Open chair queue', 'Add treatment', 'Upload scan'],
            metrics: const [
              PortalMetric(
                label: 'Patients today',
                value: '19',
                note: 'Scheduled + urgent',
              ),
              PortalMetric(
                label: 'Procedures done',
                value: '11',
                note: 'Current shift',
              ),
              PortalMetric(
                label: 'Follow-ups due',
                value: '5',
                note: 'Within 7 days',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Scaling follow-up queue',
                subtitle:
                    'Three members waiting with prior digital history attached.',
                meta: 'Melattur',
                status: 'Live',
              ),
              PortalListItem(
                title: 'X-ray review pending',
                subtitle:
                    'Uploaded image needs dentist sign-off before member release.',
                meta: 'Perinthalmanna',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Crown treatment plan',
                subtitle:
                    'Cost and stage plan to be explained after consultation.',
                meta: 'Manjeri referral',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Treatment note saved',
                subtitle:
                    'Procedure detail posted to the member’s dental history.',
                meta: 'Chair 2',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Recall reminder queued',
                subtitle:
                    'Routine check reminder prepared for three-month outreach.',
                meta: 'CRM bridge',
                status: 'Queued',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Chair efficiency',
                subtitle:
                    'Morning slots are performing with the highest on-time start rate.',
                meta: 'Ops insight',
                status: 'Good',
              ),
              PortalListItem(
                title: 'Return pattern',
                subtitle:
                    'Members from Perinthalmanna show the strongest repeat preventive visits.',
                meta: 'Retention signal',
                status: 'High',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Open cases',
                value: '23',
                note: 'Tracked plans',
              ),
              PortalMetric(label: 'Image sets', value: '17', note: 'Accessible'),
              PortalMetric(
                label: 'Treatment plans',
                value: '8',
                note: 'In progress',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Fathima Sherin',
                subtitle:
                    'Scaling complete, review due with photos and notes attached.',
                meta: 'Melattur',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Tooth sensitivity follow-up with medicine history available.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Shanib K',
                subtitle:
                    'Pending membership but emergency dental note allowed for triage.',
                meta: 'Manjeri',
                status: 'Limited',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'X-ray linked',
                subtitle:
                    'Imaging now sits beside treatment notes for easier review.',
                meta: 'Dental record',
                status: 'Linked',
              ),
              PortalListItem(
                title: 'Plan updated',
                subtitle:
                    'Two-stage treatment estimate revised after clinical review.',
                meta: 'Case note',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'History usefulness',
                subtitle:
                    'Procedure photos improve continuity more than plain text notes alone.',
                meta: 'Clinical UX',
                status: 'Helpful',
              ),
              PortalListItem(
                title: 'Data gap',
                subtitle:
                    'Billing-ready dental package summaries would strengthen management portal depth.',
                meta: 'Opportunity',
                status: 'Future',
              ),
            ],
          ),
          PortalSectionData(
            key: 'appointments',
            title: 'Appointments',
            summary:
                'Coordinate chair schedules, procedure durations, review slots, and repeat care reminders for dental patients.',
            actions: const ['Add slot', 'Reschedule chair', 'Confirm review'],
            metrics: const [
              PortalMetric(label: 'Chair bookings', value: '16', note: 'Today'),
              PortalMetric(label: 'Delayed starts', value: '1', note: 'Minor'),
              PortalMetric(
                label: 'Recall bookings',
                value: '6',
                note: 'This week',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Scaling review',
                subtitle: 'Short slot blocked for afternoon follow-up.',
                meta: 'Melattur',
                status: 'Confirmed',
              ),
              PortalListItem(
                title: 'Filling consultation',
                subtitle: 'Patient requested a later chair after work hours.',
                meta: 'Perinthalmanna',
                status: 'Reschedule',
              ),
              PortalListItem(
                title: 'Treatment plan discussion',
                subtitle:
                    'Case review appointment reserved for family counseling.',
                meta: 'Manjeri',
                status: 'Booked',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Chair schedule synced',
                subtitle:
                    'Reception and dentist views now reflect the same sequence.',
                meta: 'Desk flow',
                status: 'Aligned',
              ),
              PortalListItem(
                title: 'Reminder sent',
                subtitle:
                    'Upcoming review patients received push notifications.',
                meta: 'Notification',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best slot length',
                subtitle:
                    'Twenty-minute reviews create the cleanest utilization pattern.',
                meta: 'Scheduling insight',
                status: 'Optimal',
              ),
              PortalListItem(
                title: 'No-show reduction',
                subtitle:
                    'Recall reminders are helping members return for preventive checkups.',
                meta: 'Care continuity',
                status: 'Working',
              ),
            ],
          ),
          PortalSectionData(
            key: 'treatments',
            title: 'Treatments',
            summary:
                'Record procedures, materials, dentist notes, and chair-side outcomes with a clean treatment workflow.',
            actions: const ['Create procedure', 'Save notes', 'Link report'],
            metrics: const [
              PortalMetric(
                label: 'Procedures today',
                value: '11',
                note: 'Captured',
              ),
              PortalMetric(label: 'Treatment plans', value: '8', note: 'Active'),
              PortalMetric(
                label: 'Urgent cases',
                value: '2',
                note: 'Same-day care',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Scaling and polishing',
                subtitle:
                    'Completed with instructions posted to after-care notes.',
                meta: 'Melattur',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Filling recommendation',
                subtitle:
                    'Procedure suggested after cavity review; plan awaiting acceptance.',
                meta: 'Perinthalmanna',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Sensitivity case',
                subtitle:
                    'Observation note saved with medicine and revisit advice.',
                meta: 'Alanallur',
                status: 'Tracked',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Treatment stage updated',
                subtitle: 'Case advanced from diagnosis to approved plan.',
                meta: 'Case flow',
                status: 'Updated',
              ),
              PortalListItem(
                title: 'Post-care note shared',
                subtitle:
                    'Member can review home-care advice from the documents section.',
                meta: 'Patient handoff',
                status: 'Visible',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Procedure mix',
                subtitle:
                    'Preventive visits are still the biggest volume driver in the portal.',
                meta: 'Case mix',
                status: 'Majority',
              ),
              PortalListItem(
                title: 'Future add-on',
                subtitle:
                    'A chair-material usage panel would enrich the operational story later.',
                meta: 'Enhancement',
                status: 'Idea',
              ),
            ],
          ),
          PortalSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Handle dental images, scan uploads, procedure PDFs, and release-ready records for member history.',
            actions: const ['Upload image', 'Approve record', 'Archive report'],
            metrics: const [
              PortalMetric(label: 'Files uploaded', value: '9', note: 'Today'),
              PortalMetric(
                label: 'Images processing',
                value: '2',
                note: 'Classification running',
              ),
              PortalMetric(label: 'Released', value: '6', note: 'Member-visible'),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Dental X-ray image',
                subtitle:
                    'Classified and mapped to treatment history after upload.',
                meta: 'Perinthalmanna',
                status: 'Validated',
              ),
              PortalListItem(
                title: 'Procedure summary PDF',
                subtitle: 'Ready to release after dentist note review.',
                meta: 'Melattur',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Scanned estimate sheet',
                subtitle: 'OCR confidence low, manual check requested.',
                meta: 'Manjeri',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Archive copy retained',
                subtitle:
                    'Original file kept alongside structured extraction data.',
                meta: 'Compliance',
                status: 'Stored',
              ),
              PortalListItem(
                title: 'Member alert queued',
                subtitle:
                    'Notification prepared for approved dental image release.',
                meta: 'Comms',
                status: 'Queued',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Image quality signal',
                subtitle:
                    'Direct digital uploads from the chairside device perform best.',
                meta: 'Workflow insight',
                status: 'Best',
              ),
              PortalListItem(
                title: 'Friction point',
                subtitle:
                    'Paper estimates need a cleaner upload path in the next phase.',
                meta: 'Process gap',
                status: 'Visible',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Completed plans',
                value: '21',
                note: 'Quarter to date',
              ),
              PortalMetric(
                label: 'Repeat preventive visits',
                value: '12',
                note: 'High retention',
              ),
              PortalMetric(
                label: 'Pending reviews',
                value: '4',
                note: 'Next 10 days',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Three-month recall cohort',
                subtitle:
                    'Members due for preventive review are lined up for outreach.',
                meta: 'CRM feed',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Completed treatment summary',
                subtitle:
                    'A full case timeline is visible for management portal review.',
                meta: 'Perinthalmanna',
                status: 'Compiled',
              ),
              PortalListItem(
                title: 'Open continuity gap',
                subtitle:
                    'One referred patient has not returned after first consultation.',
                meta: 'Melattur',
                status: 'Follow-up',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'History export generated',
                subtitle:
                    'Portal treatment history rendered as a shareable PDF summary.',
                meta: 'Export',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Retention insight updated',
                subtitle:
                    'Preventive-care revisits continue to improve in the active cluster.',
                meta: 'Trend',
                status: 'Positive',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most loyal location',
                subtitle:
                    'Perinthalmanna members show the best preventive revisit cadence.',
                meta: 'Retention leader',
                status: 'Top',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Safna M',
        headline:
            'Relationship management for follow-ups, complaints, tasks, and member retention',
        regionLabel: 'Malappuram SHIELD customer engagement desk',
        icon: Icons.support_agent,
        accentColor: AppColors.shieldNavy,
        sections: [
          PortalSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'Watch open tasks, follow-up load, complaint status, and campaign performance across the active member base.',
            actions: const ['Create task', 'Open complaint', 'Start outreach'],
            metrics: const [
              PortalMetric(label: 'Tasks today', value: '28', note: 'Assigned'),
              PortalMetric(
                label: 'Open complaints',
                value: '7',
                note: 'Need action',
              ),
              PortalMetric(
                label: 'Follow-ups due',
                value: '12',
                note: 'Same day',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Missed appointment recovery',
                subtitle:
                    'Three members need same-day outreach after skipped visits.',
                meta: 'Manjeri',
                status: 'Urgent',
              ),
              PortalListItem(
                title: 'Wallet confusion complaint',
                subtitle:
                    'Customer asked for a clearer explanation of pharmacy deductions.',
                meta: 'Perinthalmanna',
                status: 'Open',
              ),
              PortalListItem(
                title: 'Wellness camp invitation list',
                subtitle:
                    'Campaign segment is ready for Alanallur and Melattur outreach.',
                meta: 'Campaign',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Follow-up closed',
                subtitle: 'Member confirmed next consultation after call-back.',
                meta: 'CRM action',
                status: 'Closed',
              ),
              PortalListItem(
                title: 'Complaint escalated',
                subtitle:
                    'One reversal request was sent to SHIELD executive queue.',
                meta: 'Cross-team',
                status: 'Escalated',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'High-value cohort',
                subtitle:
                    'Members with recent pharmacy use and pending visits are most responsive.',
                meta: 'Segment insight',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Complaint pattern',
                subtitle:
                    'Most issues come from delayed explanations, not failed service delivery.',
                meta: 'Root cause',
                status: 'Useful',
              ),
            ],
          ),
          PortalSectionData(
            key: 'customers',
            title: 'Customer List',
            summary:
                'Browse engagement-ready customer profiles with service recency, locality, and follow-up need indicators.',
            actions: const ['Search member', 'Open timeline', 'Tag segment'],
            metrics: const [
              PortalMetric(
                label: 'Active members',
                value: '412',
                note: 'Portal dataset',
              ),
              PortalMetric(
                label: 'At-risk members',
                value: '36',
                note: 'Low activity',
              ),
              PortalMetric(
                label: 'High-engagement',
                value: '84',
                note: 'Frequent users',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Nihal Rahman',
                subtitle:
                    'Active pharmacy and clinic usage; candidate for preventive plan upsell.',
                meta: 'Perinthalmanna',
                status: 'Warm',
              ),
              PortalListItem(
                title: 'Fathima Sherin',
                subtitle: 'Recent dental follow-up and high document usage.',
                meta: 'Melattur',
                status: 'Engaged',
              ),
              PortalListItem(
                title: 'Shanib K',
                subtitle:
                    'Pending membership completion and needs activation follow-up.',
                meta: 'Manjeri',
                status: 'Needs care',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Segment updated',
                subtitle:
                    'Members grouped by branch engagement and care frequency.',
                meta: 'CRM data',
                status: 'Updated',
              ),
              PortalListItem(
                title: 'Customer note added',
                subtitle: 'Preferred contact time saved for next outreach.',
                meta: 'Profile note',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most responsive town',
                subtitle:
                    'Tirur members respond fastest to appointment reminder follow-ups.',
                meta: 'Engagement trend',
                status: 'Best',
              ),
              PortalListItem(
                title: 'Conversion opportunity',
                subtitle:
                    'Pending members near Perinthalmanna can likely be activated quickly.',
                meta: 'Growth angle',
                status: 'Strong',
              ),
            ],
          ),
          PortalSectionData(
            key: 'tasks',
            title: 'Tasks',
            summary:
                'Assign and track CRM work items such as call-backs, campaign outreach, issue resolution, and retention nudges.',
            actions: const ['New task', 'Reassign', 'Close task'],
            metrics: const [
              PortalMetric(label: 'Open tasks', value: '28', note: 'Today'),
              PortalMetric(label: 'Due now', value: '9', note: 'Actionable'),
              PortalMetric(label: 'Completed', value: '17', note: 'This week'),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Call no-show patient',
                subtitle:
                    'Check whether the member wants a rescheduled clinic slot.',
                meta: 'Manjeri',
                status: 'Due',
              ),
              PortalListItem(
                title: 'Explain wallet deduction',
                subtitle:
                    'Resolve confusion on recent pharmacy transaction breakdown.',
                meta: 'Perinthalmanna',
                status: 'Due',
              ),
              PortalListItem(
                title: 'Promote wellness camp',
                subtitle:
                    'Invite inactive members from Alanallur and Makkaraparamba.',
                meta: 'Campaign',
                status: 'Queued',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Task closed',
                subtitle:
                    'Member confirmed document access after guided support.',
                meta: 'Support flow',
                status: 'Closed',
              ),
              PortalListItem(
                title: 'Owner changed',
                subtitle: 'Escalated issue moved to a senior CRM executive.',
                meta: 'Workflow',
                status: 'Reassigned',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best task type',
                subtitle:
                    'Follow-up reminder calls are closing faster than broad campaign work.',
                meta: 'Ops insight',
                status: 'Fast',
              ),
              PortalListItem(
                title: 'Suggested improvement',
                subtitle:
                    'Task cards should eventually display wallet and appointment context together.',
                meta: 'Product note',
                status: 'Future',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Scheduled today',
                value: '12',
                note: 'Outbound',
              ),
              PortalMetric(label: 'Reached', value: '7', note: 'So far'),
              PortalMetric(label: 'Need retry', value: '3', note: 'No answer'),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Post-consultation check-in',
                subtitle:
                    'Call member after Manjeri visit to confirm medicine pickup.',
                meta: 'Customer care',
                status: 'Due',
              ),
              PortalListItem(
                title: 'Activation reminder',
                subtitle:
                    'Pending member from Melattur needs enrollment completion guidance.',
                meta: 'Growth',
                status: 'Due',
              ),
              PortalListItem(
                title: 'Dental review follow-up',
                subtitle:
                    'Confirm that recall appointment still works for Friday, June 26, 2026.',
                meta: 'Melattur',
                status: 'Scheduled',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Follow-up logged',
                subtitle: 'Conversation summary saved with next step and date.',
                meta: 'CRM note',
                status: 'Stored',
              ),
              PortalListItem(
                title: 'Escalation raised',
                subtitle:
                    'Home visit concern handed over to clinic operations.',
                meta: 'Cross-team',
                status: 'Raised',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best timing',
                subtitle:
                    'Afternoon callbacks perform better than morning outreach for working members.',
                meta: 'Contact behavior',
                status: 'Improved',
              ),
              PortalListItem(
                title: 'High-retention pattern',
                subtitle:
                    'Follow-up calls after first pharmacy wallet use help keep members active.',
                meta: 'Retention signal',
                status: 'Strong',
              ),
            ],
          ),
          PortalSectionData(
            key: 'complaints',
            title: 'Complaints',
            summary:
                'Track complaint intake, resolution progress, ownership, and member communication around issues.',
            actions: const ['New complaint', 'Escalate', 'Resolve case'],
            metrics: const [
              PortalMetric(label: 'Open cases', value: '7', note: 'Current'),
              PortalMetric(
                label: 'Resolved this week',
                value: '11',
                note: 'Closed',
              ),
              PortalMetric(
                label: 'Avg resolution',
                value: '1.8 days',
                note: 'Portal SLA',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Wallet deduction confusion',
                subtitle:
                    'Member wants branch-wise itemization of medicine charges.',
                meta: 'Perinthalmanna',
                status: 'Open',
              ),
              PortalListItem(
                title: 'Delayed report visibility',
                subtitle: 'Lab file approved late after upload from Tirur.',
                meta: 'Tirur',
                status: 'Investigating',
              ),
              PortalListItem(
                title: 'Appointment delay complaint',
                subtitle:
                    'Wait time exceeded expected window at clinic reception.',
                meta: 'Manjeri',
                status: 'Assigned',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Complaint closed',
                subtitle:
                    'Branch manager called the member and offered a resolution.',
                meta: 'Service recovery',
                status: 'Resolved',
              ),
              PortalListItem(
                title: 'Internal note added',
                subtitle:
                    'Timeline updated with resolution steps for audit traceability.',
                meta: 'Audit support',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most common issue',
                subtitle:
                    'Service explanation gaps are more frequent than hard service failures.',
                meta: 'Root cause',
                status: 'Common',
              ),
              PortalListItem(
                title: 'Best recovery path',
                subtitle:
                    'Same-day human callback produces the highest complaint closure satisfaction.',
                meta: 'Resolution pattern',
                status: 'Effective',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Live campaigns',
                value: '4',
                note: 'Portal mode',
              ),
              PortalMetric(
                label: 'Audience size',
                value: '126',
                note: 'Combined',
              ),
              PortalMetric(
                label: 'Expected reach',
                value: '81%',
                note: 'Contactable members',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Wellness camp outreach',
                subtitle:
                    'Target inactive members near Alanallur and Makkaraparamba.',
                meta: 'Preventive care',
                status: 'Draft',
              ),
              PortalListItem(
                title: 'Pharmacy repeat-purchase push',
                subtitle:
                    'Encourage return visits in Perinthalmanna and Tirur branches.',
                meta: 'Retention',
                status: 'Scheduled',
              ),
              PortalListItem(
                title: 'Dental recall drive',
                subtitle: 'Invite members due for preventive dental reviews.',
                meta: 'Melattur',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Audience filtered',
                subtitle:
                    'Low-activity members separated from high-engagement clusters.',
                meta: 'Segmentation',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Message draft saved',
                subtitle:
                    'Short healthcare-first copy prepared for push and SMS.',
                meta: 'Campaign prep',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best campaign angle',
                subtitle:
                    'Practical reminders and savings messages outperform generic promotions.',
                meta: 'Message learning',
                status: 'Proven',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Rashid P',
        headline:
            'Operational control for member approvals, membership lifecycle, wallet adjustments, and reversals',
        regionLabel: 'Central SHIELD operations desk',
        icon: Icons.verified_user,
        accentColor: AppColors.shieldBlue,
        sections: [
          PortalSectionData(
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
              PortalMetric(
                label: 'Pending approvals',
                value: '14',
                note: 'New members',
              ),
              PortalMetric(
                label: 'Wallet requests',
                value: '6',
                note: 'Manual actions',
              ),
              PortalMetric(
                label: 'Reversal cases',
                value: '3',
                note: 'Awaiting decision',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Founding member validation',
                subtitle:
                    'RC-linked member record is ready for activation review.',
                meta: 'Perinthalmanna',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Wallet top-up request',
                subtitle:
                    'Manual recharge request raised from Melattur branch.',
                meta: 'Branch ops',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Pharmacy reversal appeal',
                subtitle:
                    'Counter staff wants a mistaken deduction reversed after verification.',
                meta: 'Tirur',
                status: 'Urgent',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Membership approved',
                subtitle: 'Digital card generation completed after activation.',
                meta: 'Operations',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Adjustment posted',
                subtitle:
                    'Promotional credit manually added with audit visibility.',
                meta: 'Wallet ops',
                status: 'Completed',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Busiest pipeline',
                subtitle:
                    'Member approval remains the heaviest daily operations queue.',
                meta: 'Workload insight',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Control point',
                subtitle:
                    'Reversal reviews need branch context and transaction proof side by side.',
                meta: 'Process note',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'approvals',
            title: 'Customer Approvals',
            summary:
                'Review new member applications, validate identity details, and activate records for downstream wallet and card creation.',
            actions: const ['Approve member', 'Request change', 'Suspend case'],
            metrics: const [
              PortalMetric(
                label: 'In review',
                value: '14',
                note: 'Current queue',
              ),
              PortalMetric(
                label: 'Approved today',
                value: '8',
                note: 'Activation done',
              ),
              PortalMetric(
                label: 'Need clarification',
                value: '2',
                note: 'Incomplete profiles',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Shanib K application',
                subtitle:
                    'Basic profile is present but founding eligibility needs confirmation.',
                meta: 'Manjeri',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Family enrollment',
                subtitle:
                    'Multi-member record from Alanallur awaiting final mobile validation.',
                meta: 'Alanallur',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Legacy RC migration',
                subtitle:
                    'Profile imported with old loyalty data ready for cleanup.',
                meta: 'Perinthalmanna',
                status: 'Ready',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Approval note saved',
                subtitle:
                    'Why the member was approved was added for audit clarity.',
                meta: 'Ops note',
                status: 'Stored',
              ),
              PortalListItem(
                title: 'Status history posted',
                subtitle:
                    'Draft to active transition recorded in the member timeline.',
                meta: 'Audit trail',
                status: 'Tracked',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Fastest approval branch',
                subtitle:
                    'Perinthalmanna referrals are arriving with the cleanest data quality.',
                meta: 'Source quality',
                status: 'Best',
              ),
              PortalListItem(
                title: 'Common blocker',
                subtitle:
                    'Unverified mobile numbers remain the main delay in same-day activation.',
                meta: 'Root cause',
                status: 'Common',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Founding members',
                value: '238',
                note: 'Portal count',
              ),
              PortalMetric(
                label: 'Standard members',
                value: '174',
                note: 'Portal count',
              ),
              PortalMetric(
                label: 'Cards generated',
                value: '401',
                note: 'Digital',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Card generation pending',
                subtitle:
                    'Member profile approved but digital card not yet issued.',
                meta: 'Melattur',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Standard plan activation',
                subtitle:
                    'Fee marked collected, awaiting final activate click.',
                meta: 'Tirur',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Suspension review',
                subtitle:
                    'Temporary hold requested because of profile mismatch.',
                meta: 'Manjeri',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'QR token issued',
                subtitle:
                    'Privilege card is now available inside customer-facing views.',
                meta: 'Membership flow',
                status: 'Issued',
              ),
              PortalListItem(
                title: 'Lifecycle event saved',
                subtitle: 'Activation timestamp written to membership history.',
                meta: 'Audit support',
                status: 'Stored',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Founding member story',
                subtitle:
                    'Legacy RC migration remains a strong narrative point for management portals.',
                meta: 'Business context',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'UX improvement',
                subtitle:
                    'Membership status filters should stay prominent in future admin builds.',
                meta: 'Future note',
                status: 'Helpful',
              ),
            ],
          ),
          PortalSectionData(
            key: 'wallet-ops',
            title: 'Wallet Operations',
            summary:
                'Approve recharges, manual adjustments, promotional credits, and exception handling with clear audit context.',
            actions: const ['Add credit', 'Approve recharge', 'View ledger'],
            metrics: const [
              PortalMetric(
                label: 'Requests today',
                value: '6',
                note: 'Manual queue',
              ),
              PortalMetric(label: 'Credits posted', value: '4', note: 'Same day'),
              PortalMetric(
                label: 'Exception holds',
                value: '1',
                note: 'Needs manager',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Manual top-up request',
                subtitle:
                    'Branch asked for a member recharge after offline cash collection.',
                meta: 'Melattur',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Promotional credit',
                subtitle:
                    'Preventive camp bonus to be posted to selected members.',
                meta: 'Alanallur',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Negative adjustment hold',
                subtitle:
                    'Chargeback request requires manager confirmation before posting.',
                meta: 'Perinthalmanna',
                status: 'Blocked',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Ledger visible',
                subtitle:
                    'All dummy wallet adjustments are reflected with before/after context.',
                meta: 'Control view',
                status: 'Clear',
              ),
              PortalListItem(
                title: 'Notification sent',
                subtitle:
                    'Member alert triggered after wallet credit approval.',
                meta: 'Customer comms',
                status: 'Sent',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'High-friction step',
                subtitle:
                    'Manual recharge review is where the UI needs the clearest audit explanation.',
                meta: 'Risk control',
                status: 'Important',
              ),
              PortalListItem(
                title: 'Operational value',
                subtitle:
                    'Wallet operations pages help management understand the ledger-based model quickly.',
                meta: 'Portal value',
                status: 'Strong',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Open reversal cases',
                value: '3',
                note: 'Current queue',
              ),
              PortalMetric(
                label: 'Approved this week',
                value: '5',
                note: 'Closed',
              ),
              PortalMetric(
                label: 'Need branch proof',
                value: '1',
                note: 'Incomplete',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Pharmacy double-scan case',
                subtitle: 'Member was charged twice after a counter retry.',
                meta: 'Tirur',
                status: 'Investigate',
              ),
              PortalListItem(
                title: 'Wrong member deduction',
                subtitle:
                    'Branch note suggests the sale was posted to the wrong wallet.',
                meta: 'Perinthalmanna',
                status: 'Urgent',
              ),
              PortalListItem(
                title: 'Cancelled consultation fee',
                subtitle:
                    'No-show fee was deducted despite same-day branch cancellation.',
                meta: 'Manjeri',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Decision logged',
                subtitle:
                    'Previous reversal decision shows approver note and reason.',
                meta: 'Audit trail',
                status: 'Stored',
              ),
              PortalListItem(
                title: 'Member informed',
                subtitle:
                    'Push notification prepared for accepted reversal outcome.',
                meta: 'Comms',
                status: 'Ready',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most common reversal cause',
                subtitle:
                    'Counter-level transaction duplication is the main exception case in portal data.',
                meta: 'Pattern',
                status: 'Common',
              ),
              PortalListItem(
                title: 'Control improvement',
                subtitle:
                    'Side-by-side bill, wallet, and verification history would strengthen review confidence.',
                meta: 'Product note',
                status: 'Future',
              ),
            ],
          ),
          PortalSectionData(
            key: 'support',
            title: 'Support Cases',
            summary:
                'See escalations from branch staff and CRM, then route them to the right operational owner with notes.',
            actions: const ['Assign owner', 'Add note', 'Close issue'],
            metrics: const [
              PortalMetric(label: 'Escalations', value: '9', note: 'Open'),
              PortalMetric(
                label: 'Cross-team handoffs',
                value: '4',
                note: 'Today',
              ),
              PortalMetric(
                label: 'Closed this week',
                value: '18',
                note: 'Resolved',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Pending activation issue',
                subtitle:
                    'CRM flagged a member whose card was not generated after approval.',
                meta: 'Manjeri',
                status: 'Open',
              ),
              PortalListItem(
                title: 'Wallet confusion handoff',
                subtitle: 'Branch and CRM notes bundled into one support case.',
                meta: 'Perinthalmanna',
                status: 'Assigned',
              ),
              PortalListItem(
                title: 'Document visibility complaint',
                subtitle:
                    'Customer cannot find a newly approved report in the app.',
                meta: 'Tirur',
                status: 'Review',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Support note merged',
                subtitle:
                    'Escalation history now shows all prior branch comments.',
                meta: 'Case detail',
                status: 'Merged',
              ),
              PortalListItem(
                title: 'Issue closed',
                subtitle:
                    'Customer confirmed that the missing card is now visible.',
                meta: 'Resolution',
                status: 'Closed',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Cross-team hotspot',
                subtitle:
                    'Membership and wallet exceptions create the most support handoffs.',
                meta: 'Ops learning',
                status: 'Frequent',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Shameer Ali',
        headline:
            'Management overview for approvals, reports, credit exposure, and service performance',
        regionLabel: 'Regional operations and performance dashboard',
        icon: Icons.analytics,
        accentColor: AppColors.success,
        sections: [
          PortalSectionData(
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
              PortalMetric(
                label: 'Active members',
                value: '412',
                note: 'Portal tenant',
              ),
              PortalMetric(
                label: 'Monthly revenue',
                value: '₹8.4L',
                note: 'Combined services',
              ),
              PortalMetric(
                label: 'Pending decisions',
                value: '9',
                note: 'Need manager eye',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Credit override request',
                subtitle:
                    'One high-value member needs extended facility approval.',
                meta: 'Perinthalmanna',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Branch performance review',
                subtitle:
                    'Tirur branch saw improved pharmacy conversion this week.',
                meta: 'Ops review',
                status: 'Open',
              ),
              PortalListItem(
                title: 'Retention dip watch',
                subtitle:
                    'Alanallur cluster has lower repeat service usage than expected.',
                meta: 'Management alert',
                status: 'Watch',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Report pack generated',
                subtitle:
                    'Weekly membership, wallet, and service trend summary is ready.',
                meta: 'Reporting',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Approval completed',
                subtitle:
                    'Manager approved a branch-level wallet exception case.',
                meta: 'Decision log',
                status: 'Done',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Growth leader',
                subtitle:
                    'Perinthalmanna remains the strongest multi-service cluster in the portal.',
                meta: 'Branch ranking',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Focus area',
                subtitle:
                    'Alanallur and Makkaraparamba need stronger recall and outreach coverage.',
                meta: 'Actionable insight',
                status: 'Focus',
              ),
            ],
          ),
          PortalSectionData(
            key: 'approvals',
            title: 'Approvals',
            summary:
                'Review manager-level approvals including credit overrides, high-risk wallet operations, and operational escalations.',
            actions: const ['Approve request', 'Reject', 'Escalate further'],
            metrics: const [
              PortalMetric(label: 'Credit approvals', value: '4', note: 'Open'),
              PortalMetric(
                label: 'Wallet overrides',
                value: '3',
                note: 'Need decision',
              ),
              PortalMetric(
                label: 'Branch escalations',
                value: '2',
                note: 'Operational',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Credit extension',
                subtitle:
                    'Long-term member requests temporary additional healthcare credit.',
                meta: 'Manjeri',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Negative adjustment approval',
                subtitle:
                    'SHIELD executive requires manager sign-off for balance reduction.',
                meta: 'Perinthalmanna',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'High-value reversal',
                subtitle:
                    'A large pharmacy reversal is waiting for final approval.',
                meta: 'Tirur',
                status: 'Urgent',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Decision logged',
                subtitle: 'Approval note captured with financial rationale.',
                meta: 'Audit support',
                status: 'Stored',
              ),
              PortalListItem(
                title: 'Case returned',
                subtitle:
                    'Branch was asked to submit clearer proof before approval.',
                meta: 'Workflow',
                status: 'Returned',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Approval mix',
                subtitle:
                    'Credit-related decisions are the most sensitive management reviews.',
                meta: 'Risk pattern',
                status: 'Highest',
              ),
              PortalListItem(
                title: 'Design ask',
                subtitle:
                    'Managers benefit from a compact branch and member context summary in each case.',
                meta: 'UX note',
                status: 'Needed',
              ),
            ],
          ),
          PortalSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Access role-oriented report packs for memberships, wallet use, branch performance, and operational quality.',
            actions: const ['Export PDF', 'Export Excel', 'Schedule report'],
            metrics: const [
              PortalMetric(label: 'Report packs', value: '7', note: 'Available'),
              PortalMetric(
                label: 'Exports today',
                value: '5',
                note: 'Leadership use',
              ),
              PortalMetric(
                label: 'Data freshness',
                value: '15 min',
                note: 'Portal SLA',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Membership summary',
                subtitle:
                    'Founding versus standard member mix by active branch.',
                meta: 'Executive pack',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Wallet utilization',
                subtitle: 'Spend and recharge patterns across the member base.',
                meta: 'Finance lens',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Document operations report',
                subtitle:
                    'Processing backlog and approval performance by source.',
                meta: 'Ops lens',
                status: 'Queued',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'CSV export generated',
                subtitle:
                    'Branch-wise service usage exported for external review.',
                meta: 'Data export',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Weekly dashboard snapshot',
                subtitle: 'A static pack was saved for management meeting use.',
                meta: 'Meeting prep',
                status: 'Prepared',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most useful pack',
                subtitle:
                    'Combined membership and wallet views tell the clearest business story.',
                meta: 'Management insight',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Next enhancement',
                subtitle:
                    'A care-path funnel would help connect membership to service usage more clearly.',
                meta: 'Opportunity',
                status: 'Future',
              ),
            ],
          ),
          PortalSectionData(
            key: 'analytics',
            title: 'Analytics',
            summary:
                'Inspect branch trends, service mix, member retention patterns, and operational bottlenecks through portal insights.',
            actions: const [
              'Compare branches',
              'Filter service',
              'Open segment',
            ],
            metrics: const [
              PortalMetric(
                label: 'Retention rate',
                value: '78%',
                note: 'Portal average',
              ),
              PortalMetric(
                label: 'Repeat purchase rate',
                value: '64%',
                note: 'Pharmacy-heavy',
              ),
              PortalMetric(
                label: 'Avg service depth',
                value: '2.7',
                note: 'Per active member',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Perinthalmanna outperformance',
                subtitle:
                    'Strongest combined pharmacy, clinic, and document engagement.',
                meta: 'Cluster insight',
                status: 'Lead',
              ),
              PortalListItem(
                title: 'Alanallur watchlist',
                subtitle:
                    'Lower repeat service usage suggests a follow-up gap.',
                meta: 'Retention watch',
                status: 'Watch',
              ),
              PortalListItem(
                title: 'Tirur growth curve',
                subtitle:
                    'Service frequency is rising after member activation improvements.',
                meta: 'Positive trend',
                status: 'Up',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Segment updated',
                subtitle:
                    'Low-engagement cohort now highlights members without a recent follow-up.',
                meta: 'Analytics model',
                status: 'Updated',
              ),
              PortalListItem(
                title: 'Trend summary saved',
                subtitle: 'Branch comparison snapshot prepared for review.',
                meta: 'Management deck',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Key business link',
                subtitle:
                    'Member retention improves where pharmacy and clinic usage happen together.',
                meta: 'Cross-service insight',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Operational lesson',
                subtitle:
                    'Document delays slightly reduce repeat digital engagement after clinic visits.',
                meta: 'Process effect',
                status: 'Observed',
              ),
            ],
          ),
          PortalSectionData(
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
              PortalMetric(
                label: 'Active credit accounts',
                value: '38',
                note: 'Portal count',
              ),
              PortalMetric(label: 'Utilization', value: '61%', note: 'Current'),
              PortalMetric(
                label: 'Overdue watch',
                value: '4',
                note: 'Need follow-up',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Credit limit increase request',
                subtitle:
                    'Regular member seeks temporary extension for treatment bundle.',
                meta: 'Perinthalmanna',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Utilization nearing cap',
                subtitle:
                    'One member is close to full use and may need pause rules.',
                meta: 'Manjeri',
                status: 'Watch',
              ),
              PortalListItem(
                title: 'Settlement follow-up',
                subtitle:
                    'CRM support required for one overdue recovery conversation.',
                meta: 'Tirur',
                status: 'Action',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Approval granted',
                subtitle:
                    'Credit case approved with note on utilization history.',
                meta: 'Decision',
                status: 'Approved',
              ),
              PortalListItem(
                title: 'Collection note added',
                subtitle: 'Recovery follow-up date saved for the CRM team.',
                meta: 'Cross-team',
                status: 'Tagged',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Healthy signal',
                subtitle:
                    'Members with repeat preventive service usage show lower credit stress.',
                meta: 'Risk insight',
                status: 'Positive',
              ),
              PortalListItem(
                title: 'Guardrail',
                subtitle:
                    'Credit oversight pages should always show branch and membership type together.',
                meta: 'Decision aid',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'retention',
            title: 'Retention',
            summary:
                'Focus on repeat visits, service continuity, and locality-based engagement opportunities across the network.',
            actions: const ['Open segment', 'Trigger CRM', 'Branch compare'],
            metrics: const [
              PortalMetric(
                label: 'Repeat members',
                value: '264',
                note: '30-day activity',
              ),
              PortalMetric(
                label: 'Dormant members',
                value: '36',
                note: 'Need reactivation',
              ),
              PortalMetric(
                label: 'Recall success',
                value: '71%',
                note: 'Follow-up driven',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Dormant member cohort',
                subtitle:
                    'Alanallur and Makkaraparamba show the highest inactivity pockets.',
                meta: 'Retention risk',
                status: 'Open',
              ),
              PortalListItem(
                title: 'High-loyalty cohort',
                subtitle:
                    'Perinthalmanna members with wallet usage remain highly sticky.',
                meta: 'Best group',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Dental recall opportunity',
                subtitle:
                    'Preventive-care revisits can improve long-term engagement in Melattur.',
                meta: 'Campaign idea',
                status: 'Promising',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Retention list shared',
                subtitle:
                    'CRM received a targeted call list for low-activity members.',
                meta: 'Action',
                status: 'Sent',
              ),
              PortalListItem(
                title: 'Branch summary refreshed',
                subtitle:
                    'Repeat visit trends updated after the last week of portal activity.',
                meta: 'Insight pack',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Retention formula',
                subtitle:
                    'Members who touch two or more SHIELD services stay active more reliably.',
                meta: 'Core insight',
                status: 'Strong',
              ),
              PortalListItem(
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
      return PortalRoleData(
        role: role,
        operatorName: 'Ameen Basith',
        headline:
            'System-wide administration for users, roles, businesses, audit, and platform configuration',
        regionLabel: 'Unified SHIELD admin console',
        icon: Icons.admin_panel_settings,
        accentColor: AppColors.error,
        sections: [
          PortalSectionData(
            key: 'dashboard',
            title: 'Dashboard',
            summary:
                'View users, roles, businesses, permission health, and system events from the top-level admin control room.',
            actions: const ['Add user', 'Open audit', 'Check system'],
            metrics: const [
              PortalMetric(label: 'Users', value: '86', note: 'All roles'),
              PortalMetric(label: 'Businesses', value: '5', note: 'Configured'),
              PortalMetric(
                label: 'Audit events today',
                value: '428',
                note: 'Tracked',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Role mapping review',
                subtitle:
                    'One branch user was placed in the wrong department permission set.',
                meta: 'Security admin',
                status: 'Review',
              ),
              PortalListItem(
                title: 'System setting draft',
                subtitle:
                    'Notification channel defaults prepared for rollout confirmation.',
                meta: 'Config',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Audit spike noticed',
                subtitle:
                    'Higher-than-usual wallet adjustment activity flagged for quick review.',
                meta: 'Audit watch',
                status: 'Watch',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'User created',
                subtitle:
                    'New pharmacy staff account provisioned for Tirur branch.',
                meta: 'Admin action',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Permission bundle updated',
                subtitle: 'Role grants refreshed for CRM executive operations.',
                meta: 'Access control',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Governance value',
                subtitle:
                    'A clear admin view helps the management portal show SHIELD as one platform, not disconnected tools.',
                meta: 'Storytelling',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Security reminder',
                subtitle:
                    'Audit visibility is the strongest differentiator for this admin portal layer.',
                meta: 'Control insight',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'users',
            title: 'Users',
            summary:
                'Create and manage staff accounts, role assignments, business mapping, and account statuses using dummy records.',
            actions: const ['Create user', 'Disable user', 'Reset access'],
            metrics: const [
              PortalMetric(label: 'Active users', value: '79', note: 'Enabled'),
              PortalMetric(label: 'Disabled', value: '7', note: 'Inactive'),
              PortalMetric(
                label: 'New this month',
                value: '12',
                note: 'Onboarded',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Tirur pharmacy onboarding',
                subtitle:
                    'New staff profile is ready for role and branch assignment.',
                meta: 'User setup',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Dormant CRM account',
                subtitle:
                    'Account should be disabled after last working day confirmation.',
                meta: 'Lifecycle',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Shared-device access issue',
                subtitle:
                    'One clinic user asked for a session reset after branch handover.',
                meta: 'Support',
                status: 'Open',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Role changed',
                subtitle:
                    'Branch coordinator updated from staff to manager visibility tier.',
                meta: 'Access update',
                status: 'Applied',
              ),
              PortalListItem(
                title: 'Device session cleared',
                subtitle: 'Old session data cleared for security hygiene.',
                meta: 'Security admin',
                status: 'Done',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Most active user group',
                subtitle:
                    'Pharmacy staff accounts generate the highest daily platform interaction.',
                meta: 'Usage mix',
                status: 'Top',
              ),
              PortalListItem(
                title: 'Admin note',
                subtitle:
                    'Business and department should remain visible in every user row for clarity.',
                meta: 'UX note',
                status: 'Helpful',
              ),
            ],
          ),
          PortalSectionData(
            key: 'roles',
            title: 'Roles & Permissions',
            summary:
                'Inspect role bundles, permission groups, and cross-business access policy for each SHIELD role.',
            actions: const ['Edit role', 'Assign permissions', 'Clone bundle'],
            metrics: const [
              PortalMetric(label: 'Roles', value: '8', note: 'Platform roles'),
              PortalMetric(
                label: 'Permission groups',
                value: '24',
                note: 'Portal bundles',
              ),
              PortalMetric(
                label: 'Policy exceptions',
                value: '1',
                note: 'Needs review',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Clinic role visibility check',
                subtitle:
                    'Ensure clinic staff cannot open dental-only records.',
                meta: 'ABAC review',
                status: 'Review',
              ),
              PortalListItem(
                title: 'CRM bundle cleanup',
                subtitle:
                    'Customer profile visibility requires a narrower permission set.',
                meta: 'Access design',
                status: 'Pending',
              ),
              PortalListItem(
                title: 'Manager override rights',
                subtitle:
                    'Credit approval actions being reviewed for consistency.',
                meta: 'Governance',
                status: 'Open',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Permission set saved',
                subtitle:
                    'A draft update to SHIELD executive rights was retained in portal mode.',
                meta: 'Role admin',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Policy note added',
                subtitle:
                    'ABAC dependency documented in the role details panel.',
                meta: 'Documentation',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Critical concept',
                subtitle:
                    'Role pages help explain the difference between broad access and record visibility.',
                meta: 'Security story',
                status: 'Clear',
              ),
              PortalListItem(
                title: 'Future step',
                subtitle:
                    'A permission diff view would make governance reviews even easier later.',
                meta: 'Enhancement',
                status: 'Useful',
              ),
            ],
          ),
          PortalSectionData(
            key: 'businesses',
            title: 'Businesses',
            summary:
                'Manage business units, departments, branch identities, and service-provider structure across the SHIELD network.',
            actions: const ['Add business', 'Create department', 'Edit branch'],
            metrics: const [
              PortalMetric(label: 'Businesses', value: '5', note: 'Configured'),
              PortalMetric(
                label: 'Departments',
                value: '14',
                note: 'Across branches',
              ),
              PortalMetric(
                label: 'Active providers',
                value: '12',
                note: 'Portal list',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'New Tirur setup',
                subtitle:
                    'Branch identity draft ready for provider and department mapping.',
                meta: 'Expansion prep',
                status: 'Draft',
              ),
              PortalListItem(
                title: 'Alanallur care desk',
                subtitle:
                    'Home-care support department proposed under clinic operations.',
                meta: 'Department design',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Makkaraparamba routing note',
                subtitle:
                    'Service-provider linkage needs cleanup for outreach reporting.',
                meta: 'Data structure',
                status: 'Attention',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Department updated',
                subtitle:
                    'CRM unit linked correctly to the central engagement team.',
                meta: 'Org mapping',
                status: 'Updated',
              ),
              PortalListItem(
                title: 'Provider label revised',
                subtitle:
                    'Branch naming aligned to SHIELD portal copy across the app.',
                meta: 'Branding',
                status: 'Aligned',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Best platform story',
                subtitle:
                    'Business configuration proves SHIELD can span pharmacies, clinics, dental, and outreach under one model.',
                meta: 'Architecture story',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Modeling reminder',
                subtitle:
                    'Provider and department structure should stay simple for early portals.',
                meta: 'Scope control',
                status: 'Wise',
              ),
            ],
          ),
          PortalSectionData(
            key: 'audit',
            title: 'Audit Logs',
            summary:
                'Review immutable audit activity across approvals, wallet operations, document actions, and admin changes.',
            actions: const ['Filter logs', 'Export trail', 'Inspect event'],
            metrics: const [
              PortalMetric(
                label: 'Events today',
                value: '428',
                note: 'All domains',
              ),
              PortalMetric(
                label: 'Critical actions',
                value: '39',
                note: 'High visibility',
              ),
              PortalMetric(
                label: 'Export requests',
                value: '2',
                note: 'Leadership review',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Wallet adjustment audit',
                subtitle: 'Track who changed a member balance and why.',
                meta: 'Finance control',
                status: 'Visible',
              ),
              PortalListItem(
                title: 'Approval trail',
                subtitle:
                    'Customer activation decision with full actor and timestamp chain.',
                meta: 'Membership',
                status: 'Visible',
              ),
              PortalListItem(
                title: 'Role update event',
                subtitle:
                    'Permission change captured with old/new state for review.',
                meta: 'Admin control',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Export generated',
                subtitle:
                    'Filtered audit slice prepared for management review.',
                meta: 'Compliance',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Event inspection opened',
                subtitle:
                    'Detailed event view helps explain append-only tracking.',
                meta: 'Portal flow',
                status: 'Viewed',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Strong differentiator',
                subtitle:
                    'Audit visibility is one of the most convincing enterprise portal elements.',
                meta: 'Product strength',
                status: 'Major',
              ),
              PortalListItem(
                title: 'Future note',
                subtitle:
                    'Entity snapshots and filters should stay fast even as logs scale.',
                meta: 'Scalability thought',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'system',
            title: 'System Settings',
            summary:
                'Review top-level platform configuration such as notification defaults, file settings, and security preferences in portal form.',
            actions: const ['Edit setting', 'Preview policy', 'Save draft'],
            metrics: const [
              PortalMetric(
                label: 'Config groups',
                value: '9',
                note: 'Portal sections',
              ),
              PortalMetric(
                label: 'Draft changes',
                value: '2',
                note: 'Not applied',
              ),
              PortalMetric(
                label: 'Security profile',
                value: 'Healthy',
                note: 'Portal status',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Notification defaults',
                subtitle:
                    'Push + SMS remain enabled for OTP and appointment reminders.',
                meta: 'Communications',
                status: 'Configured',
              ),
              PortalListItem(
                title: 'File policy review',
                subtitle:
                    'Document upload size and allowed file types are visible to admins.',
                meta: 'Storage control',
                status: 'Review',
              ),
              PortalListItem(
                title: 'Session rules',
                subtitle:
                    'Session duration and device behavior shown in settings UI.',
                meta: 'Security',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Draft saved',
                subtitle:
                    'A system settings preview was saved without affecting portal behavior.',
                meta: 'Configuration',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Security note updated',
                subtitle:
                    'TLS and audit requirements summarized in the system overview.',
                meta: 'Governance',
                status: 'Updated',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Management takeaway',
                subtitle:
                    'System settings complete the story that SHIELD is configurable, not hard-coded.',
                meta: 'Enterprise signal',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Design guardrail',
                subtitle:
                    'Settings should stay readable and grouped, not turn into a wall of switches.',
                meta: 'UX caution',
                status: 'Important',
              ),
            ],
          ),
          PortalSectionData(
            key: 'membership-plans',
            title: 'Membership Plans',
            summary:
                'Configure founding and standard membership plans, fees, benefits, and renewal rules in an admin-focused planning screen.',
            actions: const ['Add plan', 'Edit benefit', 'Preview card'],
            metrics: const [
              PortalMetric(
                label: 'Plans',
                value: '2',
                note: 'Founding + standard',
              ),
              PortalMetric(
                label: 'Active benefits',
                value: '11',
                note: 'Visible in portal',
              ),
              PortalMetric(
                label: 'Draft changes',
                value: '1',
                note: 'Awaiting review',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Founding member plan',
                subtitle:
                    'Legacy RC migration benefits are summarized with card and wallet eligibility notes.',
                meta: 'Core plan',
                status: 'Active',
              ),
              PortalListItem(
                title: 'Standard member plan',
                subtitle:
                    'General enrollment fee and digital privilege card package are shown for new customers.',
                meta: 'Enrollment',
                status: 'Active',
              ),
              PortalListItem(
                title: 'Renewal wording update',
                subtitle:
                    'A draft copy change is prepared for the next management review.',
                meta: 'Content draft',
                status: 'Pending',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Benefit preview opened',
                subtitle:
                    'Admin can check how plan changes would appear in the customer app.',
                meta: 'Cross-view',
                status: 'Viewed',
              ),
              PortalListItem(
                title: 'Rule note saved',
                subtitle:
                    'A renewal rule explanation was retained inside the plan details panel.',
                meta: 'Governance',
                status: 'Saved',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Important closure',
                subtitle:
                    'This page closes the biggest remaining admin gap from the UI spec after users, roles, and settings.',
                meta: 'Spec fit',
                status: 'Major',
              ),
              PortalListItem(
                title: 'Narrative strength',
                subtitle:
                    'Membership plans help management connect frontend polish to the core business model of SHIELD.',
                meta: 'Product story',
                status: 'Strong',
              ),
            ],
          ),
          PortalSectionData(
            key: 'reports',
            title: 'Reports',
            summary:
                'Centralize exports and admin-facing reporting packs for membership, wallet, CRM, document, and operational review.',
            actions: const ['Generate pack', 'Export CSV', 'Schedule report'],
            metrics: const [
              PortalMetric(
                label: 'Available packs',
                value: '8',
                note: 'Admin catalog',
              ),
              PortalMetric(
                label: 'Exports today',
                value: '5',
                note: '20 Jun 2026',
              ),
              PortalMetric(
                label: 'Most used',
                value: 'Membership report',
                note: 'Leadership review',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Membership report',
                subtitle:
                    'Founding versus standard member distribution is ready for leadership export.',
                meta: 'Core report',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Document processing pack',
                subtitle:
                    'Processing backlog and approval throughput are grouped in one admin view.',
                meta: 'Ops report',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'CRM summary',
                subtitle:
                    'Follow-up, complaint, and retention activity can be exported from a single reporting card.',
                meta: 'CRM report',
                status: 'Queued',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'CSV export generated',
                subtitle:
                    'A branch-wise service sheet was prepared for external management review.',
                meta: 'Export',
                status: 'Done',
              ),
              PortalListItem(
                title: 'Report schedule draft',
                subtitle:
                    'Weekly operational packs were prepared in portal mode without automation dependencies.',
                meta: 'Schedule',
                status: 'Draft',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Admin completeness',
                subtitle:
                    'Reports make the admin portal feel operationally complete instead of purely configurational.',
                meta: 'Coverage',
                status: 'Strong',
              ),
              PortalListItem(
                title: 'Future alignment',
                subtitle:
                    'The current cards map cleanly to the reporting and analytics modules described in the docs.',
                meta: 'Architecture fit',
                status: 'Good',
              ),
            ],
          ),
          PortalSectionData(
            key: 'notification-center',
            title: 'Notification Center',
            summary:
                'Review outbound alerts, templates, channel defaults, and recent delivery history across all platform roles.',
            actions: const ['Open template', 'Filter channel', 'Preview alert'],
            metrics: const [
              PortalMetric(
                label: 'Alerts today',
                value: '164',
                note: 'Push + SMS + in-app',
              ),
              PortalMetric(
                label: 'Delivery success',
                value: '98%',
                note: 'Portal aggregate',
              ),
              PortalMetric(
                label: 'Templates',
                value: '12',
                note: 'Role-aware copy',
              ),
            ],
            queueItems: const [
              PortalListItem(
                title: 'Appointment reminder template',
                subtitle:
                    'June 21 visit reminders are visible with both push and SMS preview states.',
                meta: 'Customer alerts',
                status: 'Active',
              ),
              PortalListItem(
                title: 'Complaint escalation alert',
                subtitle:
                    'CRM and SHIELD support templates are grouped with actor and destination labels.',
                meta: 'Ops alert',
                status: 'Ready',
              ),
              PortalListItem(
                title: 'Membership approval message',
                subtitle:
                    'Card-issued and activation confirmations are shown in the admin history panel.',
                meta: 'Lifecycle',
                status: 'Visible',
              ),
            ],
            recentItems: const [
              PortalListItem(
                title: 'Template preview saved',
                subtitle:
                    'An updated OTP and reminder copy set was retained for future rollout.',
                meta: 'Template',
                status: 'Saved',
              ),
              PortalListItem(
                title: 'Delivery log inspected',
                subtitle:
                    'Recent notification history was filtered by role and channel for management portal use.',
                meta: 'Audit view',
                status: 'Viewed',
              ),
            ],
            insightItems: const [
              PortalListItem(
                title: 'Cross-role value',
                subtitle:
                    'A notification center ties together login, appointments, approvals, CRM, and wallet actions in one admin lens.',
                meta: 'Platform story',
                status: 'Major',
              ),
              PortalListItem(
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
