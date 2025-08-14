class Report {
  final int id;
  final int reservationId;
  final String subject;
  final String text;
  final String createdAt;

  const Report({
    required this.id,
    required this.reservationId,
    required this.subject,
    required this.text,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'ReportID': int id,
        'ReservationID': int reservationId,
        'ReportSubject': String subject,
        'ReportText': String text,
        'CreatedAt': String createdAt,
      } =>
        Report(
          id: id,
          reservationId: reservationId,
          subject: subject,
          text: text,
          createdAt: createdAt,
        ),
      _ => throw const FormatException('Failed to load report.'),
    };
  }
}

class UpdateReservationStatusResponse {
  final bool success;
  final String newStatus;

  const UpdateReservationStatusResponse({
    required this.success,
    required this.newStatus,
  });

  factory UpdateReservationStatusResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'success': bool success, 'NewStatus': String newStatus} =>
        UpdateReservationStatusResponse(success: success, newStatus: newStatus),
      _ =>
        throw const FormatException(
          'Failed to load update reservation status response.',
        ),
    };
  }
}
