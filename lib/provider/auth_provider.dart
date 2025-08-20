import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart'; // Needed for signUp

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
  otpSent,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _authStatus = AuthStatus.unauthenticated;
  String? _token;
  String? _errorMessage;

  // Getters
  AuthStatus get authStatus => _authStatus;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  // --- Methods ---

  Future<bool> sendOtp(String phoneOrEmail) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final otpData = SendOtpModel(phoneOrEmail: phoneOrEmail);
      await _apiService.sendOtp(otpData);
      _authStatus = AuthStatus.otpSent;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "خطا در ارسال کد تایید. لطفا دوباره تلاش کنید.";
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
      final loginData = LoginWithOtpModel(phoneOrEmail: phoneOrEmail, otp: otp);
      final tokenModel = await _apiService.loginWithOtp(loginData);
      _saveToken(tokenModel.accessToken);
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "کد یا اشتباه است ویا منقضی شده است.";
      _authStatus = AuthStatus.otpSent;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(UserCreateModel userData) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenModel = await _apiService.signUp(userData);
      _saveToken(tokenModel.accessToken);
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          "ایمیل یا شماره همراه قبلا ثبت شده است. لطفا از اطلاعات دیگری استفاده کنید.";
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _saveToken(String token) {
    _token = token;
  }
}
