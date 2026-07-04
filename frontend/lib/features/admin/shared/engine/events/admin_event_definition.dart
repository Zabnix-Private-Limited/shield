class AdminEventDefinition {
  const AdminEventDefinition({
    required this.name,
    required this.version,
    this.payload = const <String, Object?>{},
  });

  final String name;
  final int version;
  final Map<String, Object?> payload;
}
