import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/shared/widgets/app_skeleton.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payment_details_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/bank_account_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/upi_payment_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/payment_method_form_sheet.dart';

class PharmacyPaymentDetailsScreen extends StatefulWidget {
  const PharmacyPaymentDetailsScreen({super.key});

  @override
  State<PharmacyPaymentDetailsScreen> createState() =>
      _PharmacyPaymentDetailsScreenState();
}

class _PharmacyPaymentDetailsScreenState
    extends State<PharmacyPaymentDetailsScreen> {
  final PharmacyPaymentDetailsController _controller =
      PharmacyPaymentDetailsController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadPaymentDetails();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openAddForm({required String defaultType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentMethodFormSheet(
        defaultType: defaultType,
        onSave: ({required methodType, required data}) async {
          if (methodType == 'BANK_ACCOUNT') {
            return await _controller.createBankAccount(
              accountHolderName: data['accountHolderName'],
              bankName: data['bankName'],
              accountNumber: data['accountNumber'],
              ifscCode: data['ifscCode'],
              branchName: data['branchName'],
              displayLabel: data['displayLabel'],
              isPrimary: data['isPrimary'],
            );
          } else {
            return await _controller.createUpi(
              upiId: data['upiId'],
              displayLabel: data['displayLabel'],
              isPrimary: data['isPrimary'],
            );
          }
        },
      ),
    );
  }

  void _openEditForm(PharmacyPaymentMethodModel method) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentMethodFormSheet(
        initialMethod: method,
        onSave: ({required methodType, required data}) async {
          if (methodType == 'BANK_ACCOUNT') {
            return await _controller.updateBankAccount(
              id: method.id,
              accountHolderName: data['accountHolderName'],
              bankName: data['bankName'],
              accountNumber: data['accountNumber'],
              ifscCode: data['ifscCode'],
              branchName: data['branchName'],
              displayLabel: data['displayLabel'],
              isPrimary: data['isPrimary'],
            );
          } else {
            return await _controller.updateUpi(
              id: method.id,
              upiId: data['upiId'],
              displayLabel: data['displayLabel'],
              isPrimary: data['isPrimary'],
            );
          }
        },
      ),
    );
  }

  Future<void> _pickAndUploadQr(PharmacyPaymentMethodModel method) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        await _controller.uploadUpiQr(
          id: method.id,
          bytes: file.bytes!,
          filename: file.name,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAccounts = _controller.bankAccounts;
    final upiMethods = _controller.upiMethods;
    final isLoading = _controller.isLoading;
    final error = _controller.error;
    final isEmpty = _controller.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Copy with Refresh Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.shieldNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage the bank and UPI details customers can use for manual payments.',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.shieldNavy),
              tooltip: 'Refresh Payment Details',
              onPressed: () => _controller.loadPaymentDetails(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (isLoading && isEmpty) ...[
          const AppPortalSectionSkeleton(
            showHero: false,
            statCards: 2,
            listItems: 3,
          ),
        ] else if (error != null && isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load payment details',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error,
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _controller.loadPaymentDetails(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ] else if (isEmpty) ...[
          // Empty State
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Payment details have not been configured yet.',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customers cannot use manual bank or UPI payment instructions until at least one active payment method is configured.',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openAddForm(
                          defaultType: 'BANK_ACCOUNT',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.shieldNavy,
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add Bank Account',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openAddForm(
                          defaultType: 'UPI',
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add UPI'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Bank Accounts Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bank Accounts',
                style: AppTypography.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddForm(
                  defaultType: 'BANK_ACCOUNT',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.shieldNavy,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Add Bank Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (bankAccounts.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No bank accounts configured.',
                style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ] else ...[
            ...bankAccounts.map(
              (b) => BankAccountCard(
                method: b,
                isUpdating: _controller.isMethodUpdating(b.id),
                onEdit: () => _openEditForm(b),
                onToggleActive: () =>
                    _controller.toggleActive(b.id, !b.isActive),
                onSetPrimary: () => _controller.setPrimary(b.id),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // UPI Methods Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPI & QR Codes',
                style: AppTypography.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddForm(
                  defaultType: 'UPI',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.shieldGreen,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Add UPI',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (upiMethods.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No UPI IDs configured.',
                style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ] else ...[
            ...upiMethods.map(
              (u) => UpiPaymentCard(
                method: u,
                isUpdating: _controller.isMethodUpdating(u.id),
                onEdit: () => _openEditForm(u),
                onUploadQr: () => _pickAndUploadQr(u),
                onRemoveQr: u.qrImageUrl != null
                    ? () => _controller.removeUpiQr(u.id)
                    : null,
                onToggleActive: () =>
                    _controller.toggleActive(u.id, !u.isActive),
                onSetPrimary: () => _controller.setPrimary(u.id),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
