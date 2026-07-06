enum AdminActionType {
  create('create'),
  update('update'),
  delete('delete'),
  export('export'),
  refresh('refresh'),
  duplicate('duplicate'),
  archive('archive'),
  command('workspace-action');

  const AdminActionType(this.commandType);

  final String commandType;
}

class AdminActionDefinition {
  const AdminActionDefinition({
    required this.id,
    required this.type,
    required this.label,
    this.permissionKey,
  });

  final String id;
  final AdminActionType type;
  final String label;
  final String? permissionKey;
}

class AdminActionExecution {
  const AdminActionExecution({
    required this.workspaceId,
    required this.userId,
    required this.action,
    this.payload = const <String, Object?>{},
    this.correlationId,
    this.causationId,
  });

  final String workspaceId;
  final String userId;
  final AdminActionDefinition action;
  final Map<String, Object?> payload;
  final String? correlationId;
  final String? causationId;
}

class AdminWorkspaceActionConfirmation {
  const AdminWorkspaceActionConfirmation({
    required this.title,
    required this.body,
    required this.confirmText,
  });

  final String title;
  final String body;
  final String confirmText;
}

class AdminWorkspaceActionDialog {
  const AdminWorkspaceActionDialog({required this.type, this.formId});

  final String type;
  final String? formId;
}

class AdminWorkspaceActionDescriptor {
  const AdminWorkspaceActionDescriptor({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
    required this.permission,
    required this.endpoint,
    required this.method,
    required this.refreshAfterSuccess,
    this.requiresSelection = false,
    this.allowBulk = false,
    this.confirmation,
    this.dialog,
    this.successMessage,
  });

  factory AdminWorkspaceActionDescriptor.fromMap(Map<String, dynamic> map) {
    return AdminWorkspaceActionDescriptor(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      icon: (map['icon'] ?? 'bolt_outlined').toString(),
      color: (map['color'] ?? 'primary').toString(),
      category: (map['category'] ?? 'secondary').toString(),
      permission: (map['permission'] ?? '').toString(),
      endpoint: (map['endpoint'] ?? '').toString(),
      method: (map['method'] ?? 'POST').toString(),
      refreshAfterSuccess: map['refreshAfterSuccess'] == true,
      requiresSelection: map['requiresSelection'] == true,
      allowBulk: map['allowBulk'] == true,
      confirmation: map['confirmation'] is Map<String, dynamic>
          ? AdminWorkspaceActionConfirmation(
              title: (map['confirmation']['title'] ?? '').toString(),
              body: (map['confirmation']['body'] ?? '').toString(),
              confirmText: (map['confirmation']['confirmText'] ?? '')
                  .toString(),
            )
          : null,
      dialog: map['dialog'] is Map<String, dynamic>
          ? AdminWorkspaceActionDialog(
              type: (map['dialog']['type'] ?? 'FORM').toString(),
              formId: map['dialog']['formId']?.toString(),
            )
          : null,
      successMessage: map['successMessage']?.toString(),
    );
  }

  final String id;
  final String label;
  final String icon;
  final String color;
  final String category;
  final String permission;
  final String endpoint;
  final String method;
  final bool refreshAfterSuccess;
  final bool requiresSelection;
  final bool allowBulk;
  final AdminWorkspaceActionConfirmation? confirmation;
  final AdminWorkspaceActionDialog? dialog;
  final String? successMessage;

  Map<String, Object?> toPayload() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'icon': icon,
      'color': color,
      'category': category,
      'permission': permission,
      'endpoint': endpoint,
      'method': method,
      'refreshAfterSuccess': refreshAfterSuccess,
      'requiresSelection': requiresSelection,
      'allowBulk': allowBulk,
      if (successMessage != null) 'successMessage': successMessage,
      if (confirmation != null)
        'confirmation': <String, Object?>{
          'title': confirmation!.title,
          'body': confirmation!.body,
          'confirmText': confirmation!.confirmText,
        },
      if (dialog != null)
        'dialog': <String, Object?>{
          'type': dialog!.type,
          if (dialog!.formId != null) 'formId': dialog!.formId,
        },
    };
  }
}
