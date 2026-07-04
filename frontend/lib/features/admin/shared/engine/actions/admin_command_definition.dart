import 'admin_command_metadata.dart';

class AdminCommandDefinition {
  const AdminCommandDefinition({
    required this.type,
    required this.workspaceId,
    this.payload = const <String, Object?>{},
    this.metadata,
  });

  final String type;
  final String workspaceId;
  final Map<String, Object?> payload;
  final AdminCommandMetadata? metadata;
}
