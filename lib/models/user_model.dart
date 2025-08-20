// lib/models/user_model.dart

class UserCreateModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String city;

  UserCreateModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'Password': password,
      'City': city,
    };
  }
}

class UserProfileUpdateModel {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? email;
  final String? city;

  UserProfileUpdateModel({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'FirstName': firstName,
      if (lastName != null) 'LastName': lastName,
      if (phoneNumber != null) 'PhoneNumber': phoneNumber,
      if (email != null) 'Email': email,
      if (city != null) 'City': city,
    }..removeWhere((key, value) => value == null);
  }
}

class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'UserID': int userId,
        'FirstName': String firstName,
        'LastName': String lastName,
        'Email': String email,
        'PhoneNumber': String phoneNumber,
        'Role': String role,
      } =>
        UserModel(
          userId: userId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
        ),
      _ => throw const FormatException('Failed to load user model.'),
    };
  }
}
