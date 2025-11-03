import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.priceType,
    required this.inventory,
    required this.category,
    this.pointsCost,
    this.priceAmount,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String priceType;
  final int inventory;
  final String category;
  final int? pointsCost;
  final double? priceAmount;
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final priceType = json['price_type'] as String? ?? 'points';
    final pointsCost = (json['points_cost'] as num?)?.toInt();
    final priceAmount = (json['price_amount'] as num?)?.toDouble();
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      priceType: priceType,
      pointsCost: pointsCost,
      priceAmount: priceAmount,
      inventory: json['inventory'] as int,
      category: category != null ? category['name'] as String : 'Sin categoria',
      imageUrl: json['image_url'] as String?,
    );
  }

  bool get requiresPoints => priceType == 'points';

  bool get requiresMoney => priceType == 'money';

  String get costLabel {
    if (requiresPoints && pointsCost != null) {
      return '${pointsCost!} pts';
    }
    if (requiresMoney && priceAmount != null) {
      return '€${priceAmount!.toStringAsFixed(2)}';
    }
    return 'N/D';
  }

  @override
  List<Object?> get props =>
      [id, name, priceType, pointsCost, priceAmount, inventory, slug];
}
