import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/api_service.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'portal_support.dart';

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
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final isContact = widget.type == SupportSheetType.contact;
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      showPortalSnackBar(
        context,
        'Please add your feedback before submitting.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.submitCustomerSupport(
        message: message,
        subject: subject.isEmpty ? null : subject,
        complaintType: isContact ? 'CONTACT_US' : 'FEEDBACK',
      );

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
                      _SupportTextField(
                        controller: _subjectController,
                        label: isContact
                            ? 'Subject (optional)'
                            : 'Topic (optional)',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _SupportTextField(
                        controller: _messageController,
                        label: isContact ? 'How can we help?' : 'Your feedback',
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                ),
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
  final int maxLines;

  const _SupportTextField({
    required this.controller,
    required this.label,
    required this.textInputAction,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
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
