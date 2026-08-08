import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../services/data/models/customer_provider.dart';
import 'customer_booking_controller.dart';

class CustomerBookingScreen extends StatefulWidget {
  const CustomerBookingScreen({super.key, this.controller});

  final CustomerBookingController? controller;

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  late final CustomerBookingController _controller;
  late final bool _ownsController;
  final _search = TextEditingController();
  final _notes = TextEditingController();
  bool _didRestore = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CustomerBookingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestore) return;
    _didRestore = true;
    _controller.restorePreselection(_query(context)['provider']);
  }

  @override
  void dispose() {
    _search.dispose();
    _notes.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final completed = _controller.completedAppointment;
      if (completed != null) {
        return _BookingSuccess(appointmentId: completed.id);
      }
      return ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Text('Book a visit', style: AppTypography.h3),
          const SizedBox(height: 6),
          Text(
            'Choose an active provider and send a preferred visit request. Final scheduling remains with SHIELD.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 20),
          Text('Provider', style: AppTypography.h4),
          const SizedBox(height: 8),
          if (_controller.provider != null)
            _SelectedProviderCard(
              provider: _controller.provider!,
              onChange: _controller.clearProvider,
            )
          else
            _ProviderPicker(
              controller: _controller,
              search: _search,
              onSearch: () => _controller.searchProviders(query: _search.text),
            ),
          if (_controller.error != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Text(
                _controller.provider == null
                    ? 'That provider is unavailable. Choose another active provider.'
                    : 'Booking could not be sent. Your provider and preferred time are still saved here.',
                style: AppTypography.small.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Preferred date and time', style: AppTypography.h4),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_outlined,
                color: AppColors.shieldBlue,
              ),
              title: Text(_formatDateTime(_controller.preferredDateTime)),
              subtitle: const Text('This is a request, not a live slot.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickDateTime(context),
            ),
          ),
          const SizedBox(height: 20),
          Text('Reason for visit (optional)', style: AppTypography.h4),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLength: 1000,
            maxLines: 4,
            onChanged: _controller.setNotes,
            decoration: const InputDecoration(
              hintText: 'Add a short note for the provider',
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Text(
              'Pricing, SHIELD Benefit coverage, service selection, and live slots are not returned by the current appointment contract. No amount is calculated or reserved when you send this request.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: _controller.isSubmitting
                ? 'Sending request…'
                : 'Send visit request',
            isLoading: _controller.isSubmitting,
            onPressed: _controller.provider == null || _controller.isSubmitting
                ? null
                : _controller.submit,
          ),
        ],
      );
    },
  );

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _controller.preferredDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_controller.preferredDateTime),
    );
    if (time == null || !context.mounted) return;
    _controller.setPreferredDateTime(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _ProviderPicker extends StatelessWidget {
  const _ProviderPicker({
    required this.controller,
    required this.search,
    required this.onSearch,
  });
  final CustomerBookingController controller;
  final TextEditingController search;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        controller: search,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: 'Search active providers',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearch,
          ),
        ),
      ),
      if (controller.isLoadingProvider) const LinearProgressIndicator(),
      ...controller.providers.map(
        (provider) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppCard(
            onTap: () => controller.selectProvider(provider),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(provider.name),
              subtitle: Text(
                [
                  provider.typeLabel,
                  provider.businessName,
                ].whereType<String>().join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
      if (!controller.isLoadingProvider && controller.providers.isEmpty)
        TextButton(onPressed: onSearch, child: const Text('Find providers')),
    ],
  );
}

class _SelectedProviderCard extends StatelessWidget {
  const _SelectedProviderCard({required this.provider, required this.onChange});
  final CustomerProvider provider;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            provider.name,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(onPressed: onChange, child: const Text('Change')),
      ],
    ),
  );
}

class _BookingSuccess extends StatelessWidget {
  const _BookingSuccess({required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context) => Center(
    child: AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.shieldGreen,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text('Visit request sent', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text('Reference: $appointmentId'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/portal/customer/appointments'),
            child: const Text('View visits'),
          ),
        ],
      ),
    ),
  );
}

Map<String, String> _query(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.queryParameters;
  } catch (_) {
    return const {};
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month}/${value.year} · $hour:${value.minute.toString().padLeft(2, '0')} $suffix';
}
