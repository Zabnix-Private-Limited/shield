import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/document.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/demo_support.dart';

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prescriptions = dummyDocuments
        .where((doc) => doc.type == DocumentType.prescription)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/demo/customer/prescriptions');
            },
          ),
        ],
      ),
      body: prescriptions.isEmpty
          ? DemoEmptyState(
              icon: Icons.medication_outlined,
              title: 'No prescriptions yet',
              description:
                  'Once prescriptions are uploaded or issued by clinics and pharmacies, they will appear in this list.',
              actionText: 'Open Prescription Demo',
              onAction: () => context.go('/demo/customer/prescriptions'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = prescriptions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      showDemoDetailsSheet(
                        context,
                        title: prescription.fileName,
                        subtitle:
                            'This prescription is visible to the member and linked to pharmacy-side validation workflows.',
                        meta:
                            '${prescription.uploadedAt.day}/${prescription.uploadedAt.month}/${prescription.uploadedAt.year}',
                        status: _getStatusText(prescription.status),
                        highlights: [
                          'Upload source: ${prescription.uploadedBy ?? 'Provider'}',
                          'Type: Prescription',
                          'Current state: ${_getStatusText(prescription.status)}',
                        ],
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.shieldBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: AppColors.shieldBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prescription.fileName,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${prescription.uploadedAt.day}/${prescription.uploadedAt.month}/${prescription.uploadedAt.year}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              prescription.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusText(prescription.status),
                            style: AppTypography.tiny.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(prescription.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return AppColors.shieldGreen;
      case DocumentStatus.validated:
        return AppColors.shieldLightBlue;
      case DocumentStatus.processing:
        return AppColors.warning;
      case DocumentStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.gray;
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.validated:
        return 'Validated';
      case DocumentStatus.processing:
        return 'Processing';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.classified:
        return 'Classified';
      case DocumentStatus.extracted:
        return 'Extracted';
    }
  }
}
