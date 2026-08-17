import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../data/customer_account_repository.dart';

final customerAccountRepositoryProvider = Provider<CustomerAccountRepository>(
  (ref) => const CustomerAccountRepository(),
);

final customerAccountDataProvider = FutureProvider.autoDispose<_AccountData>((
  ref,
) async {
  final repository = ref.watch(customerAccountRepositoryProvider);
  Future<_AccountLoad<T>> load<T>(Future<T> request) async {
    try {
      return _AccountLoad(value: await request);
    } catch (error) {
      return _AccountLoad(error: error);
    }
  }

  final results = await Future.wait([
    load(repository.addresses()),
    load(repository.dependents()),
    load(repository.contacts()),
    load(repository.pharmacies()),
    load(repository.preferredProvider()),
  ]);
  return _AccountData(
    addresses: results[0] as _AccountLoad<List<Map<String, dynamic>>>,
    dependents: results[1] as _AccountLoad<List<Map<String, dynamic>>>,
    contacts: results[2] as _AccountLoad<List<Map<String, dynamic>>>,
    pharmacies: results[3] as _AccountLoad<List<Map<String, dynamic>>>,
    preferredProvider: results[4] as _AccountLoad<Map<String, dynamic>?>,
  );
});

class CustomerAccountScreen extends ConsumerStatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  ConsumerState<CustomerAccountScreen> createState() =>
      _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends ConsumerState<CustomerAccountScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  CustomerAccountRepository get _repository =>
      ref.read(customerAccountRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(customerAccountDataProvider);

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
        ref
            .watch(customerAccountDataProvider)
            .when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => AppCard(
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
              ),
              data: (data) => SizedBox(
                height: 560,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _RecordList(
                      empty: 'No saved addresses yet.',
                      addLabel: 'Add address',
                      records: data.addresses.value ?? const [],
                      loadError: data.addresses.error,
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
                      records: data.dependents.value ?? const [],
                      loadError: data.dependents.error,
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
                      records: data.contacts.value ?? const [],
                      loadError: data.contacts.error,
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
                      pharmacies: data.pharmacies.value ?? const [],
                      loadError: data.pharmacies.error,
                      selectedId: data.preferredProvider.value?['id']
                          ?.toString(),
                      onSelect: _setPreferredProvider,
                    ),
                  ],
                ),
              ),
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
  final _AccountLoad<List<Map<String, dynamic>>> addresses;
  final _AccountLoad<List<Map<String, dynamic>>> dependents;
  final _AccountLoad<List<Map<String, dynamic>>> contacts;
  final _AccountLoad<List<Map<String, dynamic>>> pharmacies;
  final _AccountLoad<Map<String, dynamic>?> preferredProvider;
}

class _AccountLoad<T> {
  const _AccountLoad({this.value, this.error});

  final T? value;
  final Object? error;
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.empty,
    required this.addLabel,
    required this.records,
    this.loadError,
    required this.title,
    required this.detail,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });
  final String empty, addLabel;
  final List<Map<String, dynamic>> records;
  final Object? loadError;
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
        if (loadError != null)
          AppCard(
            child: Text(
              'This section could not be loaded. Retry the account screen to try again.',
              style: AppTypography.body.copyWith(color: AppColors.gray),
            ),
          )
        else if (records.isEmpty)
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
  String? _error;
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
          if (_error != null)
            Text(
              _error!,
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          TextField(
            controller: _line1,
            decoration: const InputDecoration(labelText: 'Address line 1 *'),
          ),
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City *'),
          ),
          TextField(
            controller: _state,
            decoration: const InputDecoration(labelText: 'State *'),
          ),
          TextField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode *'),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _saving ? 'Saving...' : 'Save address',
            onPressed: _saving
                ? null
                : () async {
                    if (_line1.text.trim().isEmpty ||
                        _city.text.trim().isEmpty ||
                        _state.text.trim().isEmpty ||
                        _pincode.text.trim().isEmpty) {
                      setState(() => _error = 'Fill all address fields.');
                      return;
                    }
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
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
                        setState(() {
                          _saving = false;
                          _error = 'Could not save this address. Please retry.';
                        });
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
  String? _error;
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
          if (_error != null)
            Text(
              _error!,
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'First name *'),
          ),
          TextField(
            controller: _relation,
            decoration: const InputDecoration(labelText: 'Relationship *'),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _saving ? 'Saving...' : 'Save family member',
            onPressed: _saving
                ? null
                : () async {
                    if (_name.text.trim().isEmpty ||
                        _relation.text.trim().isEmpty) {
                      setState(
                        () => _error = 'Name and relationship are required.',
                      );
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
                        setState(() {
                          _saving = false;
                          _error =
                              'Could not save this family member. Please retry.';
                        });
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
  String? _error;

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
          if (_error != null)
            Text(
              _error!,
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          DropdownButtonFormField<String>(
            value: _type,
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
            decoration: const InputDecoration(labelText: 'Name *'),
          ),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number *'),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: _saving ? 'Saving...' : 'Save contact',
            onPressed: _saving
                ? null
                : () async {
                    if (_mobile.text.replaceAll(RegExp(r'\D'), '').length !=
                        10) {
                      setState(
                        () => _error = 'Enter a valid 10-digit mobile number.',
                      );
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
                        setState(() {
                          _saving = false;
                          _error = 'Could not save this contact. Please retry.';
                        });
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
    this.loadError,
    required this.selectedId,
    required this.onSelect,
  });
  final List<Map<String, dynamic>> pharmacies;
  final Object? loadError;
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
      if (loadError != null)
        AppCard(
          child: Text(
            'Pharmacy preferences could not be loaded. Retry the account screen to try again.',
            style: AppTypography.body.copyWith(color: AppColors.gray),
          ),
        )
      else if (pharmacies.isEmpty)
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
