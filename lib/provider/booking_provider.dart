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
      _errorMessage = "Error fetching booking history.";
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
      _successMessage = "Ticket reserved successfully.";
      await fetchUserBookings(); // Refresh booking list
      return true;
    } catch (e) {
      _errorMessage = "Failed to reserve ticket. It may be sold out.";
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
          "Ticket cancelled successfully. An amount of $refundAmount will be refunded.";
      await fetchUserBookings(); // Refresh booking list
      return true;
    } catch (e) {
      _errorMessage = "Failed to cancel ticket. Please contact support.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
