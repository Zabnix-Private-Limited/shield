import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/dashboard/domain/entities/dashboard_entity.dart';
import 'package:shield/features/customer/dashboard/presentation/widgets/marketing_banner_carousel.dart';

void main() {
  testWidgets('renders a database-configured local banner image', (
    tester,
  ) async {
    const banner = DashboardBannerEntity(
      id: 'demo-banner',
      title: 'Demo wellness',
      subtitle: 'Database-configured banner.',
      imageUrl: 'assets/images/operations/wellness-nutrition.jpg',
      altText: 'Wellness ingredients.',
      ctaLabel: 'Open shop',
      ctaRoute: '/portal/customer/wellness-shop',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OperationsBannerCarousel(banners: [banner])),
      ),
    );

    expect(find.text('Demo wellness'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
