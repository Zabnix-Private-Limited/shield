import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentDocumentsScreen extends ConsumerWidget {
  const AgentDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(agentPortalControllerProvider);
    final docs = controller.customerDocuments;
    return Card(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Customer documents')),
          if (docs.isEmpty)
            const ListTile(title: Text('Select a customer to view documents.'))
          else
            ...docs.map(
              (doc) => ListTile(
                title: Text('${doc['fileName'] ?? 'Document'}'),
                subtitle: Text('${doc['documentType'] ?? ''}'),
                trailing: Text('${doc['status'] ?? 'UPLOADED'}'),
              ),
            ),
        ],
      ),
    );
  }
}
