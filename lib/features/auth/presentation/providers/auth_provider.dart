import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> initialize() async {
    try {
      final token = await _storage.read(key: AppConstants.authTokenKey);
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final response = await _apiService.getUser();
      if (response.success && response.data != null) {
        state = AsyncValue.data(User.fromJson(response.data));
      } else {
        await _storage.deleteAll();
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.login(email, password);
      
      if (response.success && response.data != null) {
        // Store the token
        await _storage.write(key: AppConstants.authTokenKey, value: response.data['token']);
        
        // Extract user data from the nested response
        final userData = response.data['user'];
        if (userData != null) {
          state = AsyncValue.data(User.fromJson(userData));
          return true;
        }
      }
      
      state = AsyncValue.error(response.message ?? AppConstants.genericError, StackTrace.current);
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.register(name, email, password);
      
      if (response.success) {
        return await login(email, password);
      }
      
      state = AsyncValue.error(response.message ?? AppConstants.genericError, StackTrace.current);
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      state = const AsyncValue.loading();
      await _apiService.logout();
      await _storage.deleteAll();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
} 