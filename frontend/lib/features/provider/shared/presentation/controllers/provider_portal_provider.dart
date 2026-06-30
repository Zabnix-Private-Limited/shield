import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/provider_portal_repository.dart';
import 'provider_portal_controller.dart';

final providerPortalRepositoryProvider = Provider<ProviderPortalRepository>(
  (ref) => ProviderPortalRepository(),
);

final providerPortalControllerProvider =
    ChangeNotifierProvider<ProviderPortalController>(
      (ref) => ProviderPortalController(
        ref.watch(providerPortalRepositoryProvider),
      ),
    );
