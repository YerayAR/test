import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../auth/providers/auth_controller.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../common/providers/api_client.dart';
import '../models/redemption.dart';
import '../../wallet/providers/wallet_provider.dart';

final redemptionHistoryProvider = FutureProvider<List<Redemption>>((ref) async {
  final dio = ref.read(dioProvider);
  final config = ref.read(appConfigProvider);
  final token = ref.watch(authControllerProvider).accessToken;
  if (token == null) {
    return const [];
  }
  final response = await dio.get<List<dynamic>>(
    config.apiPath('rewards/history/'),
    options: Options(headers: {
      'Authorization': 'Bearer $token',
    }),
  );
  final list = response.data ?? [];
  return list
      .map((item) => Redemption.fromJson(item as Map<String, dynamic>))
      .toList();
});

final redeemProductProvider = Provider<Future<void> Function(int)>((ref) {
  return (int productId) async {
    final dio = ref.read(dioProvider);
    final config = ref.read(appConfigProvider);
    final token = ref.read(authControllerProvider).accessToken;
    if (token == null) {
      throw StateError('Usuario no autenticado.');
    }
    await dio.post<void>(
      config.apiPath('rewards/history/redeem/'),
      data: {'product_id': productId},
      options: Options(headers: {
        'Authorization': 'Bearer $token',
      }),
    );
    await ref.read(authControllerProvider.notifier).loadProfile();
    ref.invalidate(productsProvider);
    ref.invalidate(redemptionHistoryProvider);
  };
});
