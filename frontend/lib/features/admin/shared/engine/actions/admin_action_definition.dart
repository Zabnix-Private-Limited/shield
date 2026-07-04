enum AdminActionType {
  create('create'),
  update('update'),
  delete('delete'),
  export('export'),
  refresh('refresh'),
  duplicate('duplicate'),
  archive('archive');

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
