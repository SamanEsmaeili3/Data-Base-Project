import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../models/ticket_model.dart';

class TicketProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CityModel> _cities = [];
  List<TicketSearchResultModel> _searchResults = [];
  TicketDetailsModel? _ticketDetails;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CityModel> get cities => _cities;
  List<TicketSearchResultModel> get searchResults => _searchResults;
  TicketDetailsModel? get ticketDetails => _ticketDetails;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCities() async {
    try {
      if (_cities.isEmpty) {
        _cities = await _apiService.getCities();
        notifyListeners();
      }
    } catch (e) {
      print("Failed to fetch cities: $e");
    }
  }

  Future<void> searchTickets({
    required String origin,
    required String destination,
    required String date,
    required String vehicleType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _searchResults = [];
    notifyListeners();

    try {
      _searchResults = await _apiService.searchTickets(
        origin: origin,
        destination: destination,
        date: date,
        vehicleType: vehicleType,
      );
    } catch (e) {
      _errorMessage = "خطا در جستجوی بلیط‌ها";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTicketDetails(int ticketId) async {
    _isLoading = true;
    _errorMessage = null;
    _ticketDetails = null;
    notifyListeners();

    try {
      _ticketDetails = await _apiService.getTicketDetails(ticketId);
    } catch (e) {
      _errorMessage = "خطا در دریافت جزئیات بلیط";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
