enum AdminFormFieldType {
  text,
  phone,
  email,
  dropdown,
  multiSelect,
  date,
  currency,
  textarea,
  toggle,
}

class AdminFormFieldDefinition {
  const AdminFormFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
  });

  final String key;
  final String label;
  final AdminFormFieldType type;
  final bool required;
}

class AdminFormSectionDefinition {
  const AdminFormSectionDefinition({
    required this.id,
    required this.title,
    required this.fields,
  });

  final String id;
  final String title;
  final List<AdminFormFieldDefinition> fields;
}

class AdminFormDefinition {
  const AdminFormDefinition({required this.entity, required this.sections});

  final String entity;
  final List<AdminFormSectionDefinition> sections;
}
