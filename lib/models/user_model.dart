class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String city;
  final String createdAt;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.city,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'FirstName': String firstName,
        'LastName': String lastName,
        'Email': String email,
        'PhoneNumber': String phoneNumber,
        'City': String city,
        'CreatedAt': String createdAt,
      } =>
        UserProfile(
          id: id,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          city: city,
          createdAt: createdAt,
        ),
      _ => throw const FormatException('Failed to load user profile.'),
    };
  }
}

class Booking {
  final int reservationId;
  final int ticketId;
  final String status;
  final String reservedAt;

  const Booking({
    required this.reservationId,
    required this.ticketId,
    required this.status,
    required this.reservedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'ReservationID': int reservationId,
        'TicketID': int ticketId,
        'Status': String status,
        'ReservedAt': String reservedAt,
      } =>
        Booking(
          reservationId: reservationId,
          ticketId: ticketId,
          status: status,
          reservedAt: reservedAt,
        ),
      _ => throw const FormatException('Failed to load booking.'),
    };
  }
}
