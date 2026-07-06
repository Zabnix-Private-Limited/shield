import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../portal/presentation/portal_role_data.dart';
import 'bottom_navigation.dart';
import 'customer_app_bar.dart';

class CustomerScaffold extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;
  final String activeSectionKey;
  final Widget body;
  final Widget? drawerContent;
  final Widget? appBarTrailing;
  final bool showBottomNavigation;

  const CustomerScaffold({
    super.key,
    required this.portal,
    required this.section,
    required this.activeSectionKey,
    required this.body,
    this.drawerContent,
    this.appBarTrailing,
    this.showBottomNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      drawer: drawerContent == null
          ? null
          : Drawer(child: SafeArea(child: drawerContent!)),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Builder(
          builder: (context) => SafeArea(
            bottom: false,
            child: CustomerAppBar(
              portal: portal,
              section: section,
              onMenuPressed: drawerContent == null
                  ? null
                  : () => Scaffold.of(context).openDrawer(),
              trailing: appBarTrailing,
            ),
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: showBottomNavigation
          ? CustomerBottomNavigation(activeSectionKey: activeSectionKey)
          : null,
    );
  }
}
