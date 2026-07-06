import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/models/document.dart';
import '../../../../../../shared/models/wallet.dart';
import '../../../../../../shared/services/platform_file_actions.dart';
import '../../../../../../shared/utils/app_display_formatters.dart';
import '../../../shared/presentation/controllers/provider_portal_controller.dart';

class ProviderPatientTabbedDetailPane extends StatelessWidget {
  const ProviderPatientTabbedDetailPane({
    super.key,
    required this.roleKey,
    required this.controller,
    required this.activeTab,
    required this.onTabChanged,
  });

  final String roleKey;
  final ProviderPortalController controller;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProviderTabBar(activeTab: activeTab, onTabChanged: onTabChanged),
          const SizedBox(height: 16),
          _buildTabContent(context),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (activeTab) {
      case 'clinical-notes':
        return _ClinicalNotesTab(controller: controller);
      case 'billing-wallet':
        return _BillingWalletTab(controller: controller);
      case 'timeline':
        return _TimelineTab(controller: controller);
      case 'prescriptions':
        return _PrescriptionsTab(controller: controller);
      case 'documents':
      default:
        return _DocumentsTab(controller: controller);
    }
  }
}

class _ProviderTabBar extends StatelessWidget {
  const _ProviderTabBar({required this.activeTab, required this.onTabChanged});

  final String activeTab;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('documents', 'Documents'),
      ('clinical-notes', 'Clinical Notes'),
      ('billing-wallet', 'Billing & Wallet'),
      ('timeline', 'Timeline'),
      ('prescriptions', 'Prescriptions'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map((tab) {
              final selected = activeTab == tab.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(tab.$2),
                  selected: selected,
                  onSelected: (_) => onTabChanged(tab.$1),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.controller});

  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Patient records',
          subtitle:
              'Open prescriptions, lab reports, invoices, and supporting files from one place.',
        ),
        const SizedBox(height: 12),
        _DocumentGroup(
          title: 'Prescriptions',
          documents: controller.selectedPrescriptionDocuments,
          emptyMessage: 'No prescription files are linked to this patient yet.',
          controller: controller,
        ),
        const SizedBox(height: 12),
        _DocumentGroup(
          title: 'Lab Reports',
          documents: controller.selectedLabReportDocuments,
          emptyMessage: 'No lab reports have been uploaded yet.',
          controller: controller,
        ),
        const SizedBox(height: 12),
        _DocumentGroup(
          title: 'Invoices',
          documents: controller.selectedInvoiceDocuments,
          emptyMessage: 'No invoice files are available yet.',
          controller: controller,
        ),
        const SizedBox(height: 12),
        _DocumentGroup(
          title: 'Other Records',
          documents: controller.selectedOtherDocuments,
          emptyMessage: 'No additional records are available yet.',
          controller: controller,
        ),
      ],
    );
  }
}

class _ClinicalNotesTab extends StatelessWidget {
  const _ClinicalNotesTab({required this.controller});

  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    final consultationForm = controller.consultationForm;
    final visitSummary = controller.activeVisitSummary;
    final statusSummary = controller.activeVisitStatusSummary;
    final noteRows = <MapEntry<String, String>>[
      MapEntry(
        'Chief complaint',
        consultationForm['chiefComplaint']?.toString() ??
            consultationForm['chief_complaint']?.toString() ??
            '',
      ),
      MapEntry('Symptoms', consultationForm['symptoms']?.toString() ?? ''),
      MapEntry(
        'Clinical findings',
        consultationForm['clinicalFindings']?.toString() ??
            consultationForm['clinical_findings']?.toString() ??
            '',
      ),
      MapEntry('Diagnosis', consultationForm['diagnosis']?.toString() ?? ''),
      MapEntry('Advice', consultationForm['advice']?.toString() ?? ''),
      MapEntry(
        'Follow-up',
        consultationForm['followUp']?.toString() ??
            consultationForm['follow_up']?.toString() ??
            '',
      ),
    ].where((entry) => entry.value.trim().isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Clinical notes',
          subtitle:
              'Review the active visit summary, consultation status, and key care notes without leaving the patient record.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Visit status',
              value:
                  statusSummary['statusLabel']?.toString() ??
                  controller.activeVisitStatusLabel,
            ),
            _MetricCard(
              label: 'Care plan',
              value:
                  visitSummary['appointmentTypeLabel']?.toString() ??
                  controller.patientHeaderFieldValue('upcoming-appointment'),
            ),
            _MetricCard(
              label: 'Updated',
              value: AppDisplayFormatters.formatDateOrDateTime(
                visitSummary['updatedAt']?.toString() ??
                    visitSummary['createdAt']?.toString() ??
                    '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (noteRows.isEmpty)
          _SoftEmptyState(
            message:
                'No detailed clinical notes are available for the current visit yet.',
          )
        else
          ...noteRows.map(
            (entry) => _DetailBlock(label: entry.key, value: entry.value),
          ),
      ],
    );
  }
}

class _BillingWalletTab extends StatelessWidget {
  const _BillingWalletTab({required this.controller});

  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    final cashWallet =
        controller.selectedWallet?['cashWallet'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final rewardWallet =
        controller.selectedWallet?['rewardPoints'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final benefitSummary = controller.selectedBenefitSummary;
    final walletStatistics = controller.selectedWalletStatistics;
    final purchases = controller.selectedPurchases;
    final transactions = controller.selectedWalletTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Billing and wallet',
          subtitle:
              'Cash and reward balances are customer-visible. SHIELD benefit support is internal and never shown as spendable wallet balance.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Visible cash',
              value: controller.formatCurrency(cashWallet['available']),
              helper: 'Available to spend where the customer is eligible.',
            ),
            _MetricCard(
              label: 'Reward points',
              value: '${rewardWallet['available'] ?? 0}',
              helper: 'Separate from cash and shown independently.',
            ),
            _MetricCard(
              label: 'Benefit support used',
              value: controller.formatCurrency(
                benefitSummary['appliedTotal'] ??
                    benefitSummary['benefitsUsed'],
              ),
              helper: 'Internal SHIELD support already applied to invoices.',
            ),
            _MetricCard(
              label: 'Monthly spend',
              value: controller.formatCurrency(
                walletStatistics['monthlySpend'],
              ),
              helper: 'Recent cash and invoice activity.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoBanner(
          title: 'Benefit support stays hidden from the visible wallet balance',
          message:
              'Use cash and reward balances for patient-facing conversations. Treat SHIELD benefit support as internal billing assistance that only appears on applied invoice lines.',
        ),
        const SizedBox(height: 14),
        _SectionTitle(
          title: 'Recent invoices',
          subtitle:
              'Latest invoices, wallet deductions, and applied support for this patient.',
        ),
        const SizedBox(height: 10),
        if (purchases.isEmpty)
          _SoftEmptyState(message: 'No invoice activity has been recorded yet.')
        else
          ...purchases.take(5).map((purchase) {
            final amount =
                purchase['payableAmount'] ?? purchase['payable_amount'];
            final count =
                int.tryParse(
                  '${purchase['itemCount'] ?? purchase['item_count'] ?? 0}',
                ) ??
                0;
            final subtitle = [
              '$count item${count == 1 ? '' : 's'}',
              purchase['statusLabel']?.toString() ?? '',
              purchase['invoiceNumber']?.toString() ?? '',
            ].where((value) => value.trim().isNotEmpty).join(' • ');
            return _SummaryCard(
              title: purchase['title']?.toString() ?? 'Invoice',
              subtitle: subtitle,
              meta: controller.formatCurrency(amount),
            );
          }),
        const SizedBox(height: 14),
        _SectionTitle(
          title: 'Ledger activity',
          subtitle:
              'Transactions are grouped by ledger so cash, reward points, and internal benefit support never blur together.',
        ),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          _SoftEmptyState(message: 'No wallet activity has been recorded yet.')
        else
          ...transactions
              .take(8)
              .map(
                (transaction) => _TransactionTile(
                  transaction: transaction,
                  controller: controller,
                ),
              ),
      ],
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.controller});

  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    final timeline = controller.selectedTimeline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: controller.timelineTitle,
          subtitle: controller.timelineSubtitle.isEmpty
              ? 'Follow care activity, documents, visits, and billing events in one stream.'
              : controller.timelineSubtitle,
        ),
        const SizedBox(height: 12),
        if (timeline.isEmpty)
          _SoftEmptyState(
            message: 'No patient timeline activity is available yet.',
          )
        else
          ...timeline.take(12).map((entry) {
            return _SummaryCard(
              title: entry['title']?.toString() ?? 'Activity',
              subtitle: entry['subtitle']?.toString() ?? '',
              meta: [
                _timelineLabel(entry['kind']?.toString()),
                AppDisplayFormatters.formatDateOrDateTime(
                  entry['timestamp']?.toString() ?? '',
                ),
              ].join(' • '),
            );
          }),
      ],
    );
  }
}

class _PrescriptionsTab extends StatelessWidget {
  const _PrescriptionsTab({required this.controller});

  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    final prescription = controller.activeVisitPrescription;
    final items = (prescription['items'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final documents = controller.selectedPrescriptionDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Prescription history',
          subtitle:
              'Review active visit medicines alongside saved prescription documents.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Draft status',
              value:
                  prescription['statusLabel']?.toString() ?? 'No active draft',
            ),
            _MetricCard(
              label: 'Medicine lines',
              value:
                  prescription['totalItemsLabel']?.toString() ??
                  '${items.length}',
            ),
            _MetricCard(
              label: 'Finalized',
              value:
                  prescription['finalizedAtLabel']?.toString() ??
                  'Not finalized',
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _SoftEmptyState(
            message:
                'No medicine lines are attached to the active visit yet. Saved prescription files still appear below.',
          )
        else
          ...items.map(
            (item) => _SummaryCard(
              title: item['title']?.toString() ?? 'Medicine',
              subtitle: [
                item['subtitle']?.toString() ?? '',
                item['dosage']?.toString() ?? '',
                item['duration']?.toString() ?? '',
              ].where((value) => value.trim().isNotEmpty).join(' • '),
              meta: [
                item['mealPlan']?.toString() ?? '',
                item['specialInstructions']?.toString() ?? '',
              ].where((value) => value.trim().isNotEmpty).join(' • '),
            ),
          ),
        const SizedBox(height: 14),
        _DocumentGroup(
          title: 'Saved prescription files',
          documents: documents,
          emptyMessage: 'No prescription files are linked to this patient yet.',
          controller: controller,
        ),
      ],
    );
  }
}

class _DocumentGroup extends StatelessWidget {
  const _DocumentGroup({
    required this.title,
    required this.documents,
    required this.emptyMessage,
    required this.controller,
  });

  final String title;
  final List<Document> documents;
  final String emptyMessage;
  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 8),
        if (documents.isEmpty)
          _SoftEmptyState(message: emptyMessage)
        else
          ...documents.map(
            (document) =>
                _DocumentTile(document: document, controller: controller),
          ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.controller});

  final Document document;
  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    Future<void> openDocument() async {
      try {
        final url = await controller.getPatientDocumentDownloadUrl(document.id);
        await openPlatformUrl(url);
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not open that document right now.'),
          ),
        );
      }
    }

    Future<void> downloadDocument() async {
      try {
        final url = await controller.getPatientDocumentDownloadUrl(document.id);
        await downloadPlatformUrl(url, fileName: document.fileName);
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not download that document right now.'),
          ),
        );
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          onTap: openDocument,
          title: Text(document.fileName),
          subtitle: Text(
            [
                  document.typeLabel,
                  document.statusLabel,
                  AppDisplayFormatters.formatDateOrDateTime(
                    document.uploadedAt.toIso8601String(),
                  ),
                  document.extractionPreview,
                ]
                .whereType<String>()
                .where((value) => value.trim().isNotEmpty)
                .join(' • '),
          ),
          trailing: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(onPressed: openDocument, child: const Text('Open')),
              TextButton(
                onPressed: downloadDocument,
                child: const Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.controller});

  final WalletTransaction transaction;
  final ProviderPortalController controller;

  @override
  Widget build(BuildContext context) {
    final ledger = switch (transaction.subLedgerType.toUpperCase()) {
      'POINTS' => 'Reward points',
      'BENEFIT' => 'Benefit support',
      _ => 'Cash wallet',
    };
    final ledgerNote = switch (transaction.subLedgerType.toUpperCase()) {
      'BENEFIT' => 'Internal support, not a visible wallet balance',
      'POINTS' => 'Customer-visible reward ledger',
      _ => 'Customer-visible cash ledger',
    };

    return _SummaryCard(
      title: transaction.remarks?.trim().isNotEmpty == true
          ? transaction.remarks!.trim()
          : transaction.isCredit
          ? 'Credit posted'
          : 'Debit recorded',
      subtitle:
          '$ledger • ${transaction.isCredit ? 'Credit' : 'Debit'} • $ledgerNote',
      meta:
          '${controller.formatCurrency(transaction.amount)} • ${AppDisplayFormatters.formatDateOrDateTime(transaction.createdAt.toIso8601String())}',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.helper});

  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
          if (helper?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: AppTypography.tiny.copyWith(color: AppColors.gray),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.shieldBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
          ],
          if (meta.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: AppTypography.tiny.copyWith(color: AppColors.gray),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftEmptyState extends StatelessWidget {
  const _SoftEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: AppTypography.small.copyWith(color: AppColors.gray),
      ),
    );
  }
}

String _timelineLabel(String? rawKind) {
  switch ((rawKind ?? '').toUpperCase()) {
    case 'APPOINTMENT':
      return 'Visit';
    case 'CONSULTATION':
      return 'Consultation';
    case 'DIAGNOSIS':
      return 'Diagnosis';
    case 'ADVICE':
      return 'Advice';
    case 'FOLLOW_UP':
      return 'Follow-up';
    case 'DOCUMENT':
      return 'Document';
    default:
      return 'Activity';
  }
}
