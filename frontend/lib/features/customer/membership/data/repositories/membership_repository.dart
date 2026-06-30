import '../datasources/membership_local.dart';
import '../datasources/membership_remote.dart';
import '../models/membership_model.dart';

class MembershipRepository {
  MembershipRepository({
    MembershipRemoteDataSource? remote,
    MembershipLocalDataSource? local,
  }) : _remote = remote ?? MembershipRemoteDataSource(),
       _local = local ?? MembershipLocalDataSource();

  final MembershipRemoteDataSource _remote;
  final MembershipLocalDataSource _local;

  Future<MembershipModel?> loadCachedMembership(String customerId) {
    return _local.load(customerId);
  }

  Future<MembershipModel> loadMembership(String customerId) async {
    try {
      final membership = await _remote.fetch(customerId);
      await _local.save(customerId, membership);
      return membership;
    } catch (_) {
      final cached = await _local.load(customerId);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<MembershipModel> refreshMembership(String customerId) async {
    final membership = await _remote.fetch(customerId);
    await _local.save(customerId, membership);
    return membership;
  }

  Future<void> invalidateCache(String customerId) {
    return _local.clear(customerId);
  }
}
