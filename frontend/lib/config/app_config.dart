import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.paymentBaseUrl,
  });

  final String apiBaseUrl;
  final String paymentBaseUrl;

  String apiPath(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$apiBaseUrl/$normalized';
  }

  String paymentPath(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$paymentBaseUrl/$normalized';
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  const defaultApiUrl = 'http://localhost:8000/api';
  const apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: defaultApiUrl);
  const paymentsUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
    defaultValue: apiUrl,
  );
  return AppConfig(
    apiBaseUrl: apiUrl,
    paymentBaseUrl: paymentsUrl,
  );
});

/// Helper extension to log configuration when running in debug mode.
extension AppConfigDebugExtension on AppConfig {
  void debugLog() {
    if (kDebugMode) {
      // ignore: avoid_print, only for startup diagnostics
      print('AppConfig: apiBaseUrl=$apiBaseUrl, paymentBaseUrl=$paymentBaseUrl');
    }
  }
}
