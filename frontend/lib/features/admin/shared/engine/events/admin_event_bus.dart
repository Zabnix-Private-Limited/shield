import 'dart:async';

import 'admin_event_definition.dart';

class AdminEventBus {
  final StreamController<AdminEventDefinition> _controller =
      StreamController<AdminEventDefinition>.broadcast();

  Stream<AdminEventDefinition> get events => _controller.stream;

  void publish(AdminEventDefinition event) {
    if (_controller.isClosed) {
      throw StateError('Cannot publish admin event after bus is closed.');
    }
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}
