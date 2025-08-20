// lib/models/ticket_model.dart

class CityModel {
  final int cityId;
  final String cityName;

  CityModel({required this.cityId, required this.cityName});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'CityID': int cityId, 'CityName': String cityName} => CityModel(
        cityId: cityId,
        cityName: cityName,
      ),
      _ => throw const FormatException('Failed to load city model.'),
    };
  }
}

class TicketSearchResultModel {
  final int ticketId;
  final String origin;
  final String destination;
  final String departureDateTime;
  final String arrivalDateTime;
  final double price;
  final int remainingCapacity;
  final String companyName;
  final String? vehicleType;

  TicketSearchResultModel({
    required this.ticketId,
    required this.origin,
    required this.destination,
    required this.departureDateTime,
    required this.arrivalDateTime,
    required this.price,
    required this.remainingCapacity,
    required this.companyName,
    this.vehicleType,
  });

  factory TicketSearchResultModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'TicketID': int ticketId,
        'Origin': String origin,
        'Destination': String destination,
        'DepartureDateTime': String departureDateTime,
        'ArrivalDateTime': String arrivalDateTime,
        'Price': final price, // Can be int or double from JSON
        'RemainingCapacity': int remainingCapacity,
        'CompanyName': String companyName,
      } =>
        TicketSearchResultModel(
          ticketId: ticketId,
          origin: origin,
          destination: destination,
          departureDateTime: departureDateTime,
          arrivalDateTime: arrivalDateTime,
          price: (price as num).toDouble(),
          remainingCapacity: remainingCapacity,
          companyName: companyName,
          vehicleType: json['VehicleType'] as String?,
        ),
      _ => throw const FormatException('Failed to load ticket search result.'),
    };
  }
}

class TicketDetailsModel {
  final int ticketId;
  final String origin;
  final String destination;
  final String departureDate;
  final String departureTime;
  final String arrivalDate;
  final String arrivalTime;
  final int price;
  final int remainingCapacity;
  final String companyName;
  final Map<String, dynamic>? features;

  TicketDetailsModel({
    required this.ticketId,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.price,
    required this.remainingCapacity,
    required this.companyName,
    this.features,
  });

  factory TicketDetailsModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'TicketID': int ticketId,
        'Origin': String origin,
        'Destination': String destination,
        'DepartureDate': String departureDate,
        'DepartureTime': String departureTime,
        'ArrivalDate': String arrivalDate,
        'ArrivalTime': String arrivalTime,
        'Price': int price,
        'RemainingCapacity': int remainingCapacity,
        'CompanyName': String companyName,
      } =>
        TicketDetailsModel(
          ticketId: ticketId,
          origin: origin,
          destination: destination,
          departureDate: departureDate,
          departureTime: departureTime,
          arrivalDate: arrivalDate,
          arrivalTime: arrivalTime,
          price: price,
          remainingCapacity: remainingCapacity,
          companyName: companyName,
          features: json['Features'] as Map<String, dynamic>?,
        ),
      _ => throw const FormatException('Failed to load ticket details.'),
    };
  }
}
