class City {
  final int id;
  final String name;

  const City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'id': int id, 'name': String name} => City(id: id, name: name),
      _ => throw const FormatException('Failed to load city.'),
    };
  }
}

class Ticket {
  final int id;
  final String origin;
  final String destination;
  final String date;
  final double price;

  const Ticket({
    required this.id,
    required this.origin,
    required this.destination,
    required this.date,
    required this.price,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'TicketID': int id,
        'Origin': String origin,
        'Destination': String destination,
        'Date': String date,
        'Price': num price,
      } =>
        Ticket(
          id: id,
          origin: origin,
          destination: destination,
          date: date,
          price: price.toDouble(),
        ),
      _ => throw const FormatException('Failed to load ticket.'),
    };
  }
}

class ReservationResponse {
  final int reservationId;
  final String status;

  const ReservationResponse({
    required this.reservationId,
    required this.status,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'ReservationID': int reservationId, 'Status': String status} =>
        ReservationResponse(reservationId: reservationId, status: status),
      _ => throw const FormatException('Failed to load reservation response.'),
    };
  }
}

class PaymentResponse {
  final bool success;
  final String transactionId;

  const PaymentResponse({required this.success, required this.transactionId});

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'success': bool success, 'transaction_id': String transactionId} =>
        PaymentResponse(success: success, transactionId: transactionId),
      _ => throw const FormatException('Failed to load payment response.'),
    };
  }
}
