import '../events/admin_event_bus.dart';
import '../events/admin_event_definition.dart';
import '../events/admin_event_metadata.dart';
import 'admin_action_definition.dart';
import 'admin_command_bus.dart';
import 'admin_command_definition.dart';
import 'admin_command_metadata.dart';

class AdminActionPipeline {
  AdminActionPipeline({
    required AdminCommandBus commandBus,
    required AdminEventBus eventBus,
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _commandBus = commandBus,
       _eventBus = eventBus,
       _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _defaultIdGenerator;

  final AdminCommandBus _commandBus;
  final AdminEventBus _eventBus;
  final DateTime Function() _clock;
  final String Function() _idGenerator;

  Future<Map<String, Object?>> execute(AdminActionExecution execution) async {
    final commandId = _idGenerator();
    final timestamp = _clock();
    final result = await _commandBus.dispatch(
      AdminCommandDefinition(
        type: execution.action.type.commandType,
        workspaceId: execution.workspaceId,
        payload: execution.payload,
        metadata: AdminCommandMetadata(
          commandId: commandId,
          timestamp: timestamp,
          userId: execution.userId,
          correlationId: execution.correlationId,
          causationId: execution.causationId,
        ),
      ),
    );

    final normalizedResult = result is Map<String, Object?>
        ? result
        : <String, Object?>{'result': result};

    _eventBus.publish(
      AdminEventDefinition(
        name: 'action.completed',
        version: 1,
        metadata: AdminEventMetadata(
          eventId: commandId,
          workspaceId: execution.workspaceId,
          userId: execution.userId,
          timestamp: timestamp,
          correlationId: execution.correlationId,
          causationId: execution.causationId,
        ),
        payload: <String, Object?>{
          'actionId': execution.action.id,
          'actionType': execution.action.type.commandType,
          ...normalizedResult,
        },
      ),
    );

    return normalizedResult;
  }
}

String _defaultIdGenerator() => DateTime.now().microsecondsSinceEpoch.toString();
