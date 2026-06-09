import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:suraksha_women_safety_app/core/network/dio_client.dart';
import 'package:suraksha_women_safety_app/constants/api_constants.dart';
import 'package:suraksha_women_safety_app/models/user_model.dart';

const Object _unset = Object();

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? token;
  final String? error;

  AuthState({this.isLoading = false, this.user, this.token, this.error});

  AuthState copyWith({
    bool? isLoading,
    Object? user = _unset,
    Object? token = _unset,
    Object? error = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: identical(user, _unset) ? this.user : user as UserModel?,
      token: identical(token, _unset) ? this.token : token as String?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _dioClient = DioClient();
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState(isLoading: true)) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      state = AuthState();
      return;
    }

    try {
      final response = await _dioClient.dio.get(ApiConstants.profile);
      final user = UserModel.fromJson(response.data);
      state = AuthState(user: user, token: token);
    } on DioException {
      await _storage.delete(key: 'token');
      state = AuthState(error: 'Session expired. Please sign in again.');
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {'identifier': identifier, 'password': password},
      );

      final token = response.data['token'];
      await _storage.write(key: 'token', value: token);

      final user = UserModel.fromJson(response.data);
      state = state.copyWith(
        isLoading: false,
        user: user,
        token: token,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Login failed',
      );
    }
  }

  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.register,
        data: {
          'fullName': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final token = response.data['token'];
      await _storage.write(key: 'token', value: token);

      final user = UserModel.fromJson(response.data);
      state = state.copyWith(
        isLoading: false,
        user: user,
        token: token,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Registration failed',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    state = AuthState();
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}
