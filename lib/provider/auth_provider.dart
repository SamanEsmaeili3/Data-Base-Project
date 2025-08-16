import 'package:flutter/material.dart';
import 'package:hand_made/models/auth_model.dart';
import 'package:hand_made/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
  otpSent,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _authStatus = AuthStatus.uninitialized;
  String? _token;
  String? _errorMessage;

  // Getters
  AuthStatus get authStatus => _authStatus;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');

    if (_token != null && _token!.isNotEmpty) {
      _authStatus = AuthStatus.authenticated;
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phoneOrEmail) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create the model object
      final otpData = SendOtpModel(phoneOrEmail: phoneOrEmail);

      // 2. Pass the single object to the service
      await _apiService.sendOtp(otpData);

      _authStatus = AuthStatus.otpSent;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "خطا در ارسال کد. لطفاً ورودی خود را چک کنید.";
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithOtp(String phoneOrEmail, String otp) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create the model object
      final loginData = LoginWithOtpModel(phoneOrEmail: phoneOrEmail, otp: otp);

      // 2. Pass the single object to the service
      final tokenModel = await _apiService.LoginWithOtp(loginData);

      await _saveToken(tokenModel.accessToken);
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "کد وارد شده صحیح نیست یا منقضی شده است.";
      _authStatus = AuthStatus.otpSent;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _authStatus = AuthStatus.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }
}
