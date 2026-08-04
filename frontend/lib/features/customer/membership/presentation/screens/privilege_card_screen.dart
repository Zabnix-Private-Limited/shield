import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    this.requestPhysicalCard,
  });

  final MembershipController? controller;
  final Future<Customer> Function()? loadCustomer;
  final Future<Map<String, dynamic>> Function()? loadCardProfile;
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
  bool _requestingPhysicalCard = false;

  @override
  void initState() {
    super.initState();
    _ownsMembershipController = widget.controller == null;
    _membershipController = widget.controller ?? MembershipController();
    _membershipController.load();
    _customer = _loadCustomer();
    _cardProfile = _loadCardProfile();
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
                  if (membership.cardQrPayload?.isNotEmpty == true)
                    _DigitalCard(
                      customer: customerSnapshot.data!,
                      membership: membership,
                    )
                  else
                    const _DigitalCardUnavailable(),
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
      widget.loadCustomer?.call() ??
      ApiService.getCustomerProfile(
        ApiService.requireAuthenticatedCustomerId(),
      );

  Future<Map<String, dynamic>> _loadCardProfile() async {
    try {
      return await (widget.loadCardProfile?.call() ??
          ApiService.getCustomerCardProfile(
            ApiService.requireAuthenticatedCustomerId(),
          ));
    } catch (_) {
      return const {'_unavailable': true};
    }
  }

  Future<void> _refresh() async {
    await _membershipController.refresh();
    if (mounted) {
      setState(() => _cardProfile = _loadCardProfile());
    }
    await _cardProfile;
  }

  Future<void> _requestPhysicalCard() async {
    setState(() => _requestingPhysicalCard = true);
    try {
      final request = widget.requestPhysicalCard != null
          ? await widget.requestPhysicalCard!()
          : await ApiService.requestCustomerPhysicalCard(
              ApiService.requireAuthenticatedCustomerId(),
            );
      if (!mounted) return;
      setState(() => _cardProfile = _loadCardProfile());
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: membership.cardQrPayload!,
                  size: 92,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF082B70),
                  ),
                ),
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
        ? 'Request a physical SHIELD card for your membership.'
        : action == 'VIEW_CARD' && request == null
        ? 'Your digital privilege card is issued. Physical-card history is not available yet.'
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
          Text('Physical card', style: AppTypography.h5),
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
                  requesting ? 'Submitting…' : 'Request physical card',
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
            'Physical card status is unavailable right now.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
