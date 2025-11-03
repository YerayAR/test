import 'package:equatable/equatable.dart';

class Redemption extends Equatable {
  const Redemption({
    required this.id,
    required this.productName,
    required this.pointsSpent,
    required this.moneySpent,
    required this.currency,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final int pointsSpent;
  final double moneySpent;
  final String currency;
  final DateTime createdAt;

  factory Redemption.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final points = (json['points_spent'] as num?)?.toInt() ?? 0;
    final money = (json['money_spent'] as num?)?.toDouble() ?? 0;
    return Redemption(
      id: json['id'] as int,
      productName: product != null ? product['name'] as String : 'Producto',
      pointsSpent: points,
      moneySpent: money,
      currency: (json['currency'] as String?) ?? 'EUR',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get wasPoints => pointsSpent > 0;
  bool get wasMoney => moneySpent > 0;

  @override
  List<Object?> get props => [id, productName, pointsSpent, moneySpent, currency, createdAt];
}
