import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderCustomersScreen extends StatelessWidget {
  const ProviderCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final selected = controller.selectedCustomer;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer workspace', style: AppTypography.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller.customers
                  .map(
                    (customer) => ChoiceChip(
                      label: Text(customer['fullName']?.toString() ?? 'Customer'),
                      selected:
                          controller.selectedCustomerId == customer['id']?.toString(),
                      onSelected: (_) => controller.selectCustomer(
                        customer['id']?.toString() ?? '',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            if (controller.isCustomerLoading)
              const Center(child: CircularProgressIndicator())
            else if (selected == null)
              const Text('Select a customer to open the provider workspace.')
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selected.fullName, style: AppTypography.h4),
                      const SizedBox(height: 6),
                      Text('${selected.mobile} • ${selected.customerCode}'),
                      const SizedBox(height: 12),
                      Text(
                        'Membership: ${controller.selectedMembership?['membership']?['membershipNumber'] ?? 'Not issued'}',
                      ),
                      Text(
                        'Wallet cash: Rs ${controller.selectedWallet?['cashWallet']?['available'] ?? controller.selectedWallet?['cashWallet']?['available'] ?? 0}',
                      ),
                      Text(
                        'Documents: ${controller.selectedDocuments.length}',
                      ),
                      Text(
                        'Appointments: ${controller.selectedAppointments.length}',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
