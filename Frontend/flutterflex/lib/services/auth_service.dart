import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  const AuthService(this._apiService);

  final ApiService _apiService;

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _apiService.post(
      '/register',
      body: {'username': username, 'email': email, 'password': password},
    );

    return login(email: email, password: password);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response =
        await _apiService.post(
              '/login',
              body: {'email': email, 'password': password},
            )
            as Map<String, dynamic>;

    await _apiService.saveToken(response['token'] as String);
    return UserModel.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<UserModel?> tryRestoreSession() async {
    await _apiService.loadToken();

    try {
      final response =
          await _apiService.get('/users/me', authenticated: true)
              as Map<String, dynamic>;
      return UserModel.fromJson(response);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _apiService.clearToken();
        return null;
      }

      rethrow;
    }
  }

  Future<UserModel> updateSettings({
    required String preferredUnit,
    required int preferredTheme,
    required String preferredMode,
  }) async {
    final response =
        await _apiService.put(
              '/users/settings',
              authenticated: true,
              body: {
                'preferredUnit': preferredUnit,
                'preferredTheme': preferredTheme,
                'preferredMode': preferredMode,
              },
            )
            as Map<String, dynamic>;

    return UserModel.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }
}
