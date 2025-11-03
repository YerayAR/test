import 'package:equatable/equatable.dart';

class Redemption extends Equatable {
  const Redemption({
    required this.id,
    required this.productName,
    required this.pointsSpent,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final int pointsSpent;
  final DateTime createdAt;

  factory Redemption.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return Redemption(
      id: json['id'] as int,
      productName: product != null ? product['name'] as String : 'Producto',
      pointsSpent: json['points_spent'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, productName, pointsSpent, createdAt];
}
