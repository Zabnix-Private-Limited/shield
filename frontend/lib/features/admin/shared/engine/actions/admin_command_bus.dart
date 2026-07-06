import 'admin_command_definition.dart';

typedef AdminCommandHandler =
    Future<Object?> Function(AdminCommandDefinition command);

typedef AdminCommandMiddleware =
    Future<Object?> Function(
      AdminCommandDefinition command,
      Future<Object?> Function(AdminCommandDefinition command) next,
    );

class AdminCommandBus {
  final Map<String, AdminCommandHandler> _handlers =
      <String, AdminCommandHandler>{};
  final List<AdminCommandMiddleware> _middlewares = <AdminCommandMiddleware>[];

  void registerHandler(String type, AdminCommandHandler handler) {
    _handlers[type] = handler;
  }

  void addMiddleware(AdminCommandMiddleware middleware) {
    _middlewares.add(middleware);
  }

  Future<Object?> dispatch(AdminCommandDefinition command) {
    Future<Object?> invokeAt(
      int index,
      AdminCommandDefinition nextCommand,
    ) async {
      if (index >= _middlewares.length) {
        final handler = _handlers[nextCommand.type];
        if (handler == null) {
          throw StateError(
            'No handler registered for admin command "${nextCommand.type}".',
          );
        }
        return handler(nextCommand);
      }

      final middleware = _middlewares[index];
      return middleware(nextCommand, (command) => invokeAt(index + 1, command));
    }

    return invokeAt(0, command);
  }
}
