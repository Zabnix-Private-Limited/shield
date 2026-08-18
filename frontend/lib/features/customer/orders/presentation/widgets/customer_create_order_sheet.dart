import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/services/api_service.dart';

enum OrderRequestType {
  prescription,
  manualItems,
  wellness,
}

enum FulfillmentType {
  collectFromPharmacy,
  homeDelivery,
}

class CustomerCreateOrderSheet extends StatefulWidget {
  const CustomerCreateOrderSheet({super.key, this.onOrderCreated});

  final VoidCallback? onOrderCreated;

  @override
  State<CustomerCreateOrderSheet> createState() =>
      _CustomerCreateOrderSheetState();
}

class _CustomerCreateOrderSheetState extends State<CustomerCreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final String _idempotencyKey = const Uuid().v4();

  OrderRequestType _requestType = OrderRequestType.manualItems;
  FulfillmentType _fulfillment = FulfillmentType.collectFromPharmacy;

  // Selected Pharmacy Provider
  Map<String, dynamic>? _selectedPharmacy;
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loadingPharmacies = false;

  // Prescription Selection
  List<Map<String, dynamic>> _prescriptions = [];
  Map<String, dynamic>? _selectedPrescription;
  bool _loadingPrescriptions = false;

  // Manual Items List
  final List<({TextEditingController nameCtrl, int quantity, TextEditingController notesCtrl})>
      _manualItems = [];

  // Wellness Catalogue Items
  List<Map<String, dynamic>> _wellnessProducts = [];
  final Map<String, int> _wellnessCart = {}; // productId -> quantity
  bool _loadingWellness = false;

  // Address & Notes
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, dynamic>? _createdOrder;

  @override
  void initState() {
    super.initState();
    _addManualItem();
    _loadPharmacies();
    _loadPrescriptions();
    _loadWellnessProducts();
  }

  @override
  void dispose() {
    for (final item in _manualItems) {
      item.nameCtrl.dispose();
      item.notesCtrl.dispose();
    }
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addManualItem() {
    setState(() {
      _manualItems.add((
        nameCtrl: TextEditingController(),
        quantity: 1,
        notesCtrl: TextEditingController(),
      ));
    });
  }

  void _removeManualItem(int index) {
    if (_manualItems.length <= 1) return;
    setState(() {
      final item = _manualItems.removeAt(index);
      item.nameCtrl.dispose();
      item.notesCtrl.dispose();
    });
  }

  Future<void> _loadPharmacies() async {
    setState(() => _loadingPharmacies = true);
    try {
      final res = await ApiService.getCustomerProviders(type: 'PHARMACY', pageSize: 50);
      final items = (res['items'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) {
        setState(() {
          _pharmacies = items;
          if (_pharmacies.isNotEmpty && _selectedPharmacy == null) {
            _selectedPharmacy = _pharmacies.first;
          }
          _loadingPharmacies = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPharmacies = false);
    }
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _loadingPrescriptions = true);
    try {
      final docs = await ApiService.getCustomerDocumentsStrict('');
      final rxDocs = docs
          .where((d) => d.type == DocumentType.prescription || d.type?.name.toUpperCase() == 'PRESCRIPTION')
          .map((d) => {
                'id': d.id,
                'fileName': d.fileName,
                'uploadedAt': d.uploadedAt,
              })
          .toList();
      if (mounted) {
        setState(() {
          _prescriptions = rxDocs;
          if (_prescriptions.isNotEmpty) {
            _selectedPrescription = _prescriptions.first;
          }
          _loadingPrescriptions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrescriptions = false);
    }
  }

  Future<void> _loadWellnessProducts() async {
    setState(() => _loadingWellness = true);
    try {
      final res = await ApiService.getCustomerWellnessProducts(pageSize: 50);
      final items = (res['items'] as List? ?? res['data']?['items'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) {
        setState(() {
          _wellnessProducts = items;
          _loadingWellness = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingWellness = false);
    }
  }

  double get _wellnessTotalAmount {
    double total = 0;
    for (final prod in _wellnessProducts) {
      final id = prod['id']?.toString();
      if (id != null && _wellnessCart.containsKey(id)) {
        final qty = _wellnessCart[id] ?? 0;
        final price = (prod['sellingPrice'] as num? ?? prod['mrp'] as num? ?? 0).toDouble();
        total += price * qty;
      }
    }
    return total;
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    if (_selectedPharmacy == null) {
      setState(() => _errorMessage = 'Please select a pharmacy.');
      return;
    }

    if (_fulfillment == FulfillmentType.homeDelivery &&
        _addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Delivery address is required for Home Delivery.');
      return;
    }

    if (_requestType == OrderRequestType.prescription &&
        _selectedPrescription == null) {
      setState(() => _errorMessage = 'Please select a prescription document.');
      return;
    }

    if (_requestType == OrderRequestType.manualItems) {
      bool hasValidItem = false;
      for (final item in _manualItems) {
        if (item.nameCtrl.text.trim().isNotEmpty) {
          hasValidItem = true;
          break;
        }
      }
      if (!hasValidItem) {
        setState(() => _errorMessage = 'Please enter at least one medicine request name.');
        return;
      }
    }

    if (_requestType == OrderRequestType.wellness && _wellnessCart.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one wellness item to your order.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final providerId = _selectedPharmacy!['id'].toString();
      final fulfillmentPreference = _fulfillment == FulfillmentType.homeDelivery
          ? 'HOME_DELIVERY'
          : 'COLLECT_FROM_PHARMACY';

      String sourceStr = 'MANUAL_ITEMS';
      String? docId;
      List<Map<String, dynamic>>? items;

      if (_requestType == OrderRequestType.prescription) {
        sourceStr = 'PRESCRIPTION';
        docId = _selectedPrescription!['id'].toString();
      } else if (_requestType == OrderRequestType.manualItems) {
        sourceStr = 'MANUAL_ITEMS';
        items = _manualItems
            .where((i) => i.nameCtrl.text.trim().isNotEmpty)
            .map((i) => {
                  'name': i.nameCtrl.text.trim(),
                  'quantity': i.quantity,
                  if (i.notesCtrl.text.trim().isNotEmpty)
                    'notes': i.notesCtrl.text.trim(),
                })
            .toList();
      } else {
        sourceStr = 'WELLNESS';
        items = _wellnessCart.entries
            .where((e) => e.value > 0)
            .map((e) => {
                  'product_id': e.key,
                  'quantity': e.value,
                })
            .toList();
      }

      final res = await ApiService.createCustomerOrder(
        providerId: providerId,
        orderSource: sourceStr,
        documentId: docId,
        items: items,
        fulfillmentPreference: fulfillmentPreference,
        deliveryAddress: _fulfillment == FulfillmentType.homeDelivery
            ? _addressController.text.trim()
            : null,
        customerNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        idempotencyKey: _idempotencyKey,
      );

      final orderData = Map<String, dynamic>.from(res['data'] as Map? ?? res);
      if (mounted) {
        setState(() {
          _createdOrder = orderData;
          _isSubmitting = false;
        });
        widget.onOrderCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdOrder != null) {
      return _buildConfirmationView();
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Pharmacy Order',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.shieldNavy,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Form Content
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.caption.copyWith(color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Step 1: Select Request Type
                    Text(
                      '1. Order Type',
                      style: AppTypography.subtitle2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Manual List'),
                            selected: _requestType == OrderRequestType.manualItems,
                            onSelected: (val) {
                              if (val) setState(() => _requestType = OrderRequestType.manualItems);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Prescription'),
                            selected: _requestType == OrderRequestType.prescription,
                            onSelected: (val) {
                              if (val) setState(() => _requestType = OrderRequestType.prescription);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Wellness'),
                            selected: _requestType == OrderRequestType.wellness,
                            onSelected: (val) {
                              if (val) setState(() => _requestType = OrderRequestType.wellness);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Step 2: Content based on Order Type
                    if (_requestType == OrderRequestType.manualItems)
                      _buildManualItemsSection()
                    else if (_requestType == OrderRequestType.prescription)
                      _buildPrescriptionSection()
                    else
                      _buildWellnessSection(),

                    const SizedBox(height: 20),

                    // Step 3: Select Pharmacy Provider
                    Text(
                      'Select Pharmacy',
                      style: AppTypography.subtitle2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingPharmacies)
                      const Center(child: CircularProgressIndicator())
                    else if (_pharmacies.isEmpty)
                      Text(
                        'No active pharmacies available.',
                        style: AppTypography.caption.copyWith(color: Colors.red),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedPharmacy?['id']?.toString(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _pharmacies.map((p) {
                          final name = p['providerName'] ?? p['businessName'] ?? 'Pharmacy';
                          return DropdownMenuItem<String>(
                            value: p['id'].toString(),
                            child: Text(name.toString()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPharmacy = _pharmacies.firstWhere(
                                (p) => p['id'].toString() == val,
                              );
                            });
                          }
                        },
                      ),

                    const SizedBox(height: 20),

                    // Step 4: Fulfillment Preference
                    Text(
                      'Fulfillment Method',
                      style: AppTypography.subtitle2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<FulfillmentType>(
                            title: const Text('Store Pickup', style: TextStyle(fontSize: 13)),
                            subtitle: const Text('Collect from Pharmacy', style: TextStyle(fontSize: 11)),
                            value: FulfillmentType.collectFromPharmacy,
                            groupValue: _fulfillment,
                            onChanged: (val) => setState(() => _fulfillment = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<FulfillmentType>(
                            title: const Text('Home Delivery', style: TextStyle(fontSize: 13)),
                            subtitle: const Text('Deliver to Address', style: TextStyle(fontSize: 11)),
                            value: FulfillmentType.homeDelivery,
                            groupValue: _fulfillment,
                            onChanged: (val) => setState(() => _fulfillment = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),

                    if (_fulfillment == FulfillmentType.homeDelivery) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address *',
                          hintText: 'Enter complete street address and landmark',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Customer Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Customer Notes (Optional)',
                        hintText: 'Special instructions for the pharmacy',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Price Summary Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.shieldNavy,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _requestType == OrderRequestType.wellness
                                  ? 'Estimated Total: ₹${_wellnessTotalAmount.toStringAsFixed(2)}'
                                  : 'Final pricing will be confirmed by the pharmacy after reviewing your order.',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shieldNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Order',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requested Medicines / Items',
          style: AppTypography.subtitle2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._manualItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Medicine / Item Name #${idx + 1}',
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: item.quantity > 1
                          ? () => setState(() => _manualItems[idx] = (
                                nameCtrl: item.nameCtrl,
                                quantity: item.quantity - 1,
                                notesCtrl: item.notesCtrl,
                              ))
                          : null,
                    ),
                    Text('${item.quantity}', style: AppTypography.subtitle2),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => setState(() => _manualItems[idx] = (
                            nameCtrl: item.nameCtrl,
                            quantity: item.quantity + 1,
                            notesCtrl: item.notesCtrl,
                          )),
                    ),
                  ],
                ),
                if (_manualItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeManualItem(idx),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addManualItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Another Item'),
        ),
      ],
    );
  }

  Widget _buildPrescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Prescription Document',
          style: AppTypography.subtitle2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loadingPrescriptions)
          const Center(child: CircularProgressIndicator())
        else if (_prescriptions.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No uploaded prescription documents found. Please upload a prescription first in your Customer Documents.',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedPrescription?['id']?.toString(),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _prescriptions.map((rx) {
              return DropdownMenuItem<String>(
                value: rx['id'].toString(),
                child: Text(rx['fileName']?.toString() ?? 'Prescription'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPrescription = _prescriptions.firstWhere(
                    (rx) => rx['id'].toString() == val,
                  );
                });
              }
            },
          ),
      ],
    );
  }

  Widget _buildWellnessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wellness Catalogue Items',
          style: AppTypography.subtitle2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loadingWellness)
          const Center(child: CircularProgressIndicator())
        else if (_wellnessProducts.isEmpty)
          const Text('No wellness products available.')
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              itemCount: _wellnessProducts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final p = _wellnessProducts[idx];
                final id = p['id'].toString();
                final name = p['productName'] ?? 'Product';
                final price = (p['sellingPrice'] as num? ?? p['mrp'] as num? ?? 0).toDouble();
                final qty = _wellnessCart[id] ?? 0;

                return ListTile(
                  title: Text(name.toString(), style: AppTypography.body2),
                  subtitle: Text('₹${price.toStringAsFixed(2)}', style: AppTypography.caption),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (qty > 0)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () {
                            setState(() {
                              if (qty == 1) {
                                _wellnessCart.remove(id);
                              } else {
                                _wellnessCart[id] = qty - 1;
                              }
                            });
                          },
                        ),
                      if (qty > 0) Text('$qty', style: AppTypography.subtitle2),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            _wellnessCart[id] = qty + 1;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmationView() {
    final order = _createdOrder!;
    final invoiceNumber = order['invoiceNumber'] ?? 'ORD-SUCCESS';
    final providerName = _selectedPharmacy?['providerName'] ??
        _selectedPharmacy?['businessName'] ??
        'Pharmacy';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Order Placed Successfully!',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.shieldNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order Ref: $invoiceNumber',
            style: AppTypography.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.shieldBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your order has been submitted to $providerName. The pharmacy will review and process your request.',
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shieldNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View My Orders', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
