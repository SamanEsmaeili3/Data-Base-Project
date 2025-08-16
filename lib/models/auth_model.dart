// lib/models/auth_model.dart

class TokenModel {
  final String accessToken;
  final String tokenType;

  TokenModel({required this.accessToken, required this.tokenType});

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'access_token': String accessToken, 'token_type': String tokenType} =>
        TokenModel(accessToken: accessToken, tokenType: tokenType),
      _ => throw const FormatException('Failed to load token model.'),
    };
  }
}

class LoginWithPasswordModel {
  final String phoneOrEmail;
  final String password;

  LoginWithPasswordModel({required this.phoneOrEmail, required this.password});

  Map<String, dynamic> toJson() {
    return {'phone_or_Email': phoneOrEmail, 'password': password};
  }
}

class LoginWithOtpModel {
  final String phoneOrEmail;
  final String otp;

  LoginWithOtpModel({required this.phoneOrEmail, required this.otp});

  Map<String, dynamic> toJson() {
    return {'phone_or_Email': phoneOrEmail, 'otp': otp};
  }
}
