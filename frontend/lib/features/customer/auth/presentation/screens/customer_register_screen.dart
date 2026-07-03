import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/auth_error_messages.dart';
import '../../data/customer_auth_repository.dart';
import '../widgets/shield_date_picker_sheet.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _dob;
  String _gender = 'MALE';
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (CustomerAuthRepository.instance.pendingPhoneNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/customer/login');
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final selected = await showShieldDatePickerSheet(
      context,
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 1, now.month, now.day),
      initialDate: DateTime(now.year - 25, now.month, now.day),
    );
    if (selected != null) {
      setState(() {
        _dob = selected;
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_dob == null) {
      setState(() {
        _errorText = 'Select date of birth.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await CustomerAuthRepository.instance.registerCustomer(
        name: _nameController.text,
        dob: _dob!,
        gender: _gender,
      );
      if (!mounted) {
        return;
      }
      context.go('/portal/customer/dashboard');
    } catch (error) {
      setState(() {
        _errorText = _cleanErrorMessage(error);
      });
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/customer/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete your registration', style: AppTypography.h3),
                    const SizedBox(height: 10),
                    Text(
                      'We found your phone number, but your SHIELD customer profile is not set up yet.',
                      style: AppTypography.body.copyWith(color: AppColors.gray),
                    ),
                    const SizedBox(height: 24),
                    _LabeledField(
                      label: 'Full name',
                      child: TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Enter your full name'),
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) {
                            return 'Enter your full name.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Date of birth',
                      child: InkWell(
                        onTap: _pickDob,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _inputDecoration('Select DOB'),
                          child: Text(
                            _dob == null
                                ? 'Select date of birth'
                                : _formatDob(_dob!),
                            style: AppTypography.body.copyWith(
                              color: _dob == null
                                  ? AppColors.gray
                                  : AppColors.shieldNavy,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Gender',
                      child: Wrap(
                        spacing: 10,
                        children: ['MALE', 'FEMALE', 'OTHER'].map((value) {
                          final selected = _gender == value;
                          return ChoiceChip(
                            label: Text(value),
                            selected: selected,
                            onSelected: (_) => setState(() => _gender = value),
                            selectedColor: AppColors.shieldBlue.withValues(
                              alpha: 0.12,
                            ),
                            labelStyle: AppTypography.small.copyWith(
                              color: selected
                                  ? AppColors.shieldBlue
                                  : AppColors.darkGray,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorText!,
                        style: AppTypography.small.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.shieldBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'Done',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppColors.lightGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: hintText == 'Select DOB'
          ? const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.shieldBlue,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.shieldBlue, width: 1.2),
      ),
    );
  }

  String _formatDob(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _cleanErrorMessage(Object error) {
    return AuthErrorMessages.resolve(
      error,
      flow: AuthFlow.customerRegistration,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: AppColors.darkGray,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
