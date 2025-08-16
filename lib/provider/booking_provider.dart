import 'package:flutter/material.dart';
import 'package:hand_made/service/api_service.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<UserBookingDetailsResponse> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<UserBookingDetailsResponse> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<void> fetchUserBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _apiService.getUserBookings();
    } catch (e) {
      _errorMessage = "خطا در دریافت تاریخچه رزروها.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reserveTicket(int ticketId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final reservation = await _apiService.reserveTicket(ticketId);
      // می‌توانید بلافاصله به صفحه پرداخت بروید یا پیام موفقیت نمایش دهید
      _successMessage = "بلیط با موفقیت رزرو شد. لطفاً هزینه را پرداخت کنید.";
      // به صورت اختیاری می‌توانید بلافاصله تاریخچه را آپدیت کنید
      await fetchUserBookings();
      return true;
    } catch (e) {
      _errorMessage = "رزرو بلیط ناموفق بود. ممکن است ظرفیت تمام شده باشد.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(int reservationId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.cancelTicket(reservationId);
      final refundAmount = result['refund_amount'];
      _successMessage =
          "بلیط شما با موفقیت لغو شد. مبلغ $refundAmount به حساب شما بازگردانده می‌شود.";
      // update the bookings list after cancellation
      await fetchUserBookings();
      return true;
    } catch (e) {
      _errorMessage = "لغو بلیط ناموفق بود. لطفاً با پشتیبانی تماس بگیرید.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
