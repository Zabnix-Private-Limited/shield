import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../../shared/widgets/app_skeleton.dart';
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
      return const AppPortalSectionSkeleton();
    }

    if (controller.error != null && !controller.isWorkspaceLoaded) {
      final errorTitle = _errorTitle(controller.lastError);
      final errorMessage = _errorMessage(
        controller.lastError,
        controller.error,
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorTitle, style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: AppTypography.body.copyWith(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.retryStartup,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.builder(context, ref, controller);
  }

  String _errorTitle(Object? error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 403) {
        return 'Access unavailable';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          statusCode == 502 ||
          statusCode == 503 ||
          statusCode == 504) {
        return 'Still connecting to SHIELD';
      }
    }
    return 'Provider screen unavailable';
  }

  String _errorMessage(Object? error, String? fallback) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 403) {
        return 'Your account can sign in, but it does not currently have access to this provider feature.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          statusCode == 502 ||
          statusCode == 503 ||
          statusCode == 504) {
        return 'The secure provider workspace is taking longer than usual to respond. This can happen during a cold start, and the next retry usually succeeds automatically.';
      }
    }
    return fallback ??
        'We could not load this provider screen right now. Check your connection and try again.';
  }
}
