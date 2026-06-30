import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../controllers/provider_portal_controller.dart';
import '../controllers/provider_portal_provider.dart';

class ProviderWorkspaceScaffold extends ConsumerStatefulWidget {
  const ProviderWorkspaceScaffold({
    super.key,
    required this.builder,
    this.loadSettings = false,
  });

  final Widget Function(
    BuildContext context,
    WidgetRef ref,
    ProviderPortalController controller,
  )
  builder;
  final bool loadSettings;

  @override
  ConsumerState<ProviderWorkspaceScaffold> createState() =>
      _ProviderWorkspaceScaffoldState();
}

class _ProviderWorkspaceScaffoldState
    extends ConsumerState<ProviderWorkspaceScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(providerPortalControllerProvider);
      await controller.ensureLoaded();
      if (widget.loadSettings) {
        await controller.loadSettingsData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(providerPortalControllerProvider);
    if (controller.isLoading && !controller.isWorkspaceLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && !controller.isWorkspaceLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Provider screen unavailable', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                controller.error!,
                style: AppTypography.body.copyWith(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.refreshWorkspace,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.builder(context, ref, controller);
  }
}
