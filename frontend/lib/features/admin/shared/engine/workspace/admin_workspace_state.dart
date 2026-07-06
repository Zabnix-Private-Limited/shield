enum AdminWorkspaceStatus {
  loading,
  refreshing,
  empty,
  error,
  permissionDenied,
  offline,
  ready,
}

class AdminWorkspaceState {
  const AdminWorkspaceState({
    required this.workspaceId,
    required this.status,
    this.payload,
    this.message,
  });

  const AdminWorkspaceState.loading({
    required String workspaceId,
    Object? payload,
    String? message,
  }) : this(
         workspaceId: workspaceId,
         status: AdminWorkspaceStatus.loading,
         payload: payload,
         message: message,
       );

  const AdminWorkspaceState.ready({
    required String workspaceId,
    Object? payload,
    String? message,
  }) : this(
         workspaceId: workspaceId,
         status: AdminWorkspaceStatus.ready,
         payload: payload,
         message: message,
       );

  const AdminWorkspaceState.empty({
    required String workspaceId,
    Object? payload,
    String? message,
  }) : this(
         workspaceId: workspaceId,
         status: AdminWorkspaceStatus.empty,
         payload: payload,
         message: message,
       );

  const AdminWorkspaceState.permissionDenied({
    required String workspaceId,
    Object? payload,
    String? message,
  }) : this(
         workspaceId: workspaceId,
         status: AdminWorkspaceStatus.permissionDenied,
         payload: payload,
         message: message,
       );

  final String workspaceId;
  final AdminWorkspaceStatus status;
  final Object? payload;
  final String? message;

  AdminWorkspaceState toRefreshing({String? message}) {
    return AdminWorkspaceState(
      workspaceId: workspaceId,
      status: AdminWorkspaceStatus.refreshing,
      payload: payload,
      message: message ?? this.message,
    );
  }

  AdminWorkspaceState toError(String message) {
    return AdminWorkspaceState(
      workspaceId: workspaceId,
      status: AdminWorkspaceStatus.error,
      payload: payload,
      message: message,
    );
  }
}
