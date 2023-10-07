// models.dart

class User {
  final String phoneNumber;
  final String name;
  final String password;
  final String password2;
  final String pin;

  User({
    required this.phoneNumber,
    required this.name,
    required this.password,
    required this.password2,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'name': name,
      'password': password,
      'pin': pin,
    };
  }
}
