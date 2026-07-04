import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminAuditModule extends StatelessWidget {
  const AdminAuditModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminConsolePage(
      title: 'Audit logs',
      subtitle:
          'Enterprise audit should be table-first, filterable, exportable, and automatically populated from backend action logging rather than rendered as a consumer-style feed.',
      actions: const [
        AdminActionItem(label: 'Security view', icon: Icons.security_outlined),
        AdminActionItem(label: 'Export audit', icon: Icons.file_download_outlined),
      ],
      toolbar: const AdminConsoleToolbar(
        searchHint: 'Search actor, entity, action, branch, or reason',
        filters: [
          'Today',
          'Auth',
          'Wallet',
          'Membership',
          'Documents',
          'Critical',
        ],
      ),
      child: AdminSplitWorkspace(
        left: AdminStatCard(
          title: 'Filter and retention contract',
          subtitle: 'Audit filters and exports should come from one backend-owned schema.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AdminDetailRows(
                rows: [
                  AdminDetailItem(label: 'Date range', value: 'Backend filter schema pending'),
                  AdminDetailItem(label: 'Actor', value: 'Backend filter schema pending'),
                  AdminDetailItem(label: 'Module', value: 'Backend filter schema pending'),
                  AdminDetailItem(label: 'Severity', value: 'Backend filter schema pending'),
                  AdminDetailItem(label: 'Branch', value: 'Backend filter schema pending'),
                  AdminDetailItem(label: 'Export', value: 'CSV, Excel, and PDF endpoints pending'),
                ],
              ),
              SizedBox(height: 18),
              AdminEmptyState(
                title: 'No filter contract connected yet',
                description:
                    'The audit module should support server-side slicing, saved filters, and export paths without frontend-owned business semantics.',
                actionLabel: 'Bind backend query parameters and export endpoints before enabling bulk review.',
              ),
            ],
          ),
        ),
        center: AdminStatCard(
          title: 'Audit events',
          subtitle: 'One canonical table for auth, configuration, customer, and financial actions.',
          child: Column(
            children: const [
              AdminDataTable<_AuditEventRow>(
                columns: [
                  AdminDataTableColumn<_AuditEventRow>(label: 'Timestamp', valueBuilder: _auditTimestamp),
                  AdminDataTableColumn<_AuditEventRow>(label: 'Actor', valueBuilder: _auditActor),
                  AdminDataTableColumn<_AuditEventRow>(label: 'Role', valueBuilder: _auditRole),
                  AdminDataTableColumn<_AuditEventRow>(label: 'Entity', valueBuilder: _auditEntity),
                  AdminDataTableColumn<_AuditEventRow>(label: 'Action', valueBuilder: _auditAction),
                  AdminDataTableColumn<_AuditEventRow>(label: 'Status', valueBuilder: _auditStatus),
                ],
                rows: [],
              ),
              SizedBox(height: 16),
              AdminEmptyState(
                title: 'No audit dataset connected yet',
                description:
                    'Audit V2 should ingest automatic action logging from backend middleware instead of rendering fake activity feed content.',
                actionLabel: 'Bind `/admin/audit/logs` after the backend audit service is in place.',
              ),
            ],
          ),
        ),
        right: AdminStatCard(
          title: 'Captured fields',
          subtitle: 'The backend logger should populate these fields on every important action.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ChecklistLine(label: 'actorId, role, branchId'),
              _ChecklistLine(label: 'entity and entityId'),
              _ChecklistLine(label: 'action, status, and reason'),
              _ChecklistLine(label: 'before and after payload snapshots'),
              _ChecklistLine(label: 'ip, device, browser, and timestamp'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditEventRow {
  const _AuditEventRow();
}

String _auditTimestamp(_AuditEventRow value) => '';
String _auditActor(_AuditEventRow value) => '';
String _auditRole(_AuditEventRow value) => '';
String _auditEntity(_AuditEventRow value) => '';
String _auditAction(_AuditEventRow value) => '';
String _auditStatus(_AuditEventRow value) => '';

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 8, color: AdminColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AdminTypography.small.copyWith(
                color: AdminColors.subtext,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
