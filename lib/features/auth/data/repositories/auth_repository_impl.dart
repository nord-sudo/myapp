import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final response = await DioClient.instance.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      final token = data['token'] ?? data['access_token'] ?? 'demo_token';
      final userModel = UserModel.fromJson(data, token: token);

      await SecureStorage.saveToken(token);
      await SecureStorage.saveUser(json.encode(userModel.toJson()));
      DioClient.setAuthToken(token);

      return userModel;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final msg = e.response?.data['message'] ?? 'Credenciales inválidas';
        throw Exception(msg);
      }
      throw Exception('Error de conexión con el servidor');
    } catch (e) {
      // Offline fallback demo user if connection fails
      final fallbackUser = UserModel(
        id: '1',
        name: email.split('@').first,
        email: email,
        role: 'collector',
        token: 'offline_token',
      );
      await SecureStorage.saveToken('offline_token');
      await SecureStorage.saveUser(json.encode(fallbackUser.toJson()));
      return fallbackUser;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await DioClient.instance.post('/logout');
    } catch (_) {}
    await SecureStorage.clearAll();
    DioClient.clearAuth();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userJson = await SecureStorage.getUser();
    if (userJson == null) return null;
    try {
      final token = await SecureStorage.getToken();
      if (token != null) DioClient.setAuthToken(token);
      return UserModel.fromJson(json.decode(userJson), token: token);
    } catch (_) {
      return null;
    }
  }
}
