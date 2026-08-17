import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/shimmer_loading.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../shared/widgets/error_card.dart';
import 'customer_visits_controller.dart';

class CustomerVisitsScreen extends StatefulWidget {
  const CustomerVisitsScreen({super.key, this.controller});
  final CustomerVisitsController? controller;

  @override
  State<CustomerVisitsScreen> createState() => _CustomerVisitsScreenState();
}

class _CustomerVisitsScreenState extends State<CustomerVisitsScreen> {
  late final CustomerVisitsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CustomerVisitsController();
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      if (_controller.isLoading && _controller.appointments.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: ShimmerListLoading(),
        );
      }
      if (_controller.error != null && _controller.appointments.isEmpty) {
        return ErrorCard(
          title: _errorTitle(_controller.errorKind),
          message: _errorMessage(_controller.errorKind),
          onRetry: _controller.load,
        );
      }
      final visits = _controller.visible;
      return RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Row(
              children: [
                Expanded(child: Text('My Visits', style: AppTypography.h3)),
                TextButton(
                  onPressed: () =>
                      context.go('/portal/customer/book-appointment'),
                  child: const Text('Book a visit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Appointment statuses are shown exactly as returned by SHIELD.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            _VisitFilters(controller: _controller),
            if (_controller.error != null) ...[
              const SizedBox(height: 12),
              ErrorCard(
                title: _errorTitle(_controller.errorKind),
                message:
                    '${_errorMessage(_controller.errorKind)} Showing your last available visit list.',
                onRetry: _controller.load,
              ),
            ],
            const SizedBox(height: 16),
            if (visits.isEmpty)
              AppCard(
                child: Text(
                  'No ${_labelFor(_controller.filter)} visits are available.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              )
            else
              ...visits.map(
                (visit) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VisitCard(
                    visit: visit,
                    isMutating: _controller.isMutating,
                    onCancel: () => _confirmCancel(visit),
                    onReschedule: () => _reschedule(visit),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Future<void> _confirmCancel(Appointment visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel visit?'),
        content: const Text(
          'This sends a cancellation request to SHIELD. It cannot be undone here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep visit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel visit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await _controller.cancel(visit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Visit cancelled.' : 'Cancellation could not be completed.',
        ),
      ),
    );
  }

  Future<void> _reschedule(Appointment visit) async {
    final date = await showDatePicker(
      context: context,
      initialDate: visit.appointmentDate.isAfter(DateTime.now())
          ? visit.appointmentDate
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(visit.appointmentDate),
      helpText: 'Preferred time',
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!value.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a preferred date and time in the future.'),
        ),
      );
      return;
    }
    final success = await _controller.reschedule(visit, value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Visit rescheduled.'
              : 'Rescheduling could not be completed.',
        ),
      ),
    );
  }
}

class _VisitFilters extends StatelessWidget {
  const _VisitFilters({required this.controller});
  final CustomerVisitsController controller;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: CustomerVisitsFilter.values
          .map(
            (filter) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_labelFor(filter)),
                selected: controller.filter == filter,
                onSelected: (_) => controller.setFilter(filter),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.isMutating,
    required this.onCancel,
    required this.onReschedule,
  });
  final Appointment visit;
  final bool isMutating;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.doctorName ?? visit.typeLabel, style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              '${_date(visit.appointmentDate)} · ${visit.department ?? visit.typeLabel}',
            ),
            const SizedBox(height: 8),
            Text('Status: ${visit.statusLabel}'),
            if ((visit.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(visit.notes!),
            ],
            const SizedBox(height: 12),
            Text(
              'Pricing, coverage, instructions, online links, and status history are not available in the current customer appointment contract.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(child: Icon(_icon(visit.status))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                visit.doctorName ?? visit.typeLabel,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _date(visit.appointmentDate),
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 4),
              Text(
                visit.statusLabel,
                style: AppTypography.tiny.copyWith(
                  color: _color(visit.status),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (_actionable(visit.status))
          PopupMenuButton<String>(
            enabled: !isMutating,
            onSelected: (value) =>
                value == 'cancel' ? onCancel() : onReschedule(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
              PopupMenuItem(value: 'cancel', child: Text('Cancel')),
            ],
          ),
      ],
    ),
  );
}

String _labelFor(CustomerVisitsFilter filter) => switch (filter) {
  CustomerVisitsFilter.upcoming => 'Upcoming',
  CustomerVisitsFilter.completed => 'Completed',
  CustomerVisitsFilter.cancelled => 'Cancelled',
  CustomerVisitsFilter.all => 'All',
};

String _errorTitle(CustomerVisitsErrorKind? kind) => switch (kind) {
  CustomerVisitsErrorKind.offline => 'You appear to be offline',
  CustomerVisitsErrorKind.unauthorized => 'Your session has expired',
  CustomerVisitsErrorKind.malformed => 'Visits data could not be read',
  CustomerVisitsErrorKind.unavailable || null => 'Visits unavailable',
};

String _errorMessage(CustomerVisitsErrorKind? kind) => switch (kind) {
  CustomerVisitsErrorKind.offline =>
    'Reconnect to the internet and try again. Your saved visits remain available when present.',
  CustomerVisitsErrorKind.unauthorized =>
    'Sign in again to securely load your appointments.',
  CustomerVisitsErrorKind.malformed =>
    'SHIELD could not read the appointment response. Please try again shortly.',
  CustomerVisitsErrorKind.unavailable ||
  null => 'Your appointment list could not be loaded.',
};
bool _actionable(AppointmentStatus status) =>
    status != AppointmentStatus.cancelled &&
    status != AppointmentStatus.completed;
String _date(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month}/${value.year} · $hour:${value.minute.toString().padLeft(2, '0')} $suffix';
}

IconData _icon(AppointmentStatus status) =>
    status == AppointmentStatus.cancelled
    ? Icons.cancel_outlined
    : status == AppointmentStatus.completed
    ? Icons.task_alt_outlined
    : Icons.event_outlined;
Color _color(AppointmentStatus status) => status == AppointmentStatus.cancelled
    ? AppColors.error
    : status == AppointmentStatus.completed
    ? AppColors.shieldGreen
    : AppColors.shieldBlue;
