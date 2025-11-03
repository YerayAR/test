import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../auth/providers/auth_controller.dart';
import '../../common/providers/api_client.dart';
import '../models/product.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final dio = ref.read(dioProvider);
  final config = ref.read(appConfigProvider);
  final token = ref.watch(authControllerProvider).accessToken;
  final response = await dio.get<List<dynamic>>(
    config.apiPath('catalog/products/'),
    options: Options(headers: {
      if (token != null) 'Authorization': 'Bearer ',
    }),
  );
  final list = response.data ?? [];
  return list
      .map((item) => Product.fromJson(item as Map<String, dynamic>))
      .toList();
});

final productBySlugProvider = FutureProvider.family<Product, String>((ref, slug) async {
  final dio = ref.read(dioProvider);
  final config = ref.read(appConfigProvider);
  final token = ref.watch(authControllerProvider).accessToken;
  final response = await dio.get<Map<String, dynamic>>(
    config.apiPath('catalog/products//'),
    options: Options(headers: {
      if (token != null) 'Authorization': 'Bearer ',
    }),
  );
  return Product.fromJson(response.data!);
});
