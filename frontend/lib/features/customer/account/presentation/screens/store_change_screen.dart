import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../customer/shared/widgets/error_card.dart';

class CustomerStoreChangeScreen extends StatefulWidget {
  const CustomerStoreChangeScreen({super.key, this.loadRequests});
  final Future<List<Map<String, dynamic>>> Function()? loadRequests;

  @override
  State<CustomerStoreChangeScreen> createState() => _CustomerStoreChangeScreenState();
}

class _CustomerStoreChangeScreenState extends State<CustomerStoreChangeScreen> {
  late Future<List<Map<String, dynamic>>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = _loadRequests();
  }

  Future<List<Map<String, dynamic>>> _loadRequests() =>
      widget.loadRequests?.call() ?? ApiService.getStoreChangeRequests();

  void _reload() => setState(() => _requests = _loadRequests());

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorCard(
              title: 'Store change requests unavailable',
              message: 'Your pharmacy change request history could not be loaded.',
              onRetry: _reload,
            );
          }
          final requests = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: requests.isEmpty ? 2 : requests.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _Header(onSubmitted: _reload);
                if (index == 1 && requests.isEmpty) return const _Empty();
                if (requests.isEmpty) return const SizedBox.shrink();
                return _RequestCard(request: requests[index - 1]);
              },
            ),
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.onSubmitted});
  final VoidCallback onSubmitted;
  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(children: [
          const Icon(Icons.local_pharmacy_outlined, color: AppColors.shieldBlue),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Change preferred pharmacy', style: AppTypography.h4),
            SizedBox(height: 4),
            Text('Request a review before your preferred pharmacy is changed.', style: AppTypography.small),
          ])),
          AppButton(text: 'Request', onPressed: () async {
            final submitted = await showDialog<bool>(context: context, builder: (_) => const _StoreChangeDialog());
            if (submitted == true) onSubmitted();
          }),
        ]),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const AppCard(child: Padding(padding: EdgeInsets.all(12), child: Text('No pharmacy change requests yet.', style: AppTypography.body)));
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final Map<String, dynamic> request;
  @override
  Widget build(BuildContext context) {
    final target = Map<String, dynamic>.from(request['requestedProvider'] as Map? ?? const {});
    final previous = request['previousProvider'] is Map ? Map<String, dynamic>.from(request['previousProvider'] as Map) : null;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(target['name']?.toString() ?? 'Requested pharmacy', style: AppTypography.h4)), _Status(status: request['status']?.toString() ?? 'PENDING')]),
      if (previous != null) Text('Previous: ${previous['name'] ?? 'Not set'}', style: AppTypography.small),
      const SizedBox(height: 8), Text(request['reason']?.toString() ?? '', style: AppTypography.body),
      if ((request['reviewReason']?.toString().trim() ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text('Review note: ${request['reviewReason']}', style: AppTypography.small)],
    ]));
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Chip(label: Text(status.replaceAll('_', ' ')), backgroundColor: AppColors.shieldBlue.withValues(alpha: 0.10));
}

class _StoreChangeDialog extends StatefulWidget {
  const _StoreChangeDialog();
  @override
  State<_StoreChangeDialog> createState() => _StoreChangeDialogState();
}

class _StoreChangeDialogState extends State<_StoreChangeDialog> {
  final _reason = TextEditingController();
  String? _providerId;
  bool _saving = false;
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Request pharmacy change'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: ApiService.getEligiblePharmacies(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
            final providers = snapshot.data!;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(initialValue: _providerId, decoration: const InputDecoration(labelText: 'Requested pharmacy'), items: providers.map((provider) => DropdownMenuItem(value: provider['id'].toString(), child: Text(provider['providerName']?.toString() ?? 'Pharmacy'))).toList(), onChanged: _saving ? null : (value) => setState(() => _providerId = value)),
              TextField(controller: _reason, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason')),
            ]);
          },
        ),
        actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')), AppButton(text: _saving ? 'Submitting…' : 'Submit', onPressed: _saving ? null : () async { if (_providerId == null || _reason.text.trim().isEmpty) return; setState(() => _saving = true); try { await ApiService.submitStoreChangeRequest(providerId: _providerId!, reason: _reason.text); if (context.mounted) Navigator.pop(context, true); } finally { if (mounted) setState(() => _saving = false); } })],
      );
}
