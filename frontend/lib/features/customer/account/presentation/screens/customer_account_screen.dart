import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../data/customer_account_repository.dart';

class CustomerAccountScreen extends StatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  State<CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<CustomerAccountScreen>
    with SingleTickerProviderStateMixin {
  final _repository = const CustomerAccountRepository();
  late final TabController _tabs;
  late Future<_AccountData> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_AccountData> _load() async {
    final results = await Future.wait([
      _repository.addresses(),
      _repository.dependents(),
      _repository.contacts(),
      _repository.pharmacies(),
      _repository.preferredProvider(),
    ]);
    return _AccountData(
      addresses: results[0] as List<Map<String, dynamic>>,
      dependents: results[1] as List<Map<String, dynamic>>,
      contacts: results[2] as List<Map<String, dynamic>>,
      pharmacies: results[3] as List<Map<String, dynamic>>,
      preferredProvider: results[4] as Map<String, dynamic>?,
    );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _remove({
    required String id,
    required bool address,
    bool contact = false,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          address
              ? 'Remove address?'
              : contact
              ? 'Remove contact?'
              : 'Remove family member?',
        ),
        content: const Text(
          'This action removes the saved record from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      if (address) {
        await _repository.removeAddress(id);
      } else if (contact) {
        await _repository.removeContact(id);
      } else {
        await _repository.removeDependent(id);
      }
      if (mounted) _refresh();
    } catch (_) {
      if (mounted) _message('Could not remove this record. Please retry.');
    }
  }

  Future<void> _editAddress([Map<String, dynamic>? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressEditor(
        value: existing,
        onSave: (value) =>
            _repository.saveAddress(value, id: existing?['id']?.toString()),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _editDependent([Map<String, dynamic>? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DependentEditor(
        value: existing,
        onSave: (value) =>
            _repository.saveDependent(value, id: existing?['id']?.toString()),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _editContact([Map<String, dynamic>? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactEditor(
        value: existing,
        onSave: (value) =>
            _repository.saveContact(value, id: existing?['id']?.toString()),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _setPreferredProvider(String? providerId) async {
    try {
      await _repository.setPreferredProvider(providerId);
      if (mounted) _refresh();
    } catch (_) {
      if (mounted) _message('Could not update your preferred pharmacy.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/portal/customer/profile'),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(child: Text('Profile & family', style: AppTypography.h3)),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.shieldBlue,
            tabs: const [
              Tab(text: 'Addresses'),
              Tab(text: 'Family'),
              Tab(text: 'Contacts'),
              Tab(text: 'Pharmacy'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<_AccountData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account records unavailable',
                      style: AppTypography.h4,
                    ),
                    const SizedBox(height: 8),
                    const Text('Check your connection and retry.'),
                    const SizedBox(height: 12),
                    AppButton(text: 'Retry', onPressed: _refresh),
                  ],
                ),
              );
            }
            final data = snapshot.data!;
            return SizedBox(
              height: 560,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _RecordList(
                    empty: 'No saved addresses yet.',
                    addLabel: 'Add address',
                    records: data.addresses,
                    title: (row) => (row['label'] as String?) ?? 'Address',
                    detail: (row) =>
                        [
                              row['addressLine1'],
                              row['city'],
                              row['state'],
                              row['pincode'],
                            ]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(', '),
                    onAdd: () => _editAddress(),
                    onEdit: _editAddress,
                    onRemove: (row) =>
                        _remove(id: row['id'].toString(), address: true),
                  ),
                  _RecordList(
                    empty: 'No family members saved yet.',
                    addLabel: 'Add family member',
                    records: data.dependents,
                    title: (row) =>
                        '${row['firstName'] ?? ''} ${row['lastName'] ?? ''}'
                            .trim(),
                    detail: (row) =>
                        (row['relation'] as String?) ??
                        'Relationship not added',
                    onAdd: () => _editDependent(),
                    onEdit: _editDependent,
                    onRemove: (row) =>
                        _remove(id: row['id'].toString(), address: false),
                  ),
                  _RecordList(
                    empty: 'No emergency or alternative contacts saved yet.',
                    addLabel: 'Add contact',
                    records: data.contacts,
                    title: (row) => (row['name'] as String?) ?? 'Contact',
                    detail: (row) =>
                        '${row['contactType'] ?? 'ALTERNATIVE'} • ${row['mobile'] ?? ''}',
                    onAdd: () => _editContact(),
                    onEdit: _editContact,
                    onRemove: (row) => _remove(
                      id: row['id'].toString(),
                      address: false,
                      contact: true,
                    ),
                  ),
                  _PharmacyList(
                    pharmacies: data.pharmacies,
                    selectedId: data.preferredProvider?['id']?.toString(),
                    onSelect: _setPreferredProvider,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AccountData {
  const _AccountData({
    required this.addresses,
    required this.dependents,
    required this.contacts,
    required this.pharmacies,
    required this.preferredProvider,
  });
  final List<Map<String, dynamic>> addresses;
  final List<Map<String, dynamic>> dependents;
  final List<Map<String, dynamic>> contacts;
  final List<Map<String, dynamic>> pharmacies;
  final Map<String, dynamic>? preferredProvider;
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.empty,
    required this.addLabel,
    required this.records,
    required this.title,
    required this.detail,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });
  final String empty, addLabel;
  final List<Map<String, dynamic>> records;
  final String Function(Map<String, dynamic>) title, detail;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit, onRemove;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(text: addLabel, onPressed: onAdd),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          AppCard(
            child: Text(
              empty,
              style: AppTypography.body.copyWith(color: AppColors.gray),
            ),
          ),
        ...records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title(record)),
                subtitle: Text(detail(record)),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      onPressed: () => onEdit(record),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onRemove(record),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressEditor extends StatefulWidget {
  const _AddressEditor({this.value, required this.onSave});
  final Map<String, dynamic>? value;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSave;
  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  late final TextEditingController _line1 = TextEditingController(
    text: widget.value?['addressLine1'] as String? ?? '',
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.value?['city'] as String? ?? '',
  );
  late final TextEditingController _state = TextEditingController(
    text: widget.value?['state'] as String? ?? '',
  );
  late final TextEditingController _pincode = TextEditingController(
    text: widget.value?['pincode'] as String? ?? '',
  );
  bool _saving = false;
  @override
  void dispose() {
    _line1.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.value == null ? 'Add address' : 'Edit address',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _line1,
            decoration: const InputDecoration(labelText: 'Address line 1'),
          ),
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          TextField(
            controller: _state,
            decoration: const InputDecoration(labelText: 'State'),
          ),
          TextField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode'),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _saving ? 'Saving...' : 'Save address',
            onPressed: _saving
                ? null
                : () async {
                    if (_line1.text.trim().isEmpty) {
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      await widget.onSave({
                        'addressLine1': _line1.text,
                        'city': _city.text,
                        'state': _state.text,
                        'pincode': _pincode.text,
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (_) {
                      if (mounted) {
                        setState(() => _saving = false);
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
}

class _DependentEditor extends StatefulWidget {
  const _DependentEditor({this.value, required this.onSave});
  final Map<String, dynamic>? value;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSave;
  @override
  State<_DependentEditor> createState() => _DependentEditorState();
}

class _DependentEditorState extends State<_DependentEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.value?['firstName'] as String? ?? '',
  );
  late final TextEditingController _relation = TextEditingController(
    text: widget.value?['relation'] as String? ?? '',
  );
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.value == null ? 'Add family member' : 'Edit family member',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          TextField(
            controller: _relation,
            decoration: const InputDecoration(labelText: 'Relationship'),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _saving ? 'Saving...' : 'Save family member',
            onPressed: _saving
                ? null
                : () async {
                    if (_name.text.trim().isEmpty ||
                        _relation.text.trim().isEmpty) {
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      await widget.onSave({
                        'firstName': _name.text,
                        'relation': _relation.text,
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (_) {
                      if (mounted) {
                        setState(() => _saving = false);
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({this.value, required this.onSave});
  final Map<String, dynamic>? value;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSave;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final _name = TextEditingController(
    text: widget.value?['name'] as String? ?? '',
  );
  late final _mobile = TextEditingController(
    text: widget.value?['mobile'] as String? ?? '',
  );
  String _type = 'EMERGENCY';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = (widget.value?['contactType'] as String? ?? 'EMERGENCY')
        .toUpperCase();
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.value == null ? 'Add contact' : 'Edit contact',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: const [
              DropdownMenuItem(
                value: 'EMERGENCY',
                child: Text('Emergency contact'),
              ),
              DropdownMenuItem(
                value: 'ALTERNATIVE',
                child: Text('Alternative contact'),
              ),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number'),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _saving ? 'Saving...' : 'Save contact',
            onPressed: _saving
                ? null
                : () async {
                    if (_mobile.text.replaceAll(RegExp(r'\D'), '').length !=
                        10) {
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      await widget.onSave({
                        'name': _name.text,
                        'mobile': _mobile.text,
                        'contactType': _type,
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (_) {
                      if (mounted) {
                        setState(() => _saving = false);
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
}

class _PharmacyList extends StatelessWidget {
  const _PharmacyList({
    required this.pharmacies,
    required this.selectedId,
    required this.onSelect,
  });
  final List<Map<String, dynamic>> pharmacies;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      if (selectedId != null)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => onSelect(null),
            child: const Text('Remove preference'),
          ),
        ),
      if (pharmacies.isEmpty)
        AppCard(
          child: Text(
            'No active pharmacies are available.',
            style: AppTypography.body.copyWith(color: AppColors.gray),
          ),
        ),
      ...pharmacies.map((pharmacy) {
        final id = pharmacy['id'].toString();
        final selected = id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected ? Icons.check_circle : Icons.local_pharmacy_outlined,
                color: selected ? AppColors.success : AppColors.shieldBlue,
              ),
              title: Text((pharmacy['providerName'] as String?) ?? 'Pharmacy'),
              subtitle: Text(
                (pharmacy['business'] as Map?)?['name']?.toString() ??
                    'SHIELD pharmacy',
              ),
              trailing: selected
                  ? const Text('Preferred')
                  : TextButton(
                      onPressed: () => onSelect(id),
                      child: const Text('Select'),
                    ),
            ),
          ),
        );
      }),
    ],
  );
}
