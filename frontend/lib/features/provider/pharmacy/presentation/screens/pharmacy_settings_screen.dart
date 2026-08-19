import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_orders_repository.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';

class PharmacySettingsScreen extends StatefulWidget {
  const PharmacySettingsScreen({super.key});

  @override
  State<PharmacySettingsScreen> createState() => _PharmacySettingsScreenState();
}

class _PharmacySettingsScreenState extends State<PharmacySettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  final PharmacyOrdersRepository _repository = PharmacyOrdersRepository();

  // Order Workflow Settings
  bool _autoAcceptOrders = false;
  bool _requireInvoiceBeforeDispatch = true;

  // Partial Fulfillment Policy
  bool _allowPartialFulfillment = true;
  bool _allowPartialDispatch = true;

  // Low-Stock & Inventory Behavior
  bool _lowStockAlerts = true;
  int _lowStockThreshold = 5;

  // Alternative & Substitute Preferences
  bool _suggestSubstitutes = true;
  bool _requireCustomerConfirmation = true;

  // Chronic Order Tagging
  bool _enableChronicTagging = true;
  int _defaultRefillCadence = 30;

  // Notifications
  bool _newOrderSoundAlerts = true;
  bool _paymentSubmissionAlerts = true;

  // Delivery & Pickup Rules
  bool _enableHomeDelivery = true;
  bool _enableStorePickup = true;

  // Payment Verification Preferences
  bool _mandatoryManualVerification = true;
  bool _requireUtrProof = true;

  // Display & App Behavior
  String _dateFormat = 'YYYY-MM-DD';
  String _timeFormat = '12-hour AM/PM';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.fetchPharmacySettings();
      if (!mounted) return;
      final workflow = data['orderWorkflow'] as Map<String, dynamic>? ?? {};
      final partial = data['partialFulfillment'] as Map<String, dynamic>? ?? {};
      final lowStock = data['lowStock'] as Map<String, dynamic>? ?? {};
      final subs = data['substitutions'] as Map<String, dynamic>? ?? {};
      final chronic = data['chronic'] as Map<String, dynamic>? ?? {};
      final notifs = data['notifications'] as Map<String, dynamic>? ?? {};
      final deliv = data['deliveryPickup'] as Map<String, dynamic>? ?? {};
      final payVerif = data['paymentVerification'] as Map<String, dynamic>? ?? {};
      final disp = data['display'] as Map<String, dynamic>? ?? {};

      setState(() {
        _autoAcceptOrders = workflow['autoAcceptOrders'] ?? false;
        _requireInvoiceBeforeDispatch = workflow['requireInvoiceBeforeDispatch'] ?? true;

        _allowPartialFulfillment = partial['allowPartialFulfillment'] ?? true;
        _allowPartialDispatch = partial['allowPartialDispatch'] ?? true;

        _lowStockAlerts = lowStock['lowStockAlerts'] ?? true;
        _lowStockThreshold = lowStock['lowStockThreshold'] ?? 5;

        _suggestSubstitutes = subs['suggestSubstitutes'] ?? true;
        _requireCustomerConfirmation = subs['requireCustomerConfirmation'] ?? true;

        _enableChronicTagging = chronic['enableChronicTagging'] ?? true;
        _defaultRefillCadence = chronic['defaultRefillCadenceDays'] ?? 30;

        _newOrderSoundAlerts = notifs['newOrderSoundAlerts'] ?? true;
        _paymentSubmissionAlerts = notifs['paymentSubmissionAlerts'] ?? true;

        _enableHomeDelivery = deliv['enableHomeDelivery'] ?? true;
        _enableStorePickup = deliv['enableStorePickup'] ?? true;

        _mandatoryManualVerification = payVerif['mandatoryManualVerification'] ?? true;
        _requireUtrProof = payVerif['requireUtrProof'] ?? true;

        _dateFormat = disp['dateFormat'] ?? 'YYYY-MM-DD';
        _timeFormat = disp['timeFormat'] ?? '12-hour AM/PM';

        _isLoading = false;
        _isDirty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _handleSave() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = {
        'autoAcceptOrders': _autoAcceptOrders,
        'requireInvoiceBeforeDispatch': _requireInvoiceBeforeDispatch,
        'allowPartialFulfillment': _allowPartialFulfillment,
        'allowPartialDispatch': _allowPartialDispatch,
        'lowStockAlerts': _lowStockAlerts,
        'lowStockThreshold': _lowStockThreshold,
        'suggestSubstitutes': _suggestSubstitutes,
        'requireCustomerConfirmation': _requireCustomerConfirmation,
        'enableChronicTagging': _enableChronicTagging,
        'defaultRefillCadenceDays': _defaultRefillCadence,
        'newOrderSoundAlerts': _newOrderSoundAlerts,
        'paymentSubmissionAlerts': _paymentSubmissionAlerts,
        'enableHomeDelivery': _enableHomeDelivery,
        'enableStorePickup': _enableStorePickup,
        'mandatoryManualVerification': _mandatoryManualVerification,
        'requireUtrProof': _requireUtrProof,
        'dateFormat': _dateFormat,
        'timeFormat': _timeFormat,
      };

      await _repository.updatePharmacySettings(payload);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isDirty = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Pharmacy Settings saved and persisted to server.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    }
  }

  void _handleReset() {
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: PharmacySettingsSkeleton(),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isCompactHeader = screenWidth < 640;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Responsive Header Bar
          PharmacyCard(
            padding: const EdgeInsets.all(20),
            child: isCompactHeader
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PharmacyColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(PharmacyRadius.card),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: PharmacyColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pharmacy Settings',
                                  style: PharmacyTypography.h2.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configure operational policies and display behavior.',
                                  style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          PharmacySecondaryButton(
                            label: 'Discard Changes',
                            icon: Icons.restore_rounded,
                            onPressed: _handleReset,
                          ),
                          PharmacyPrimaryButton(
                            label: 'Save Changes',
                            icon: Icons.save_rounded,
                            isLoading: _isSaving,
                            onPressed: _isDirty ? _handleSave : null,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PharmacyColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(PharmacyRadius.card),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: PharmacyColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pharmacy Settings',
                                    style: PharmacyTypography.h2.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Configure workflow, notifications, and app behavior to match your pharmacy operations.',
                                    style: PharmacyTypography.caption.copyWith(color: PharmacyColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          PharmacySecondaryButton(
                            label: 'Discard Changes',
                            icon: Icons.restore_rounded,
                            onPressed: _handleReset,
                          ),
                          const SizedBox(width: 12),
                          PharmacyPrimaryButton(
                            label: 'Save Changes',
                            icon: Icons.save_rounded,
                            isLoading: _isSaving,
                            onPressed: _isDirty ? _handleSave : null,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Settings Cards Layout Grid
          if (isDesktop) ...[
            // Desktop 3-Column Responsive Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildOrderWorkflowCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildPartialFulfillmentCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildLowStockCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSubstitutesCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildChronicTaggingCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildNotificationsCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDeliveryPickupCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildPaymentVerificationCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildDisplayBehaviorCard()),
              ],
            ),
          ] else ...[
            // Stacked Mobile / Tablet Layout
            _buildOrderWorkflowCard(),
            const SizedBox(height: 16),
            _buildPartialFulfillmentCard(),
            const SizedBox(height: 16),
            _buildLowStockCard(),
            const SizedBox(height: 16),
            _buildSubstitutesCard(),
            const SizedBox(height: 16),
            _buildChronicTaggingCard(),
            const SizedBox(height: 16),
            _buildNotificationsCard(),
            const SizedBox(height: 16),
            _buildDeliveryPickupCard(),
            const SizedBox(height: 16),
            _buildPaymentVerificationCard(),
            const SizedBox(height: 16),
            _buildDisplayBehaviorCard(),
          ],

          const SizedBox(height: 24),
          // Bottom Responsive Actions Bar
          PharmacyCard(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  _isDirty ? 'Unsaved settings modifications pending' : 'All settings up to date',
                  style: PharmacyTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isDirty ? PharmacyColors.navy : PharmacyColors.textSecondary,
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    PharmacySecondaryButton(
                      label: 'Discard Changes',
                      onPressed: _handleReset,
                    ),
                    PharmacyPrimaryButton(
                      label: 'Save Settings',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isSaving,
                      onPressed: _isDirty ? _handleSave : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderWorkflowCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order Workflow',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Auto-Accept Orders',
            subtitle: 'Automatically accept incoming customer orders',
            value: _autoAcceptOrders,
            onChanged: (val) {
              _markDirty();
              setState(() => _autoAcceptOrders = val);
            },
          ),
          const SizedBox(height: 12),
          PharmacySwitchTile(
            title: 'Mandatory Invoice',
            subtitle: 'Require bill/invoice upload before order dispatch',
            value: _requireInvoiceBeforeDispatch,
            onChanged: (val) {
              _markDirty();
              setState(() => _requireInvoiceBeforeDispatch = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartialFulfillmentCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.remove_circle_outline, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Partial Fulfillment',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Allow Partial Quantity',
            subtitle: 'Fulfill available stock and adjust payable total',
            value: _allowPartialFulfillment,
            onChanged: (val) {
              _markDirty();
              setState(() => _allowPartialFulfillment = val);
            },
          ),
          const SizedBox(height: 12),
          PharmacySwitchTile(
            title: 'Partial Dispatch',
            subtitle: 'Allow dispatching available items before full order',
            value: _allowPartialDispatch,
            onChanged: (val) {
              _markDirty();
              setState(() => _allowPartialDispatch = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low-Stock Behavior',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Low-Stock Alerts',
            subtitle: 'Highlight items with quantity below threshold',
            value: _lowStockAlerts,
            onChanged: (val) {
              _markDirty();
              setState(() => _lowStockAlerts = val);
            },
          ),
          const SizedBox(height: 12),
          Text('Alert Threshold (Units)', style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _lowStockThreshold > 1
                    ? () {
                        _markDirty();
                        setState(() => _lowStockThreshold--);
                      }
                    : null,
              ),
              Text('$_lowStockThreshold units', style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  _markDirty();
                  setState(() => _lowStockThreshold++);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutesCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Substitute Preferences',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Suggest Substitutes',
            subtitle: 'Allow pharmacists to propose alternative brands',
            value: _suggestSubstitutes,
            onChanged: (val) {
              _markDirty();
              setState(() => _suggestSubstitutes = val);
            },
          ),
          const SizedBox(height: 12),
          PharmacySwitchTile(
            title: 'Customer Confirmation',
            subtitle: 'Require customer confirmation for price changes',
            value: _requireCustomerConfirmation,
            onChanged: (val) {
              _markDirty();
              setState(() => _requireCustomerConfirmation = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChronicTaggingCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chronic Refill Tagging',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Enable Chronic Tagging',
            subtitle: 'Tag long-term medication orders for refill reminders',
            value: _enableChronicTagging,
            onChanged: (val) {
              _markDirty();
              setState(() => _enableChronicTagging = val);
            },
          ),
          const SizedBox(height: 12),
          Text('Default Refill Cadence: $_defaultRefillCadence days', style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'New Order Alert Sound',
            subtitle: 'Play audio chime when a new order arrives',
            value: _newOrderSoundAlerts,
            onChanged: (val) {
              _markDirty();
              setState(() => _newOrderSoundAlerts = val);
            },
          ),
          const SizedBox(height: 12),
          PharmacySwitchTile(
            title: 'Payment Alerts',
            subtitle: 'Notify on manual payment claims from customers',
            value: _paymentSubmissionAlerts,
            onChanged: (val) {
              _markDirty();
              setState(() => _paymentSubmissionAlerts = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPickupCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery & Pickup Rules',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Enable Home Delivery',
            subtitle: 'Accept home delivery orders within service radius',
            value: _enableHomeDelivery,
            onChanged: (val) {
              _markDirty();
              setState(() => _enableHomeDelivery = val);
            },
          ),
          const SizedBox(height: 12),
          PharmacySwitchTile(
            title: 'Enable Store Pickup',
            subtitle: 'Allow customer collection from pharmacy counter',
            value: _enableStorePickup,
            onChanged: (val) {
              _markDirty();
              setState(() => _enableStorePickup = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentVerificationCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment Verification',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PharmacySwitchTile(
            title: 'Mandatory Manual Review',
            subtitle: 'Staff review required before wallet credit approval',
            value: _mandatoryManualVerification,
            onChanged: (val) {
              _markDirty();
              setState(() => _mandatoryManualVerification = val);
            },
          ),
          const SizedBox(height: 12),
          PharmacySwitchTile(
            title: 'Require UTR / Reference',
            subtitle: 'Require valid UTR number or screenshot proof',
            value: _requireUtrProof,
            onChanged: (val) {
              _markDirty();
              setState(() => _requireUtrProof = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayBehaviorCard() {
    return PharmacyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.display_settings_rounded, color: PharmacyColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Display & App Behavior',
                  style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text('Date Display Format', style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _dateFormat,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: const [
              DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD (2026-08-19)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'DD/MM/YYYY', child: Text('DD/MM/YYYY (19/08/2026)', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (val) {
              if (val != null) {
                _markDirty();
                setState(() => _dateFormat = val);
              }
            },
          ),
          const SizedBox(height: 12),
          Text('Time Format', style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _timeFormat,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: const [
              DropdownMenuItem(value: '12-hour AM/PM', child: Text('12-hour AM/PM (03:14 PM)', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: '24-hour', child: Text('24-hour (15:14)', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (val) {
              if (val != null) {
                _markDirty();
                setState(() => _timeFormat = val);
              }
            },
          ),
        ],
      ),
    );
  }
}
