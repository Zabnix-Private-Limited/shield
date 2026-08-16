import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../shared/widgets/error_card.dart';
import '../controllers/membership_controller.dart';

class CustomerPrivilegeCardScreen extends StatefulWidget {
  const CustomerPrivilegeCardScreen({
    super.key,
    this.controller,
    this.loadCustomer,
    this.loadCardProfile,
    this.loadCardHistory,
    this.requestPhysicalCard,
  });

  final MembershipController? controller;
  final Future<Customer> Function()? loadCustomer;
  final Future<Map<String, dynamic>> Function()? loadCardProfile;
  final Future<List<Map<String, dynamic>>> Function()? loadCardHistory;
  final Future<Map<String, dynamic>> Function()? requestPhysicalCard;

  @override
  State<CustomerPrivilegeCardScreen> createState() =>
      _CustomerPrivilegeCardScreenState();
}

class _CustomerPrivilegeCardScreenState
    extends State<CustomerPrivilegeCardScreen> {
  late final MembershipController _membershipController;
  late final bool _ownsMembershipController;
  late Future<Customer> _customer;
  late Future<Map<String, dynamic>> _cardProfile;
  late Future<List<Map<String, dynamic>>> _cardHistory;
  bool _requestingPhysicalCard = false;

  @override
  void initState() {
    super.initState();
    _ownsMembershipController = widget.controller == null;
    _membershipController = widget.controller ?? MembershipController();
    _membershipController.load();
    _customer = _loadCustomer();
    _cardProfile = _loadCardProfile();
    _cardHistory = _loadCardHistory();
  }

  @override
  void dispose() {
    if (_ownsMembershipController) {
      _membershipController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _membershipController,
      builder: (context, _) {
        if (_membershipController.isLoading && !_membershipController.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_membershipController.error != null &&
            !_membershipController.hasData) {
          return ErrorCard(
            title: 'Privilege card unavailable',
            message: 'Your membership card could not be loaded.',
            onRetry: _membershipController.load,
          );
        }
        final membership = _membershipController.membership;
        if (membership == null) {
          return ErrorCard(
            title: 'Membership unavailable',
            message: 'Your membership details could not be loaded.',
            onRetry: _membershipController.refresh,
          );
        }
        return FutureBuilder<Customer>(
          future: _customer,
          builder: (context, customerSnapshot) {
            if (customerSnapshot.hasError) {
              return ErrorCard(
                title: 'Privilege card unavailable',
                message: 'Your customer profile could not be loaded.',
                onRetry: () => setState(() => _customer = _loadCustomer()),
              );
            }
            if (!customerSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (membership.cardNumber?.isNotEmpty == true)
                    _DigitalCard(
                      customer: customerSnapshot.data!,
                      membership: membership,
                    )
                  else
                    const _DigitalCardUnavailable(),
                  const SizedBox(height: 12),
                  const _QrUnavailable(),
                  const SizedBox(height: 24),
                  Text('Card details', style: AppTypography.h4),
                  const SizedBox(height: 12),
                  _DetailRow('Plan', membership.tierLabel),
                  _DetailRow(
                    'Valid until',
                    DateFormat('dd MMM yyyy').format(membership.endDate),
                  ),
                  if (membership.cardIssuedAt != null)
                    _DetailRow(
                      'Issued on',
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(membership.cardIssuedAt!),
                    ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _cardProfile,
                    builder: (context, cardSnapshot) {
                      if (cardSnapshot.data?['_unavailable'] == true) {
                        return _PhysicalCardUnavailable(
                          onRetry: () =>
                              setState(() => _cardProfile = _loadCardProfile()),
                        );
                      }
                      if (!cardSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        );
                      }
                      return _PhysicalCardPanel(
                        profile: cardSnapshot.data!,
                        requesting: _requestingPhysicalCard,
                        onRequest: _requestPhysicalCard,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _cardHistory,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _CardHistoryUnavailable();
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        );
                      }
                      return _CardHistoryPanel(requests: snapshot.data!);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Present this QR code only to an authorised SHIELD provider for membership verification.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Customer> _loadCustomer() =>
      widget.loadCustomer?.call() ?? ApiService.getMyCustomerProfile();

  Future<Map<String, dynamic>> _loadCardProfile() async {
    try {
      return await (widget.loadCardProfile?.call() ??
          ApiService.getOwnCustomerCardProfile());
    } catch (_) {
      return const {'_unavailable': true};
    }
  }

  Future<List<Map<String, dynamic>>> _loadCardHistory() =>
      widget.loadCardHistory?.call() ?? ApiService.getOwnPhysicalCardRequests();

  Future<void> _refresh() async {
    await _membershipController.refresh();
    if (mounted) {
      setState(() => _cardProfile = _loadCardProfile());
      setState(() => _cardHistory = _loadCardHistory());
    }
    await _cardProfile;
  }

  Future<void> _requestPhysicalCard() async {
    setState(() => _requestingPhysicalCard = true);
    try {
      final request = widget.requestPhysicalCard != null
          ? await widget.requestPhysicalCard!()
          : await ApiService.requestOwnPhysicalCard();
      if (!mounted) return;
      setState(() => _cardProfile = _loadCardProfile());
      setState(() => _cardHistory = _loadCardHistory());
      final status =
          request['status']?.toString().replaceAll('_', ' ') ?? 'Unavailable';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Physical card requested'),
          content: Text('Request status: $status'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Physical card request could not be submitted.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _requestingPhysicalCard = false);
    }
  }
}

class _DigitalCard extends StatelessWidget {
  const _DigitalCard({required this.customer, required this.membership});

  final Customer customer;
  final Membership membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1558D4), Color(0xFF082B70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SHIELD',
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _StatusPill(status: membership.cardStatus ?? 'ACTIVE'),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            customer.fullName,
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            membership.tierLabel,
            style: AppTypography.small.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEMBERSHIP NO.',
                      style: AppTypography.tiny.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      membership.customerCode,
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 42,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DigitalCardUnavailable extends StatelessWidget {
  const _DigitalCardUnavailable();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FC),
      border: Border.all(color: const Color(0xFFE3E9F2)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.badge_outlined, color: AppColors.shieldBlue, size: 32),
        const SizedBox(height: 12),
        Text('Digital card unavailable', style: AppTypography.h4),
        const SizedBox(height: 4),
        Text(
          'Your digital privilege card will appear here after SHIELD issues it.',
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
      ],
    ),
  );
}

class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FC),
      border: Border.all(color: const Color(0xFFE3E9F2)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.qr_code_scanner_outlined, color: AppColors.gray),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QR verification unavailable', style: AppTypography.h5),
              const SizedBox(height: 4),
              Text(
                'A signed, server-verifiable QR contract is required before QR display is enabled.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      status.replaceAll('_', ' '),
      style: AppTypography.tiny.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE3E9F2)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
        ),
        Text(
          value,
          style: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _PhysicalCardPanel extends StatelessWidget {
  const _PhysicalCardPanel({
    required this.profile,
    required this.requesting,
    required this.onRequest,
  });

  final Map<String, dynamic> profile;
  final bool requesting;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final action = profile['action']?.toString() ?? '';
    final request = profile['physicalCardRequest'] as Map?;
    final status = request?['status']?.toString() ?? action;
    final canRequest = action == 'REQUEST_PHYSICAL_CARD';
    final description = canRequest
        ? 'Apply for your SHIELD membership card.'
        : action == 'VIEW_CARD' && request == null
        ? 'Your digital SHIELD membership card is ready to view.'
        : 'Request status: ${status.replaceAll('_', ' ')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        border: Border.all(color: const Color(0xFFE3E9F2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Membership card', style: AppTypography.h5),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          if (canRequest) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: requesting ? null : onRequest,
                child: Text(
                  requesting ? 'Submitting…' : 'Apply for membership card',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhysicalCardUnavailable extends StatelessWidget {
  const _PhysicalCardUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FC),
      border: Border.all(color: const Color(0xFFE3E9F2)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.credit_card_off_outlined, color: AppColors.gray),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Membership card status is unavailable right now.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _CardHistoryPanel extends StatelessWidget {
  const _CardHistoryPanel({required this.requests});
  final List<Map<String, dynamic>> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _CardHistoryUnavailable(
        message: 'No physical-card requests have been recorded.',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        border: Border.all(color: const Color(0xFFE3E9F2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Physical card history', style: AppTypography.h5),
          const SizedBox(height: 8),
          ...requests
              .take(3)
              .map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    '${request['status']?.toString().replaceAll('_', ' ') ?? 'UNKNOWN'} • ${_formatRequestDate(request['requestedAt'])}',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _CardHistoryUnavailable extends StatelessWidget {
  const _CardHistoryUnavailable({
    this.message = 'Physical-card history is unavailable right now.',
  });
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FC),
      border: Border.all(color: const Color(0xFFE3E9F2)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message,
      style: AppTypography.small.copyWith(color: AppColors.gray),
    ),
  );
}

String _formatRequestDate(dynamic value) {
  final date = value == null ? null : DateTime.tryParse(value.toString());
  return date == null
      ? 'Date unavailable'
      : DateFormat('dd MMM yyyy').format(date);
}
