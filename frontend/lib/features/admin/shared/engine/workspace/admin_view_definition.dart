import '../actions/admin_action_definition.dart';
import 'admin_form_definition.dart';
import 'admin_table_definition.dart';

enum AdminViewType { table, detail, cards, timeline, metrics, split }

class AdminViewDefinition {
  const AdminViewDefinition({
    required this.id,
    required this.type,
    required this.title,
    this.table,
    this.form,
    this.actions = const <AdminActionDefinition>[],
  });

  final String id;
  final AdminViewType type;
  final String title;
  final AdminTableDefinition? table;
  final AdminFormDefinition? form;
  final List<AdminActionDefinition> actions;
}
