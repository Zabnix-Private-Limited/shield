import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/agent_portal_repository.dart';
import 'agent_portal_controller.dart';

final agentPortalRepositoryProvider = Provider<AgentPortalRepository>(
  (ref) => AgentPortalRepository(),
);

final agentPortalControllerProvider =
    ChangeNotifierProvider<AgentPortalController>(
  (ref) => AgentPortalController(ref.watch(agentPortalRepositoryProvider)),
);
