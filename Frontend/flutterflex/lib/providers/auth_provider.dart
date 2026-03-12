import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'app_settings_provider.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._appSettingsProvider);

  final AuthService _authService;
  final AppSettingsProvider _appSettingsProvider;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.tryRestoreSession();
      if (_currentUser != null) {
        await _applyUserPreferences(_currentUser!);
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      await _applyUserPreferences(_currentUser!);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('ApiException(401): ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncPreferences() async {
    if (_currentUser == null) {
      return false;
    }

    try {
      _currentUser = await _authService.updateSettings(
        preferredUnit: _appSettingsProvider.selectedUnitApiValue,
        preferredTheme: _appSettingsProvider.selectedThemeIndex,
        preferredMode: _appSettingsProvider.selectedModeApiValue,
      );
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _applyUserPreferences(UserModel user) async {
    await _appSettingsProvider.applyRemotePreferences(
      preferredUnit: user.preferredUnit,
      preferredTheme: user.preferredTheme,
      preferredMode: user.preferredMode,
    );
  }
}
