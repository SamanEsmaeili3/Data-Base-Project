// lib/models/booking_model.dart

class ReservationCreateModel {
  final int ticketId;

  ReservationCreateModel({required this.ticketId});

  Map<String, dynamic> toJson() {
    return {'TicketID': ticketId};
  }
}

class ReservationResponseModel {
  final int reservationId;
  final int ticketId;
  final int userId;
  final String reservationStatus;
  final DateTime reservationTime;
  final DateTime reservationExpiryTime;

  ReservationResponseModel({
    required this.reservationId,
    required this.ticketId,
    required this.userId,
    required this.reservationStatus,
    required this.reservationTime,
    required this.reservationExpiryTime,
  });

  factory ReservationResponseModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'ReservationID': int reservationId,
        'TicketID': int ticketId,
        'UserID': int userId,
        'ReservationStatus': String reservationStatus,
        'ReservationTime': String reservationTime,
        'ReservationExpiryTime': String reservationExpiryTime,
      } =>
        ReservationResponseModel(
          reservationId: reservationId,
          ticketId: ticketId,
          userId: userId,
          reservationStatus: reservationStatus,
          reservationTime: DateTime.parse(reservationTime),
          reservationExpiryTime: DateTime.parse(reservationExpiryTime),
        ),
      _ => throw const FormatException('Failed to load reservation response.'),
    };
  }
}

class PaymentRequestModel {
  final int reservationId;
  final String paymentMethod;

  PaymentRequestModel({
    required this.reservationId,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {'ReservationID': reservationId, 'PaymentMethod': paymentMethod};
  }
}

class TicketInfoForBooking {
  final String origin;
  final String destination;
  final String departureDateTime;
  final double price;
  final String companyName;

  TicketInfoForBooking({
    required this.origin,
    required this.destination,
    required this.departureDateTime,
    required this.price,
    required this.companyName,
  });

  factory TicketInfoForBooking.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'Origin': String origin,
        'Destination': String destination,
        'DepartureDateTime': String departureDateTime,
        'Price': final price,
        'CompanyName': String companyName,
      } =>
        TicketInfoForBooking(
          origin: origin,
          destination: destination,
          departureDateTime: departureDateTime,
          price: (price as num).toDouble(),
          companyName: companyName,
        ),
      _ => throw const FormatException('Failed to load ticket info.'),
    };
  }
}

class UserBookingDetailsResponse {
  final String reservationStatus;
  final DateTime reservationTime;
  final TicketInfoForBooking ticketDetails;

  UserBookingDetailsResponse({
    required this.reservationStatus,
    required this.reservationTime,
    required this.ticketDetails,
  });

  factory UserBookingDetailsResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'ReservationStatus': String reservationStatus,
        'ReservationTime': String reservationTime,
        'TicketDetails': Map<String, dynamic> ticketDetails,
      } =>
        UserBookingDetailsResponse(
          reservationStatus: reservationStatus,
          reservationTime: DateTime.parse(reservationTime),
          ticketDetails: TicketInfoForBooking.fromJson(ticketDetails),
        ),
      _ => throw const FormatException('Failed to load user booking details.'),
    };
  }
}
