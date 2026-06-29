import '../../domain/entities/wallet_entity.dart';

class RewardWalletModel extends RewardWalletEntity {
  const RewardWalletModel({
    required super.available,
    required super.earned,
    required super.redeemed,
  });

  factory RewardWalletModel.fromJson(Map<String, dynamic> json) {
    return RewardWalletModel(
      available: _asDouble(json['available']),
      earned: _asDouble(json['earned']),
      redeemed: _asDouble(json['redeemed']),
    );
  }

  Map<String, dynamic> toJson() => {
    'available': available,
    'earned': earned,
    'redeemed': redeemed,
  };

  static double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
