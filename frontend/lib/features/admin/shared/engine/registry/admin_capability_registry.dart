class AdminCapabilityBinding {
  const AdminCapabilityBinding({
    required this.workspaceId,
    required this.capabilities,
  });

  final String workspaceId;
  final Set<String> capabilities;
}

class AdminCapabilityRegistry {
  final Map<String, Set<String>> _bindings = <String, Set<String>>{};

  void register(AdminCapabilityBinding binding) {
    _bindings[binding.workspaceId] = Set<String>.from(binding.capabilities);
  }

  Set<String> capabilitiesFor(String workspaceId) {
    return Set<String>.unmodifiable(
      _bindings[workspaceId] ?? const <String>{},
    );
  }

  bool supports(String workspaceId, String capability) {
    return _bindings[workspaceId]?.contains(capability) ?? false;
  }
}
