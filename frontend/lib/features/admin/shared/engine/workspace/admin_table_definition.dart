import '../actions/admin_action_definition.dart';

enum AdminColumnValueType {
  text,
  number,
  currency,
  date,
  status,
}

enum AdminFilterType {
  text,
  select,
  dateRange,
  multiSelect,
}

class AdminTableColumnDefinition {
  const AdminTableColumnDefinition({
    required this.key,
    required this.label,
    required this.valueType,
  });

  final String key;
  final String label;
  final AdminColumnValueType valueType;
}

class AdminFilterDefinition {
  const AdminFilterDefinition({
    required this.key,
    required this.label,
    required this.type,
  });

  final String key;
  final String label;
  final AdminFilterType type;
}

class AdminSortDefinition {
  const AdminSortDefinition({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

class AdminTableDefinition {
  const AdminTableDefinition({
    required this.entity,
    required this.columns,
    this.filters = const <AdminFilterDefinition>[],
    this.sorting = const <AdminSortDefinition>[],
    this.actions = const <AdminActionDefinition>[],
  });

  final String entity;
  final List<AdminTableColumnDefinition> columns;
  final List<AdminFilterDefinition> filters;
  final List<AdminSortDefinition> sorting;
  final List<AdminActionDefinition> actions;
}
