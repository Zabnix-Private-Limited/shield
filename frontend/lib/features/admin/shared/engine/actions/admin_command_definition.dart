class AdminCommandDefinition {
  const AdminCommandDefinition({
    required this.type,
    this.payload = const <String, Object?>{},
  });

  final String type;
  final Map<String, Object?> payload;
}
