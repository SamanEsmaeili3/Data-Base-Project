// lib/services/api_service.dart

import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/booking_model.dart';

class ApiService {
  final Dio _dio;
  // Use http://10.0.2.2 for Android Emulator to connect to localhost
  static const String _baseUrl = 'http://10.0.2.2:8000';

  // Private constructor
  ApiService._internal() : _dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can add logic here to get the token from your AuthProvider
          // For now, we assume the token is passed manually or not needed for these calls.
          // In a real app, you'd get the token from AuthProvider.
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print('API Error: ${e.response?.statusCode} - ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  // Factory constructor to return the singleton instance
  factory ApiService() => _instance;

  // --- Authentication ---
  Future<void> sendOtp(SendOtpModel otpData) async {
    await _dio.post('/auth/otp/send', data: otpData.toJson());
  }

  Future<TokenModel> loginWithOtp(LoginWithOtpModel loginData) async {
    final response = await _dio.post(
      '/auth/otp/login',
      data: loginData.toJson(),
    );
    return TokenModel.fromJson(response.data);
  }

  Future<TokenModel> signUp(UserCreateModel userData) async {
    final response = await _dio.post('/auth/signup', data: userData.toJson());
    return TokenModel.fromJson(response.data);
  }

  // --- Tickets ---
  Future<List<CityModel>> getCities() async {
    final response = await _dio.get('/tickets/cities');
    return (response.data as List)
        .map((city) => CityModel.fromJson(city))
        .toList();
  }

  Future<List<TicketSearchResultModel>> searchTickets({
    required String origin,
    required String destination,
    required String date,
    required String vehicleType,
  }) async {
    final response = await _dio.get(
      '/tickets/search/advanced',
      queryParameters: {
        'origin_city': origin,
        'destination_city': destination,
        'date': date,
        'vehicle_type': vehicleType,
      },
    );
    return (response.data as List)
        .map((ticket) => TicketSearchResultModel.fromJson(ticket))
        .toList();
  }

  Future<TicketDetailsModel> getTicketDetails(int ticketId) async {
    final response = await _dio.get('/tickets/tickets/$ticketId');
    return TicketDetailsModel.fromJson(response.data);
  }

  // --- User & Bookings ---
  // Note: These methods will require an Authorization token in the header.
  // The interceptor logic should be updated to handle this.

  Future<UserModel> getCurrentUserProfile(String token) async {
    final response = await _dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserModel.fromJson(response.data);
  }

  Future<void> updateUserProfile(
    UserProfileUpdateModel profileData,
    String token,
  ) async {
    await _dio.put(
      '/users/me',
      data: profileData.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<UserBookingDetailsResponse>> getUserBookings(String token) async {
    final response = await _dio.get(
      '/users/me/bookings',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((booking) => UserBookingDetailsResponse.fromJson(booking))
        .toList();
  }

  Future<ReservationResponseModel> reserveTicket(
    int ticketId,
    String token,
  ) async {
    final reservationData = ReservationCreateModel(ticketId: ticketId);
    final response = await _dio.post(
      '/tickets/reserve',
      data: reservationData.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return ReservationResponseModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> cancelTicket(
    int reservationId,
    String token,
  ) async {
    final response = await _dio.post(
      '/tickets/reservations/$reservationId/cancel',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<void> payForTicket(
    int reservationId,
    String paymentMethod,
    String token,
  ) async {
    final paymentData = PaymentRequestModel(
      reservationId: reservationId,
      paymentMethod: paymentMethod,
    );
    await _dio.post(
      '/tickets/pay',
      data: paymentData.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Map<String, dynamic>> checkCancellationPenalty(
    int ticketId,
    String token,
  ) async {
    final response = await _dio.get(
      '/tickets/$ticketId/cancellation-penalty',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> cancelReservation(
    int reservationId,
    String token,
  ) async {
    final response = await _dio.post(
      '/tickets/reservations/$reservationId/cancel',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}
