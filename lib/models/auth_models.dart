class SignupResponse {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String city;
  final String createdAt;

  const SignupResponse({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.city,
    required this.createdAt,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'userId': int userId,
        'FirstName': String firstName,
        'LastName': String lastName,
        'Email': String email,
        'PhoneNumber': String phoneNumber,
        'City': String city,
        'CreatedAt': String createdAt,
      } =>
        SignupResponse(
          userId: userId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          city: city,
          createdAt: createdAt,
        ),
      _ => throw const FormatException('Failed to load signup response.'),
    };
  }
}

class OTPResponse {
  final bool success;
  final String message;

  const OTPResponse({required this.success, required this.message});

  factory OTPResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'success': bool success, 'message': String message} => OTPResponse(
        success: success,
        message: message,
      ),
      _ => throw const FormatException('Failed to load OTP response.'),
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;

  const LoginResponse({required this.accessToken, required this.tokenType});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'access_token': String token, 'token_type': String type} =>
        LoginResponse(accessToken: token, tokenType: type),
      _ => throw const FormatException('Failed to load login response.'),
    };
  }
}
