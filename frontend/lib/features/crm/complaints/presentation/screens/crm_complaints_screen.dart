import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../customer/shared/widgets/error_card.dart';

class CrmComplaintsScreen extends StatefulWidget {
  const CrmComplaintsScreen({super.key});

  @override
  State<CrmComplaintsScreen> createState() => _CrmComplaintsScreenState();
}

class _CrmComplaintsScreenState extends State<CrmComplaintsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'OPEN';

  @override
  void initState() {
    super.initState();
    _future = ApiService.getCrmComplaints();
  }

  void _reload() => setState(() => _future = ApiService.getCrmComplaints());

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return ErrorCard(
          title: 'Complaints unavailable',
          message: 'The scoped CRM complaint queue could not be loaded.',
          onRetry: _reload,
        );
      }
      final records = snapshot.data!;
      final visible = records.where((record) {
        final status = (record['status'] ?? '').toString().toUpperCase();
        return switch (_filter) {
          'CLOSED' => status == 'RESOLVED',
          'ACTIVE' => status == 'ASSIGNED' || status == 'IN_PROGRESS',
          _ => status != 'RESOLVED',
        };
      }).toList();
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CRM Complaint Queue', style: AppTypography.h3),
                  const SizedBox(height: 6),
                  Text(
                    'Only complaints for customers in your authorised scope are shown.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['OPEN', 'ACTIVE', 'CLOSED']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value == 'CLOSED' ? 'Resolved' : value),
                            selected: _filter == value,
                            onSelected: (_) => setState(() => _filter = value),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No complaints in this queue.'),
                ),
              ),
            ...visible.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ComplaintRow(record: record, onChanged: _reload),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ComplaintRow extends StatelessWidget {
  const _ComplaintRow({required this.record, required this.onChanged});
  final Map<String, dynamic> record;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final id = record['id']?.toString();
      if (id == null) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ComplaintDetail(id: id),
      );
      onChanged();
    },
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (record['complaintType'] ?? 'Complaint')
                      .toString()
                      .replaceAll('_', ' '),
                  style: AppTypography.h4,
                ),
              ),
              _Status(status: (record['status'] ?? 'SUBMITTED').toString()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (record['description'] ?? '').toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small,
          ),
          const SizedBox(height: 8),
          Text(
            'Open case',
            style: AppTypography.small.copyWith(color: AppColors.shieldBlue),
          ),
        ],
      ),
    ),
  );
}

class _ComplaintDetail extends StatefulWidget {
  const _ComplaintDetail({required this.id});
  final String id;
  @override
  State<_ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<_ComplaintDetail> {
  late Future<Map<String, dynamic>> _future;
  bool _submitting = false;
  @override
  void initState() {
    super.initState();
    _future = ApiService.getCrmComplaint(widget.id);
  }

  void _reload() =>
      setState(() => _future = ApiService.getCrmComplaint(widget.id));
  Future<void> _action(
    String title,
    Future<void> Function(String) submit,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Required note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (note == null || note.trim().isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await submit(note);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Complaint updated.')));
        _reload();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request could not be completed. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _assign() async {
    final controller = TextEditingController();
    final assignee = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign complaint'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Authorised staff user ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    if (assignee == null || assignee.trim().isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ApiService.assignCrmComplaint(widget.id, assignee);
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorCard(
              title: 'Complaint unavailable',
              message: 'Refresh and try again.',
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final events = List<Map<String, dynamic>>.from(
            data['lifecycleEvents'] ?? const [],
          );
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complaint #${widget.id}', style: AppTypography.h3),
                const SizedBox(height: 8),
                _Status(status: (data['status'] ?? 'SUBMITTED').toString()),
                const SizedBox(height: 14),
                Text(
                  (data['description'] ?? '').toString(),
                  style: AppTypography.body,
                ),
                const SizedBox(height: 18),
                Text('History', style: AppTypography.h4),
                ...events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AppCard(
                      child: Text(
                        '${event['eventType']}: ${event['note'] ?? ''}',
                        style: AppTypography.small,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      text: 'Assign',
                      onPressed: _submitting ? null : _assign,
                    ),
                    AppButton(
                      text: 'Internal note',
                      onPressed: _submitting
                          ? null
                          : () => _action(
                              'Internal note',
                              (note) => ApiService.addCrmComplaintInternalNote(
                                widget.id,
                                note,
                              ),
                            ),
                    ),
                    AppButton(
                      text: 'Reply',
                      onPressed: _submitting
                          ? null
                          : () => _action(
                              'Reply to customer',
                              (note) => ApiService.replyToCrmComplaint(
                                widget.id,
                                note,
                              ),
                            ),
                    ),
                    AppButton(
                      text: 'Escalate',
                      onPressed: _submitting
                          ? null
                          : () => _action(
                              'Escalate complaint',
                              (note) => ApiService.escalateCrmComplaint(
                                widget.id,
                                note,
                              ),
                            ),
                    ),
                    AppButton(
                      text: 'Resolve',
                      onPressed: _submitting
                          ? null
                          : () => _action(
                              'Resolution note',
                              (note) => ApiService.resolveCrmComplaint(
                                widget.id,
                                note,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(status.replaceAll('_', ' ')));
}
