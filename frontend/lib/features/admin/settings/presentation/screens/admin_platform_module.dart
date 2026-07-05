import 'package:flutter/material.dart';

import '../../../governance/presentation/widgets/admin_governance_workspace_module.dart';
import '../../../shared/exports.dart';

class AdminPlatformModule extends StatelessWidget {
  const AdminPlatformModule({super.key, required this.snapshot});

  final AdminWorkspaceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AdminGovernanceWorkspaceModule(snapshot: snapshot);
  }
}
