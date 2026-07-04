class AdminEventMetadata {
  const AdminEventMetadata({
    required this.eventId,
    required this.workspaceId,
    required this.timestamp,
    this.userId,
    this.correlationId,
    this.causationId,
  });

  final String eventId;
  final String workspaceId;
  final String? userId;
  final DateTime timestamp;
  final String? correlationId;
  final String? causationId;
}
