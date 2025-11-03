import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../auth/providers/auth_controller.dart';
import '../../common/providers/api_client.dart';
import '../models/wallet_summary.dart';
import '../models/wallet_transaction.dart';

class CheckoutSession {
  const CheckoutSession({required this.url, required this.sessionId});

  final String url;
  final String sessionId;

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      url: json['checkout_url'] as String,
      sessionId: json['session_id'] as String,
    );
  }
}

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) async {
  final dio = ref.read(dioProvider);
  final config = ref.read(appConfigProvider);
  final token = ref.watch(authControllerProvider).accessToken;
  if (token == null) {
    throw StateError('Usuario no autenticado.');
  }
  final response = await dio.get<Map<String, dynamic>>(
    '${config.apiBaseUrl}/wallet/',
    options: Options(headers: {
      'Authorization': 'Bearer $token',
    }),
  );
  return WalletSummary.fromJson(response.data!);
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final dio = ref.read(dioProvider);
  final config = ref.read(appConfigProvider);
  final token = ref.watch(authControllerProvider).accessToken;
  if (token == null) {
    return const [];
  }
  final response = await dio.get<List<dynamic>>(
    '${config.apiBaseUrl}/wallet/history/',
    options: Options(headers: {
      'Authorization': 'Bearer $token',
    }),
  );
  final list = response.data ?? [];
  return list
      .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
      .toList();
});

final walletDepositServiceProvider = Provider<WalletDepositService>((ref) {
  return WalletDepositService(ref);
});

class WalletDepositService {
  WalletDepositService(this._ref);

  final Ref _ref;

  Future<CheckoutSession> createDeposit({
    required double amount,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final dio = _ref.read(dioProvider);
    final config = _ref.read(appConfigProvider);
    final token = _ref.read(authControllerProvider).accessToken;
    if (token == null) {
      throw StateError('Usuario no autenticado.');
    }
    final payload = {
      'amount': amount,
      'success_url': successUrl,
      'cancel_url': cancelUrl,
    };
    final response = await dio.post<Map<String, dynamic>>(
      '${config.apiBaseUrl}/wallet/deposit/',
      data: jsonEncode(payload),
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
    return CheckoutSession.fromJson(response.data!);
  }
}
