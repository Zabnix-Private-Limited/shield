import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payments_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/shared/widgets/portal_support.dart';

class CounterPaymentDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const CounterPaymentDialog({super.key, required this.onSaved});

  @override
  State<CounterPaymentDialog> createState() => _CounterPaymentDialogState();
}

class _CounterPaymentDialogState extends State<CounterPaymentDialog> {
  final _controller = PharmacyPaymentsController.instance;

  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '10000.00',
  );
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _customerSearchResults = [];
  bool _isSearchingCustomers = false;
  Map<String, dynamic>? _selectedCustomer;

  String _selectedChannel = 'CASH';
  final String _selectedPurpose = 'Wallet Recharge';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _referenceController.text =
        'RCP-PHARM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _performCustomerSearch('');
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _customerSearchController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _performCustomerSearch(String q) async {
    setState(() => _isSearchingCustomers = true);
    final results = await _controller.searchCustomers(q);
    if (mounted) {
      setState(() {
        _customerSearchResults = results;
        _isSearchingCustomers = false;
        if (_selectedCustomer == null && results.isNotEmpty) {
          _selectedCustomer = results.first;
        }
      });
    }
  }

  Future<void> _submitCounterPayment() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (_selectedCustomer == null) {
      showPortalSnackBar(
        context,
        'Please search and select a registered SHIELD Privilege Card member.',
        type: PortalToastType.error,
      );
      return;
    }

    if (amount == null || amount < 10000) {
      showPortalSnackBar(
        context,
        'Minimum wallet recharge amount is ₹10,000.',
        type: PortalToastType.error,
      );
      return;
    }

    if (amount.truncate() % 10000 != 0) {
      showPortalSnackBar(
        context,
        'Recharge amount must be in multiples of ₹10,000 (e.g. ₹10,000, ₹20,000, ₹30,000).',
        type: PortalToastType.error,
      );
      return;
    }

    final targetCustomerId = _selectedCustomer!['id'].toString();

    setState(() => _isSubmitting = true);

    final notes = '[$_selectedPurpose] ${_notesController.text.trim()}'.trim();

    final success = await _controller.submitCounterPayment(
      customerId: targetCustomerId,
      amount: amount,
      paymentChannel: _selectedChannel,
      referenceNumber: _referenceController.text.trim(),
      customerNotes: notes,
      autoApprove: false,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final custName = _selectedCustomer?['name'] ?? 'Member';
        showPortalSnackBar(
          context,
          'Recharge of ₹${amount.toStringAsFixed(2)} recorded for $custName and sent for manual verification. No wallet credit is applied until approval.',
          type: PortalToastType.success,
        );
        widget.onSaved();
        Navigator.of(context).pop();
      } else {
        showPortalSnackBar(
          context,
          _controller.error ?? 'Failed to record counter payment.',
          type: PortalToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(PharmacyRadius.card),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: PharmacyColors.canvas,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(PharmacyRadius.card),
                  ),
                  border: Border(
                    bottom: BorderSide(color: PharmacyColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PharmacyColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: PharmacyColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accept Counter Wallet Recharge',
                            style: PharmacyTypography.h3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Exclusive for SHIELD Privilege Card Members • 10% Extra Bonus',
                            style: PharmacyTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: PharmacyColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Privilege Card Member Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SHIELD Privilege Card Member',
                            style: PharmacyTypography.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PharmacyColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: PharmacyColors.primary),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_membership_rounded,
                                  color: PharmacyColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Privilege Member Required',
                                  style: PharmacyTypography.tiny.copyWith(
                                    color: PharmacyColors.primaryHover,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search Customer Field
                      TextField(
                        controller: _customerSearchController,
                        onChanged: _performCustomerSearch,
                        decoration: InputDecoration(
                          hintText:
                              'Search member by name, mobile, or customer code...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: PharmacyColors.textSecondary,
                          ),
                          suffixIcon: _isSearchingCustomers
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: PharmacyColors.canvas,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              PharmacyRadius.field,
                            ),
                            borderSide: const BorderSide(
                              color: PharmacyColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Search Results / Selected Badge
                      if (_customerSearchResults.isNotEmpty) ...[
                        Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            color: PharmacyColors.canvas,
                            borderRadius: BorderRadius.circular(
                              PharmacyRadius.field,
                            ),
                            border: Border.all(color: PharmacyColors.border),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _customerSearchResults.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final cust = _customerSearchResults[idx];
                              final isSelected =
                                  _selectedCustomer?['id'] == cust['id'];
                              final isMember =
                                  cust['isMembershipHolder'] != false;
                              return ListTile(
                                dense: true,
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        cust['name'] ?? 'Member',
                                        overflow: TextOverflow.ellipsis,
                                        style: PharmacyTypography.body.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMember
                                            ? PharmacyColors.primarySoft
                                            : PharmacyColors.warning.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isMember
                                              ? PharmacyColors.primary
                                              : PharmacyColors.warning,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        isMember
                                            ? 'SHIELD Member'
                                            : 'Non-Member (Wellness Only)',
                                        style: PharmacyTypography.tiny.copyWith(
                                          color: isMember
                                              ? PharmacyColors.primaryHover
                                              : PharmacyColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Card Code: ${cust['customerCode'] ?? 'N/A'} • Phone: ${cust['mobile'] ?? 'N/A'}',
                                  style: PharmacyTypography.caption,
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: PharmacyColors.primary,
                                        size: 18,
                                      )
                                    : null,
                                onTap: () {
                                  if (!isMember) {
                                    showPortalSnackBar(
                                      context,
                                      'Non-member app users cannot hold wallet balances. They can only purchase wellness products directly from customer interfaces.',
                                      type: PortalToastType.error,
                                    );
                                    return;
                                  }
                                  setState(() => _selectedCustomer = cust);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      if (_selectedCustomer != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: PharmacyColors.primarySoft.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(
                              PharmacyRadius.field,
                            ),
                            border: Border.all(color: PharmacyColors.primary),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.card_membership_rounded,
                                color: PharmacyColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected Member: ${_selectedCustomer!['name']} (${_selectedCustomer!['customerCode'] ?? 'SHIELD Member'})',
                                  style: PharmacyTypography.caption.copyWith(
                                    color: PharmacyColors.navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: PharmacyColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Payment Channel
                      Text(
                        'Payment Method / Channel',
                        style: PharmacyTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildChannelCard(
                            id: 'CASH',
                            label: 'Cash',
                            icon: Icons.payments_outlined,
                          ),
                          const SizedBox(width: 8),
                          _buildChannelCard(
                            id: 'COUNTER_UPI',
                            label: 'Counter UPI',
                            icon: Icons.qr_code_scanner_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildChannelCard(
                            id: 'CARD_POS',
                            label: 'Card / POS',
                            icon: Icons.credit_card_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildChannelCard(
                            id: 'BANK_TRANSFER',
                            label: 'Bank Transfer',
                            icon: Icons.account_balance_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Amount Input & Presets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recharge Amount (₹)',
                            style: PharmacyTypography.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Min ₹10,000 (Multiples of ₹10k)',
                            style: PharmacyTypography.tiny.copyWith(
                              color: PharmacyColors.primaryHover,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: PharmacyTypography.h2.copyWith(
                                color: PharmacyColors.navy,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: PharmacyTypography.h2.copyWith(
                                  color: PharmacyColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                filled: true,
                                fillColor: PharmacyColors.canvas,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    PharmacyRadius.field,
                                  ),
                                  borderSide: const BorderSide(
                                    color: PharmacyColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Preset Amount Multiples
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [10000, 20000, 30000, 50000, 100000].map((
                            amt,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(
                                  '₹${(amt / 1000).toStringAsFixed(0)}k',
                                ),
                                labelStyle: PharmacyTypography.caption.copyWith(
                                  color: PharmacyColors.primaryHover,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: PharmacyColors.primarySoft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    PharmacyRadius.chip,
                                  ),
                                  side: const BorderSide(
                                    color: PharmacyColors.primary,
                                  ),
                                ),
                                onPressed: () {
                                  _amountController.text = amt
                                      .toDouble()
                                      .toStringAsFixed(2);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Live 10% Extra Bonus Summary Card
                      _buildBonusCalculationCard(),
                      const SizedBox(height: 18),

                      // Receipt # & Purpose
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Receipt / Ref #',
                                  style: PharmacyTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _referenceController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. RCP-10492',
                                    filled: true,
                                    fillColor: PharmacyColors.canvas,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        PharmacyRadius.field,
                                      ),
                                      borderSide: const BorderSide(
                                        color: PharmacyColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Purpose',
                                  style: PharmacyTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PharmacyColors.primarySoft,
                                    borderRadius: BorderRadius.circular(
                                      PharmacyRadius.field,
                                    ),
                                    border: Border.all(
                                      color: PharmacyColors.primary,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: PharmacyColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Wallet Recharge',
                                          style: PharmacyTypography.caption
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    PharmacyColors.primaryHover,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      Text(
                        'Internal Notes / Remarks',
                        style: PharmacyTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Enter counter bill notes or staff reference...',
                          filled: true,
                          fillColor: PharmacyColors.canvas,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              PharmacyRadius.field,
                            ),
                            borderSide: const BorderSide(
                              color: PharmacyColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Manual-verification notice
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: PharmacyColors.canvas,
                          borderRadius: BorderRadius.circular(
                            PharmacyRadius.field,
                          ),
                          border: Border.all(color: PharmacyColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: PharmacyColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manual verification required',
                                    style: PharmacyTypography.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'The payment stays pending until a staff approval explicitly credits the wallet ledger.',
                                    style: PharmacyTypography.tiny,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: PharmacyColors.canvas,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(PharmacyRadius.card),
                  ),
                  border: Border(top: BorderSide(color: PharmacyColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PharmacySecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    PharmacyPrimaryButton(
                      label: _isSubmitting
                          ? 'Submitting...'
                          : 'Submit for Verification',
                      icon: Icons.check_circle_rounded,
                      onPressed: _isSubmitting ? null : _submitCounterPayment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonusCalculationCard() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final isValidMin = amount >= 10000;
    final isValidMultiple = isValidMin && (amount.truncate() % 10000 == 0);

    final bonusAmount = amount * 0.10;
    final totalWalletCredit = amount + bonusAmount;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValidMultiple
            ? PharmacyColors.primarySoft.withValues(alpha: 0.6)
            : PharmacyColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PharmacyRadius.field),
        border: Border.all(
          color: isValidMultiple
              ? PharmacyColors.primary
              : PharmacyColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValidMultiple
                    ? Icons.card_giftcard_rounded
                    : Icons.info_outline_rounded,
                color: isValidMultiple
                    ? PharmacyColors.primary
                    : PharmacyColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isValidMultiple
                      ? '🎁 10% Extra Bonus Credit Applied!'
                      : (amount < 10000
                            ? 'Minimum wallet recharge amount is ₹10,000'
                            : 'Recharge amount must be in multiples of ₹10,000'),
                  style: PharmacyTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isValidMultiple
                        ? PharmacyColors.primaryHover
                        : PharmacyColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (isValidMultiple) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Customer Payment:', style: PharmacyTypography.tiny),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: PharmacyTypography.tiny.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '10% Extra Bonus Credit:',
                  style: PharmacyTypography.tiny.copyWith(
                    color: PharmacyColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '+ ₹${bonusAmount.toStringAsFixed(2)}',
                  style: PharmacyTypography.tiny.copyWith(
                    color: PharmacyColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Credited to Wallet:',
                  style: PharmacyTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PharmacyColors.navy,
                  ),
                ),
                Text(
                  '₹${totalWalletCredit.toStringAsFixed(2)}',
                  style: PharmacyTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PharmacyColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelCard({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedChannel == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedChannel = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? PharmacyColors.primarySoft
                : PharmacyColors.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? PharmacyColors.primary
                  : PharmacyColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? PharmacyColors.primary
                    : PharmacyColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: PharmacyTypography.tiny.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? PharmacyColors.primaryHover
                      : PharmacyColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
