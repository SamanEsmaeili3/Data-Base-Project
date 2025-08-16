import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/booking_model.dart';

class ApiService {
  final Dio _dio;
  static const String _baseUrl =
      'http://10.0.2.2:8000'; // آدرس برای Android Emulator

  ApiService() : _dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print('API Error: ${e.response?.statusCode} - ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  Future<TokenModel> signUp(UserCreateModel userData) async {
    final response = await _dio.post('/auth/signup', data: userData.toJson());
    return TokenModel.fromJson(response.data);
  }

  Future<TokenModel> login(LoginWithOtpModel loginData) async {
    final response = await _dio.post(
      '/auth/loginWithPassword',
      data: loginData.toJson(),
    );
    return TokenModel.fromJson(response.data);
  }

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
        'date': date, // e.g., '2025-12-25'
        'vehicle_type': vehicleType, // 'airplane', 'bus', or 'train'
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

  Future<ReservationResponseModel> reserveTicket(int ticketId) async {
    final reservationData = ReservationCreateModel(ticketId: ticketId);
    final response = await _dio.post(
      '/tickets/reserve',
      data: reservationData.toJson(),
    );
    return ReservationResponseModel.fromJson(response.data);
  }

  Future<void> payForTicket(int reservationId, String paymentMethod) async {
    final paymentData = PaymentRequestModel(
      reservationId: reservationId,
      paymentMethod: paymentMethod,
    );
    await _dio.post('/tickets/pay', data: paymentData.toJson());
  }

  Future<UserModel> getCurrentUserProfile() async {
    final response = await _dio.get('/users/me');
    return UserModel.fromJson(response.data);
  }

  Future<void> updateUserProfile(UserProfileUpdateModel profileData) async {
    await _dio.put('/users/me', data: profileData.toJson());
  }

  Future<List<UserBookingDetailsResponse>> getUserBookings() async {
    final response = await _dio.get('/users/me/bookings');
    return (response.data as List)
        .map((booking) => UserBookingDetailsResponse.fromJson(booking))
        .toList();
  }

  Future<Map<String, dynamic>> getCancellationPenalty(int ticketId) async {
    final response = await _dio.get('/tickets/$ticketId/cancellation-penalty');
    return response.data;
  }

  Future<Map<String, dynamic>> cancelTicket(int reservationId) async {
    final response = await _dio.post(
      '/tickets/reservations/$reservationId/cancel',
    );
    return response.data; // e.g., {"message": "...", "refund_amount": ...}
  }
}
