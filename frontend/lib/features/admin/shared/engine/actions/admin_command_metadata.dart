class AdminCommandMetadata {
  const AdminCommandMetadata({
    required this.commandId,
    required this.timestamp,
    this.userId,
    this.correlationId,
    this.causationId,
  });

  final String commandId;
  final DateTime timestamp;
  final String? userId;
  final String? correlationId;
  final String? causationId;
}
