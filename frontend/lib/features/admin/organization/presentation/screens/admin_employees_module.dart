import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminEmployeesModule extends StatelessWidget {
  const AdminEmployeesModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Organization / Employees',
      title: 'Employee identity, sessions, and device visibility',
      description:
          'Control internal users, session health, device trust, and operational access without losing RBAC context.',
      primaryAction: AdminActionItem(label: 'Create user', icon: Icons.person_add_alt_outlined),
      secondaryAction: AdminActionItem(label: 'View sessions', icon: Icons.devices_outlined),
      leftTitle: 'Internal users',
      leftSubtitle: 'Roles, branch scopes, auth provider state, and access posture.',
      leftChild: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'Rahul Das', subtitle: 'SHIELD Agent • Kochi Central', meta: 'Google-auth active session', status: 'Active', color: AdminColors.success)),
          AdminEntityCard(item: AdminEntityItem(title: 'Anu Jacob', subtitle: 'CRM Executive • Trivandrum City', meta: '2 trusted devices', status: 'Active', color: AdminColors.secondary)),
          AdminEntityCard(item: AdminEntityItem(title: 'Vivek Menon', subtitle: 'Admin • Global scope', meta: 'passwordless Google auth only', status: 'Privileged', color: AdminColors.warning)),
        ],
      ),
      rightTitle: 'Session and device health',
      rightSubtitle: 'Access-state visibility that matches the auth subsystem.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Current sessions', value: '138', meta: 'active internal sessions', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Trusted devices', value: '214', meta: 'auth_device records', color: AdminColors.secondary)),
          AdminHealthRow(item: AdminHealthItem(label: 'Revoked sessions today', value: '4', meta: 'manual or security-driven', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Suspicious login attempts', value: '1', meta: 'review login history', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
