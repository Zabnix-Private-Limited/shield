import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/portal_support.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _category = 'PHARMACY';
  String _consultationMode = 'IN_PERSON';
  String _specialist = 'DOCTOR';
  String _uploadStatus = 'No prescription selected';

  void _showAction(String message) {
    showPortalSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AppPageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a care service', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Explore pharmacy, lab, homecare, and consultation services in one mobile flow.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('PHARMACY', 'Pharmacy'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('LAB', 'Laboratory'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('HOMECARE', 'Home Care'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('CONSULT', 'Consultation'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_category == 'PHARMACY') _buildPharmacyView(),
              if (_category == 'LAB') _buildLabView(),
              if (_category == 'HOMECARE') _buildHomecareView(),
              if (_category == 'CONSULT') _buildConsultationView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _category = value),
      selectedColor: AppColors.shieldBlue.withValues(alpha: 0.14),
      labelStyle: AppTypography.small.copyWith(
        color: selected ? AppColors.shieldBlue : AppColors.darkGray,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildPharmacyView() {
    final regularProducts = [
      {'name': 'Metformin 500mg', 'qty': '30 tablets', 'price': '₹128'},
      {'name': 'Telmisartan 40mg', 'qty': '15 tablets', 'price': '₹214'},
      {'name': 'Vitamin D3', 'qty': '1 bottle', 'price': '₹180'},
      {'name': 'Calcium Tablets', 'qty': '30 tablets', 'price': '₹145'},
    ];
    final suggestions = [
      {'name': 'Blood Sugar Strips', 'desc': 'Often bought with diabetic refill medicine.', 'price': '₹420'},
      {'name': 'Joint Support Oil', 'desc': 'Popular among repeat orthopedic members.', 'price': '₹185'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prescription Upload', style: AppTypography.h5),
              const SizedBox(height: 8),
              Text(
                _uploadStatus,
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Select File',
                      onPressed: () {
                        setState(() {
                          _uploadStatus = 'Prescription_nihal_june_2026.pdf selected';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Upload',
                      type: AppButtonType.outline,
                      onPressed: () => _showAction(
                        'Prescription uploaded. Pharmacy review flow is ready in the frontend.',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Frequently Purchased Products', style: AppTypography.h5),
        const SizedBox(height: 12),
        ...regularProducts.map((product) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined, color: AppColors.shieldBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['name']!, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                        Text('${product['qty']} • ${product['price']}', style: AppTypography.tiny.copyWith(color: AppColors.gray)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAction('${product['name']} added to reorder list.'),
                    icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.shieldGreen),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Text('Suggested for You', style: AppTypography.h5),
        const SizedBox(height: 12),
        ...suggestions.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name']!, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item['desc']!, style: AppTypography.small.copyWith(color: AppColors.gray)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['price']!, style: AppTypography.small.copyWith(fontWeight: FontWeight.w700)),
                      AppButton(
                        text: 'Add',
                        height: 40,
                        onPressed: () => _showAction('${item['name']} added to cart.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLabView() {
    final tests = [
      {'name': 'Complete Blood Count', 'price': '₹350', 'time': 'Results in 12 hours'},
      {'name': 'Lipid Profile', 'price': '₹600', 'time': 'Results in 24 hours'},
      {'name': 'HbA1c', 'price': '₹450', 'time': 'Results in 8 hours'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tests.map((test) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: AppColors.shieldBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test['name']!, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                      Text(test['time']!, style: AppTypography.tiny.copyWith(color: AppColors.gray)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(test['price']!, style: AppTypography.small.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Book Test',
                      height: 40,
                      onPressed: () => _showAction('${test['name']} booking request created.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHomecareView() {
    final services = [
      {'name': 'Home Nursing', 'desc': 'Vitals, injections, follow-up nursing support'},
      {'name': 'Home Collection', 'desc': 'Sample collection for lab packages'},
      {'name': 'Elderly Care Visit', 'desc': 'Care assistant and medication supervision'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: services.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service['name']!, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(service['desc']!, style: AppTypography.small.copyWith(color: AppColors.gray)),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Request Service',
                  onPressed: () => _showAction('${service['name']} request logged.'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsultationView() {
    final specialists = [
      {'key': 'DOCTOR', 'label': 'Doctor'},
      {'key': 'DENTAL', 'label': 'Dental'},
      {'key': 'COSMETIC', 'label': 'Cosmetic'},
      {'key': 'DIETITIAN', 'label': 'Dietitian'},
    ];

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consultation Booking', style: AppTypography.h5),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialists.map((specialist) {
              final selected = _specialist == specialist['key'];
              return ChoiceChip(
                label: Text(specialist['label']!),
                selected: selected,
                onSelected: (_) => setState(() => _specialist = specialist['key']!),
                selectedColor: AppColors.shieldBlue.withValues(alpha: 0.14),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Consultation Mode', style: AppTypography.small.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['IN_PERSON', 'TELE', 'VIDEO'].map((mode) {
              final selected = _consultationMode == mode;
              return ChoiceChip(
                label: Text(mode == 'IN_PERSON' ? 'In-Person' : mode == 'TELE' ? 'Tele' : 'Video'),
                selected: selected,
                onSelected: (_) => setState(() => _consultationMode = mode),
                selectedColor: AppColors.shieldGreen.withValues(alpha: 0.14),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Book Consultation Slot',
            onPressed: () => _showAction(
              '$_specialist consultation requested in $_consultationMode mode.',
            ),
          ),
          if (_specialist == 'DIETITIAN') ...[
            const SizedBox(height: 20),
            Text('Preset Nutrition Plans', style: AppTypography.h5),
            const SizedBox(height: 12),
            ...[
              'Diabetic-Friendly Diet',
              'Weight Loss Plan',
              'Hypertension Management Plan',
            ].map((plan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu, color: AppColors.shieldBlue),
                      const SizedBox(width: 12),
                      Expanded(child: Text(plan, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
                      AppButton(
                        text: 'Choose',
                        height: 38,
                        onPressed: () => _showAction('$plan selected.'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
