import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payment_details_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/bank_account_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/upi_payment_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/payment_method_form_sheet.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';
import 'package:shield/features/provider/pharmacy/presentation/pharmacy_error_message.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        PharmacyCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details Configuration',
                      style: PharmacyTypography.h2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage active Bank Account and UPI QR details. Delivered securely to customer payment screens.',
                      style: PharmacyTypography.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: PharmacyColors.navy,
                ),
                tooltip: 'Refresh Payment Details',
                onPressed: () => _controller.loadPaymentDetails(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (isLoading && isEmpty) ...[
          const PharmacyPaymentDetailsSkeleton(),
        ] else if (error != null && isEmpty) ...[
          PharmacyCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: PharmacyColors.danger,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Unable to load payment details',
                    style: PharmacyTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacyFriendlyErrorMessage(
                      error,
                      fallback:
                          "Payment details couldn't be loaded. Please try again.",
                    ),
                    style: PharmacyTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  PharmacyPrimaryButton(
                    label: 'Retry Loading',
                    onPressed: () => _controller.loadPaymentDetails(),
                  ),
                ],
              ),
            ),
          ),
        ] else if (isEmpty) ...[
          PharmacyCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 56,
                    color: PharmacyColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No payment details configured yet',
                    style: PharmacyTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure at least one Bank Account or UPI ID with QR image for customer payments.',
                    style: PharmacyTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      PharmacyPrimaryButton(
                        label: 'Add Bank Account',
                        icon: Icons.add_rounded,
                        onPressed: () =>
                            _openAddForm(defaultType: 'BANK_ACCOUNT'),
                      ),
                      PharmacySecondaryButton(
                        label: 'Add UPI ID',
                        icon: Icons.add_rounded,
                        onPressed: () => _openAddForm(defaultType: 'UPI'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Bank Accounts Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bank Accounts',
                style: PharmacyTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              PharmacyPrimaryButton(
                label: 'Add Bank Account',
                compact: true,
                icon: Icons.add_rounded,
                onPressed: () => _openAddForm(defaultType: 'BANK_ACCOUNT'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (bankAccounts.isEmpty) ...[
            Text(
              'No bank accounts configured.',
              style: PharmacyTypography.caption,
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

          // UPI & QR Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPI Details & QR Codes',
                style: PharmacyTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              PharmacyPrimaryButton(
                label: 'Add UPI ID',
                compact: true,
                icon: Icons.add_rounded,
                onPressed: () => _openAddForm(defaultType: 'UPI'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (upiMethods.isEmpty) ...[
            Text(
              'No UPI details configured.',
              style: PharmacyTypography.caption,
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
