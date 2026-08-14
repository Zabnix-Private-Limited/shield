import 'package:flutter/material.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentStoreChangeScreen extends StatefulWidget {
  const AgentStoreChangeScreen({super.key, this.loadRequests});
  final Future<List<Map<String, dynamic>>> Function()? loadRequests;
  @override
  State<AgentStoreChangeScreen> createState() => _AgentStoreChangeScreenState();
}

class _AgentStoreChangeScreenState extends State<AgentStoreChangeScreen> {
  late Future<List<Map<String, dynamic>>> _requests;
  @override
  void initState() { super.initState(); _requests = _loadRequests(); }
  Future<List<Map<String, dynamic>>> _loadRequests() =>
      widget.loadRequests?.call() ?? ApiService.getStaffStoreChangeRequests();
  void _reload() => setState(() => _requests = _loadRequests());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) {
            return AgentWorkspaceSurface(child: AgentPanelCard(title: 'Store change queue unavailable', subtitle: 'The assigned customer request queue could not be loaded.', child: TextButton(onPressed: _reload, child: const Text('Retry'))));
          }
          final requests = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AgentUi.compactPanelPadding,
              itemCount: requests.isEmpty ? 2 : requests.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return const AgentSectionHeader(title: 'Store Change Requests', description: 'Review preferred pharmacy changes only for customers assigned to you.');
                if (index == 1 && requests.isEmpty) return const AgentPanelCard(title: 'No store change requests', subtitle: 'There are no assigned customer pharmacy changes to review.', child: SizedBox.shrink());
                if (requests.isEmpty) return const SizedBox.shrink();
                return _RequestCard(request: requests[index - 1], onReviewed: _reload);
              },
            ),
          );
        },
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onReviewed});
  final Map<String, dynamic> request;
  final VoidCallback onReviewed;
  @override
  Widget build(BuildContext context) {
    final customer = Map<String, dynamic>.from(request['customer'] as Map? ?? const {});
    final requested = Map<String, dynamic>.from(request['requestedProvider'] as Map? ?? const {});
    final pending = request['status']?.toString().toUpperCase() == 'PENDING';
    return AgentPanelCard(
      title: customer['name']?.toString().trim().isNotEmpty == true ? customer['name'].toString() : 'Assigned customer',
      subtitle: 'Requested pharmacy: ${requested['name'] ?? 'Unavailable'}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reason: ${request['reason'] ?? ''}'),
        const SizedBox(height: 8),
        AgentStatusBadge(label: request['status']?.toString() ?? 'PENDING', color: pending ? AgentColors.warning : AgentColors.success, icon: pending ? Icons.hourglass_top_outlined : Icons.task_alt_outlined),
        if ((request['reviewReason']?.toString().trim() ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Review note: ${request['reviewReason']}')),
        if (pending) Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 8, children: [OutlinedButton(onPressed: () => _review(context, 'REJECTED'), child: const Text('Reject')), FilledButton(onPressed: () => _review(context, 'APPROVED'), child: const Text('Approve'))])),
      ]),
    );
  }
  Future<void> _review(BuildContext context, String status) async {
    String? reason;
    if (status == 'REJECTED') {
      reason = await _requestReason(context);
      if (reason == null) return;
    }
    await ApiService.reviewStoreChangeRequest(request['id'].toString(), status: status, reason: reason);
    onReviewed();
  }
  Future<String?> _requestReason(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Reject request'), content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () { final reason = controller.text.trim(); if (reason.isNotEmpty) Navigator.pop(dialogContext, reason); }, child: const Text('Reject'))]));
    controller.dispose();
    return result;
  }
}
