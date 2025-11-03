import 'package:equatable/equatable.dart';

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.createdAt,
    this.externalReference,
  });

  final int id;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final DateTime createdAt;
  final String? externalReference;

  bool get isPositive => amount >= 0;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as int,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      description: (json['description'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      externalReference: json['external_reference'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, type, amount, status, createdAt];
}
