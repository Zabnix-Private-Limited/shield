import 'package:flutter/widgets.dart';

import '../../controllers/admin_workspace_controller.dart';

class AdminWorkspaceControllerScope
    extends InheritedNotifier<AdminWorkspaceController> {
  const AdminWorkspaceControllerScope({
    super.key,
    required AdminWorkspaceController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminWorkspaceController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminWorkspaceControllerScope>()
        ?.notifier;
  }
}
