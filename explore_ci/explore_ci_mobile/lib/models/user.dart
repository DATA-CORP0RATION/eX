class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;

  AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
    );
  }

  String get fullName => [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
}
