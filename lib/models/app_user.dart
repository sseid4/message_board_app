class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime registrationDatetime;
  final DateTime? dob;

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.registrationDatetime,
    this.dob,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'registrationDatetime': registrationDatetime.toUtc().toIso8601String(),
    if (dob != null) 'dob': dob!.toUtc().toIso8601String(),
  };

  static AppUser fromMap(Map<String, dynamic> m) => AppUser(
    uid: m['uid'] as String,
    firstName: m['firstName'] as String? ?? '',
    lastName: m['lastName'] as String? ?? '',
    role: m['role'] as String? ?? '',
    registrationDatetime:
        DateTime.tryParse(m['registrationDatetime'] ?? '') ?? DateTime.now(),
    dob: m['dob'] != null ? DateTime.tryParse(m['dob']) : null,
  );
}
