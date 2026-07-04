import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminDocumentsModule extends StatelessWidget {
  const AdminDocumentsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Operations / Documents',
      title: 'Document verification command center',
      description:
          'One queue for pending, approved, rejected, expired, and resubmission-required documents with preview, decision, and audit trace.',
      primaryAction: const AdminActionItem(label: 'Approve selected', icon: Icons.verified_outlined),
      secondaryAction: const AdminActionItem(label: 'Request resubmission', icon: Icons.restart_alt_outlined),
      child: const Column(
        children: [
          AdminSectionTabs(tabs: ['Pending', 'Approved', 'Rejected', 'Expired', 'Resubmission']),
          SizedBox(height: 16),
          AdminSplitWorkspace(
            left: _DocumentQueuePanel(),
            center: _DocumentPreviewPanel(),
            right: _DocumentDecisionPanel(),
          ),
        ],
      ),
    );
  }
}

class _DocumentQueuePanel extends StatelessWidget {
  const _DocumentQueuePanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Verification queue',
      subtitle: 'Prioritized by ageing, customer risk, and operational dependency.',
      child: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'Aadhaar • Arun Thomas', subtitle: 'Uploaded today • Kochi Central', meta: 'Needed before afternoon visit', status: 'Priority', color: AdminColors.warning)),
          AdminEntityCard(item: AdminEntityItem(title: 'Lab report • Lakshmi Nair', subtitle: 'Awaiting metadata validation', meta: 'OCR and record-link check', status: 'Review', color: AdminColors.secondary)),
          AdminEntityCard(item: AdminEntityItem(title: 'Membership proof • Fathima Rahman', subtitle: 'Previous rejection appealed', meta: 'Resubmitted 20 min ago', status: 'Escalate', color: AdminColors.danger)),
        ],
      ),
    );
  }
}

class _DocumentPreviewPanel extends StatelessWidget {
  const _DocumentPreviewPanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Preview and metadata',
      subtitle: 'File preview, extraction context, source branch, and linked customer record.',
      child: Column(
        children: [
          AdminPreviewSurface(title: 'Aadhaar document preview', subtitle: 'Front + back image set • 2 pages • source upload via agent registration'),
          SizedBox(height: 16),
          AdminDetailRows(rows: [
            AdminDetailItem(label: 'Customer', value: 'Arun Thomas • SH-10284'),
            AdminDetailItem(label: 'Source', value: 'Agent registration workflow'),
            AdminDetailItem(label: 'Branch', value: 'Kochi Central'),
            AdminDetailItem(label: 'Risk', value: 'Visit blocked until verified'),
          ]),
        ],
      ),
    );
  }
}

class _DocumentDecisionPanel extends StatelessWidget {
  const _DocumentDecisionPanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Approval panel',
      subtitle: 'Decision, comments, and audit trail.',
      child: Column(
        children: [
          AdminDecisionCard(label: 'Approve and unlock next workflow', icon: Icons.check_circle_outline, color: AdminColors.success),
          SizedBox(height: 12),
          AdminDecisionCard(label: 'Reject with explicit reason', icon: Icons.cancel_outlined, color: AdminColors.danger),
          SizedBox(height: 12),
          AdminDecisionCard(label: 'Request upload again', icon: Icons.file_upload_outlined, color: AdminColors.warning),
          SizedBox(height: 16),
          AdminTimeline(items: [
            AdminTimelineItem(time: '09:12', title: 'Uploaded by Rahul Das', description: 'Submitted with registration review context.', accent: AdminColors.secondary),
            AdminTimelineItem(time: '09:16', title: 'OCR metadata attached', description: 'Name and ID fields extracted for comparison.', accent: AdminColors.rewards),
          ]),
        ],
      ),
    );
  }
}
