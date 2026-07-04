enum AdminViewType {
  table,
  detail,
  cards,
  timeline,
  metrics,
  split,
}

class AdminViewDefinition {
  const AdminViewDefinition({
    required this.id,
    required this.type,
    required this.title,
  });

  final String id;
  final AdminViewType type;
  final String title;
}
