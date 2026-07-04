import 'admin_event_metadata.dart';

class AdminEventDefinition {
  const AdminEventDefinition({
    required this.name,
    required this.version,
    required this.metadata,
    this.payload = const <String, Object?>{},
  });

  final String name;
  final int version;
  final AdminEventMetadata metadata;
  final Map<String, Object?> payload;
}
