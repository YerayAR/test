import 'package:equatable/equatable.dart';

class WalletSummary extends Equatable {
  const WalletSummary({
    required this.balance,
    required this.currency,
    required this.updatedAt,
  });

  final double balance;
  final String currency;
  final DateTime updatedAt;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [balance, currency, updatedAt];
}
