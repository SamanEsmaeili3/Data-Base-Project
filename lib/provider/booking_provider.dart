import 'package:flutter/material.dart';
import 'package:hand_made/service/api_service.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<UserBookingDetailsResponse> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String _authToken = '';

  // Getters
  List<UserBookingDetailsResponse> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Method to update the token from AuthProvider
  void updateAuthToken(String token) {
    _authToken = token;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<void> fetchUserBookings() async {
    if (_authToken.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _apiService.getUserBookings(_authToken);
    } catch (e) {
      _errorMessage = "خطا در درسافت اطلاعات رزروها";
      _bookings = []; // Clear old data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reserveTicket(int ticketId) async {
    if (_authToken.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiService.reserveTicket(ticketId, _authToken);
      _successMessage = "بلیط با موفقیت رزرو شد.";
      await fetchUserBookings(); // Refresh booking list
      return true;
    } catch (e) {
      _errorMessage = "خطا در رزرو بلیط. لطفا با پشتیبانی تماس بگیرید.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(int reservationId) async {
    if (_authToken.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.cancelTicket(reservationId, _authToken);
      final refundAmount = result['refund_amount'];
      _successMessage =
          "بلیط با موفقیت لغو شد. مبلغ $refundAmount تومان به حساب شما بازگشت داده می‌شود.";
      await fetchUserBookings(); // Refresh booking list
      return true;
    } catch (e) {
      _errorMessage = "خطا در لغو بلیط. لطفا با پشتیبانی تماس بگیرید.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> payForReservation(
    int reservationId,
    String paymentMethod,
  ) async {
    if (_authToken.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiService.payForTicket(reservationId, paymentMethod, _authToken);
      _successMessage = "پرداخت با موفقیت انجام شد.";
      // Refresh the booking list to show the new "Paid" status.
      await fetchUserBookings();
      return true;
    } catch (e) {
      _errorMessage = "پرداخت ناموفق بود. ممکن است رزرو منقضی شده باشد.";
      notifyListeners(); // Also notify on error to update UI
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkCancellationPenalty(int ticketId) async {
    if (_authToken.isEmpty) {
      throw Exception('User not authenticated');
    }
    return await _apiService.checkCancellationPenalty(ticketId, _authToken);
  }

  Future<bool> cancelReservation(int reservationId) async {
    if (_authToken.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.cancelReservation(
        reservationId,
        _authToken,
      );
      final refundAmount = result['refund_amount'];
      _successMessage =
          "بلیط با موفقیت لغو شد. مبلغ $refundAmount تومان به حساب شما بازگردانده می‌شود.";
      await fetchUserBookings(); // Refresh the list to show "Cancelled" status
      return true;
    } catch (e) {
      _errorMessage = "خطا در لغو بلیط. لطفاً با پشتیبانی تماس بگیرید.";
      notifyListeners(); // Also notify on error to update UI
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
