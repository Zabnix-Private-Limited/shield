import '../../domain/entities/wallet_entity.dart';

class CashWalletModel extends CashWalletEntity {
  const CashWalletModel({
    required super.available,
    required super.credited,
    required super.debited,
  });

  factory CashWalletModel.fromJson(Map<String, dynamic> json) {
    return CashWalletModel(
      available: _asDouble(json['available']),
      credited: _asDouble(json['credited']),
      debited: _asDouble(json['debited']),
    );
  }

  Map<String, dynamic> toJson() => {
    'available': available,
    'credited': credited,
    'debited': debited,
  };

  static double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
