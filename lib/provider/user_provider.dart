import 'package:flutter/material.dart';
import 'package:hand_made/service/api_service.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _apiService.getCurrentUserProfile();
    } catch (e) {
      _errorMessage = "خطا در دریافت اطلاعات کاربر.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(UserProfileUpdateModel profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateUserProfile(profileData);
      // After updating, fetch the profile again to refresh data
      await fetchUserProfile();
      return true;
    } catch (e) {
      _errorMessage = "خطا در به‌روزرسانی پروفایل.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
