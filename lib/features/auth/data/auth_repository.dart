import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  AuthRepository(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = FlutterSecureStorage();
  return AuthRepository(storage);
}); 
 
 
 
 
 
 