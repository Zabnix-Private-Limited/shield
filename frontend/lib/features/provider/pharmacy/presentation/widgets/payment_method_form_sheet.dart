import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';

class PaymentMethodFormSheet extends StatefulWidget {
  final PharmacyPaymentMethodModel? initialMethod;
  final String? defaultType; // 'BANK_ACCOUNT' | 'UPI'
  final Future<bool> Function({
    required String methodType,
    required Map<String, dynamic> data,
  }) onSave;

  const PaymentMethodFormSheet({
    super.key,
    this.initialMethod,
    this.defaultType,
    required this.onSave,
  });

  @override
  State<PaymentMethodFormSheet> createState() => _PaymentMethodFormSheetState();
}

class _PaymentMethodFormSheetState extends State<PaymentMethodFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _methodType;
  late TextEditingController _labelController;
  late TextEditingController _holderController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;
  late TextEditingController _upiIdController;
  bool _isPrimary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMethod;
    _methodType = m?.methodType ?? widget.defaultType ?? 'BANK_ACCOUNT';
    _labelController = TextEditingController(text: m?.displayLabel ?? '');
    _holderController = TextEditingController(text: m?.accountHolderName ?? '');
    _bankNameController = TextEditingController(text: m?.bankName ?? '');
    _accountNumberController = TextEditingController(text: '');
    _ifscController = TextEditingController(text: m?.ifscCode ?? '');
    _branchController = TextEditingController(text: m?.branchName ?? '');
    _upiIdController = TextEditingController(text: m?.upiId ?? '');
    _isPrimary = m?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _holderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'displayLabel': _labelController.text.trim(),
      'isPrimary': _isPrimary,
    };

    if (_methodType == 'BANK_ACCOUNT') {
      payload['accountHolderName'] = _holderController.text.trim();
      payload['bankName'] = _bankNameController.text.trim();
      if (_accountNumberController.text.trim().isNotEmpty) {
        payload['accountNumber'] = _accountNumberController.text.trim();
      }
      payload['ifscCode'] = _ifscController.text.trim().toUpperCase();
      payload['branchName'] = _branchController.text.trim();
    } else {
      payload['upiId'] = _upiIdController.text.trim().toLowerCase();
    }

    final success = await widget.onSave(
      methodType: _methodType,
      data: payload,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMethod != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? 'Edit ${_methodType == 'BANK_ACCOUNT' ? 'Bank Account' : 'UPI Method'}'
                        : 'Add New Payment Destination',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.shieldNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type Selector (Only when adding)
              if (!isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Bank Account')),
                        selected: _methodType == 'BANK_ACCOUNT',
                        selectedColor: AppColors.shieldNavy,
                        labelStyle: TextStyle(
                          color: _methodType == 'BANK_ACCOUNT'
                              ? Colors.white
                              : AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) =>
                            setState(() => _methodType = 'BANK_ACCOUNT'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('UPI ID')),
                        selected: _methodType == 'UPI',
                        selectedColor: AppColors.shieldGreen,
                        labelStyle: TextStyle(
                          color: _methodType == 'UPI'
                              ? Colors.white
                              : AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _methodType = 'UPI'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Common Field: Display Label
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Display Label (Optional)',
                  hintText: 'e.g. Main Store Account, Primary UPI',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Bank Fields
              if (_methodType == 'BANK_ACCOUNT') ...[
                TextFormField(
                  controller: _holderController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Account holder name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name *',
                    hintText: 'e.g. HDFC Bank, ICICI Bank',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Bank name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isEditing
                        ? 'New Account Number (Leave empty to keep existing)'
                        : 'Account Number *',
                    hintText: 'e.g. 123456789012',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (!isEditing && (v == null || v.trim().isEmpty)) {
                      return 'Account number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ifscController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code *',
                    hintText: 'e.g. HDFC0001234',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'IFSC code is required';
                    final clean = v.trim().toUpperCase();
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(clean)) {
                      return 'Invalid IFSC format (e.g. HDFC0001234)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _branchController,
                  decoration: const InputDecoration(
                    labelText: 'Branch Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                // UPI Fields
                TextFormField(
                  controller: _upiIdController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID / VPA *',
                    hintText: 'e.g. pharmacy@upi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'UPI ID is required';
                    final clean = v.trim().toLowerCase();
                    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+$').hasMatch(clean)) {
                      return 'Invalid UPI ID format (e.g. pharmacy@upi)';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),

              // Set as Primary Checkbox
              CheckboxListTile(
                value: _isPrimary,
                onChanged: (val) => setState(() => _isPrimary = val ?? false),
                title: const Text('Set as Primary Payment Destination'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shieldNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sync_rounded, size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEditing ? 'Saving Changes...' : 'Adding Destination...',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body1.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Add Payment Destination',
                          style: AppTypography.body1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
