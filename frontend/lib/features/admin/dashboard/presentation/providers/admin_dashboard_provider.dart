import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_dashboard_controller.dart';
import '../../data/datasources/admin_dashboard_remote_data_source.dart';
import '../../data/repositories/admin_dashboard_repository_impl.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';

final adminDashboardRemoteDataSourceProvider =
    Provider<AdminDashboardRemoteDataSource>(
      (ref) => AdminDashboardRemoteDataSource(),
    );

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepositoryImpl(
    remoteDataSource: ref.watch(adminDashboardRemoteDataSourceProvider),
  ),
);

final adminDashboardControllerProvider =
    ChangeNotifierProvider<AdminDashboardController>((ref) {
      final controller = AdminDashboardController(
        ref.watch(adminDashboardRepositoryProvider),
      );
      controller.load();
      return controller;
    });
