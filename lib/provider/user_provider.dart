import 'package:flutter/material.dart';
import 'package:hand_made/service/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String _authToken = '';

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Method to update the token from AuthProvider
  void updateAuthToken(String token) {
    _authToken = token;
  }

  Future<void> fetchUserProfile() async {
    if (_authToken.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _apiService.getCurrentUserProfile(_authToken);
    } catch (e) {
      _errorMessage = "خطا در دریافت اطلاعات کاربر";
      _user = null; // Clear old data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(UserProfileUpdateModel profileData) async {
    if (_authToken.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateUserProfile(profileData, _authToken);
      await fetchUserProfile(); // Refresh profile after update
      return true;
    } catch (e) {
      _errorMessage = "خطا در بروزرسانی پروفایل";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
