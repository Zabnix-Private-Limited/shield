import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'portal_support.dart';
import 'turnstile_challenge.dart';

enum SupportSheetType { contact, feedback }

Future<void> showCustomerSupportSheet(
  BuildContext context, {
  required SupportSheetType type,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CustomerSupportSheet(type: type),
  );
}

class _CustomerSupportSheet extends StatefulWidget {
  final SupportSheetType type;

  const _CustomerSupportSheet({required this.type});

  @override
  State<_CustomerSupportSheet> createState() => _CustomerSupportSheetState();
}

class _CustomerSupportSheetState extends State<_CustomerSupportSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _turnstileToken;
  int _rating = 5;

  bool get _requiresTurnstile => kIsWeb;
  bool get _hasTurnstileSiteKey => AppConfig.turnstileSiteKey.trim().isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final isContact = widget.type == SupportSheetType.contact;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (isContact) {
      if (name.isEmpty || phone.isEmpty || message.isEmpty) {
        showPortalSnackBar(
          context,
          'Name, phone number, and message are required.',
        );
        return;
      }
    } else if (message.isEmpty) {
      showPortalSnackBar(
        context,
        'Please add your feedback before submitting.',
      );
      return;
    }

    if (_requiresTurnstile) {
      if (!_hasTurnstileSiteKey) {
        showPortalSnackBar(
          context,
          'Web verification is not configured yet. Please try again after setup.',
        );
        return;
      }
      if ((_turnstileToken ?? '').trim().isEmpty) {
        showPortalSnackBar(
          context,
          'Please complete the web verification first.',
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (isContact) {
        await ApiService.submitSupportContact(
          name: name,
          phone: phone,
          message: message,
          email: email.isEmpty ? null : email,
          subject: subject.isEmpty ? null : subject,
          turnstileToken: _turnstileToken,
        );
      } else {
        await ApiService.submitSupportFeedback(
          name: name.isEmpty ? null : name,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          subject: subject.isEmpty ? null : subject,
          message: message,
          rating: _rating,
          turnstileToken: _turnstileToken,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      showPortalSnackBar(
        context,
        isContact
            ? 'Your contact request was sent to the SHIELD support team.'
            : 'Thanks for the feedback. The SHIELD team has saved your note.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showPortalSnackBar(
        context,
        isContact
            ? 'Support request could not be submitted right now. Please try again shortly.'
            : 'Feedback could not be submitted right now. Please try again shortly.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContact = widget.type == SupportSheetType.contact;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isContact ? 'Contact SHIELD' : 'Share feedback',
                  style: AppTypography.h4,
                ),
                const SizedBox(height: 8),
                Text(
                  isContact
                      ? 'Reach the customer support team for app, membership, or service issues.'
                      : 'Tell us what is working well and what should improve in the customer experience.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    children: [
                      if (isContact) ...[
                        _SupportTextField(
                          controller: _nameController,
                          label: 'Full name',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _SupportTextField(
                          controller: _phoneController,
                          label: 'Phone number',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        _SupportTextField(
                          controller: _nameController,
                          label: 'Name (optional)',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _SupportTextField(
                        controller: _emailController,
                        label: 'Email (optional)',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _SupportTextField(
                        controller: _subjectController,
                        label: isContact
                            ? 'Subject (optional)'
                            : 'Topic (optional)',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      if (!isContact) ...[
                        _FeedbackRatingPicker(
                          value: _rating,
                          onChanged: (value) => setState(() => _rating = value),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _SupportTextField(
                        controller: _messageController,
                        label: isContact ? 'How can we help?' : 'Your feedback',
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                ),
                if (_requiresTurnstile) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Web verification',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cloudflare Turnstile protects this public web form before it reaches SHIELD services.',
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_hasTurnstileSiteKey)
                          TurnstileChallenge(
                            siteKey: AppConfig.turnstileSiteKey.trim(),
                            onTokenChanged: (token) {
                              setState(() {
                                _turnstileToken = token;
                              });
                            },
                            onError: (message) {
                              showPortalSnackBar(context, message);
                            },
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Turnstile site key is missing from the web build configuration.',
                              style: AppTypography.small.copyWith(
                                color: AppColors.darkGray,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        type: AppButtonType.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: isContact ? 'Send request' : 'Submit feedback',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SupportTextField({
    required this.controller,
    required this.label,
    required this.textInputAction,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FeedbackRatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _FeedbackRatingPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall experience',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: List.generate(5, (index) {
            final score = index + 1;
            final isSelected = score == value;
            return InkWell(
              onTap: () => onChanged(score),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.shieldBlue.withValues(alpha: 0.12)
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.shieldBlue
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: isSelected ? AppColors.shieldBlue : AppColors.gray,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$score',
                      style: AppTypography.small.copyWith(
                        color: isSelected
                            ? AppColors.shieldBlue
                            : AppColors.darkGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
