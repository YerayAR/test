import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../common/providers/api_client.dart';
import '../models/user_profile.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.errorMessage,
  });

  final bool isLoading;
  final String? accessToken;
  final String? refreshToken;
  final UserProfile? user;
  final String? errorMessage;

  bool get isAuthenticated => accessToken != null && user != null;

  AuthState copyWith({
    bool? isLoading,
    String? accessToken,
    String? refreshToken,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState.initial());

  final Ref _ref;

  Dio get _client => _ref.read(dioProvider);

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final config = _ref.read(appConfigProvider);
      final response = await _client.post<Map<String, dynamic>>(
        config.apiPath('auth/login/'),
        data: {
          'username': username,
          'password': password,
        },
      );
      final data = response.data!;
      final access = data['access'] as String;
      final refresh = data['refresh'] as String;
      final profile = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        accessToken: access,
        refreshToken: refresh,
        user: profile,
        errorMessage: null,
      );
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['detail'] as String? ?? 'Credenciales invalidas.')
          : 'No se pudo iniciar sesion.';
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Future<void> loadProfile() async {
    if (state.accessToken == null) return;
    try {
      final config = _ref.read(appConfigProvider);
      final response = await _client.get<Map<String, dynamic>>(
        config.apiPath('me/'),
        options: Options(headers: {
          'Authorization': 'Bearer ${state.accessToken}',
        }),
      );
      final profile = UserProfile.fromJson(response.data!);
      state = state.copyWith(user: profile, errorMessage: null);
    } on DioException catch (_) {
      logout();
    }
  }

  void logout() {
    state = AuthState.initial();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
