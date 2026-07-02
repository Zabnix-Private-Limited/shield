import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentCustomersScreen extends ConsumerStatefulWidget {
  const AgentCustomersScreen({super.key});

  @override
  ConsumerState<AgentCustomersScreen> createState() => _AgentCustomersScreenState();
}

class _AgentCustomersScreenState extends ConsumerState<AgentCustomersScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final filtered = controller.customers.where((customer) {
      final combined =
          '${customer['fullName'] ?? ''} ${customer['mobile'] ?? ''} ${customer['customerCode'] ?? ''}'
              .toLowerCase();
      return combined.contains(_query.toLowerCase());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search assigned customers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 520,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final list = ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      final customerId = customer['id']?.toString() ?? '';
                      return ListTile(
                        selected: controller.selectedCustomerId == customerId,
                        title: Text('${customer['fullName'] ?? 'Customer'}'),
                        subtitle: Text(
                          '${customer['status'] ?? 'PENDING'} • ${customer['mobile'] ?? 'No mobile'}',
                        ),
                        trailing: Text('Refs ${customer['referralCount'] ?? 0}'),
                        onTap: customerId.isEmpty
                            ? null
                            : () => ref
                                .read(agentPortalControllerProvider)
                                .selectCustomer(customerId),
                      );
                    },
                  );
                  final detail = controller.isCustomerLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _CustomerDetail(controller: controller);

                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        Expanded(child: list),
                        const Divider(),
                        Expanded(child: detail),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: list),
                      const VerticalDivider(),
                      Expanded(child: detail),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetail extends StatelessWidget {
  const _CustomerDetail({required this.controller});
  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    final customer = controller.selectedCustomer;
    if (customer.isEmpty) {
      return const Center(child: Text('Select a customer to open the agent workspace.'));
    }

    return ListView(
      children: [
        ListTile(
          title: Text('${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim()),
          subtitle: Text('${customer['mobile'] ?? ''}'),
        ),
        ListTile(
          title: const Text('Status'),
          trailing: Text('${customer['status'] ?? 'PENDING'}'),
        ),
        ListTile(
          title: const Text('Agent code'),
          trailing: Text('${customer['agentCode'] ?? '-'}'),
        ),
        ListTile(
          title: const Text('Referral code'),
          trailing: Text('${customer['referralCode'] ?? '-'}'),
        ),
        const Divider(),
        ...controller.customerTasks.take(5).map<Widget>(
          (task) => ListTile(
            title: Text('${task['status'] ?? 'Task'}'),
            subtitle: Text('${task['notes'] ?? ''}'),
          ),
        ),
      ],
    );
  }
}
