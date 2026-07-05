import 'package:flutter/material.dart';

import '../../../shared/engine/exports.dart';
import '../../../shared/presentation/widgets/admin_backend_workspace_module.dart';

class AdminReportsModule extends StatelessWidget {
  const AdminReportsModule({super.key, required this.snapshot});

  final AdminWorkspaceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AdminBackendWorkspaceModule(snapshot: snapshot);
  }
}
