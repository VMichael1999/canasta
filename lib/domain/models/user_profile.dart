import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.firstName,
    required this.email,
    required this.phone,
  });

  final String name;
  final String firstName;
  final String email;
  final String phone;

  static const UserProfile defaultUser = UserProfile(
    name: 'Michael Dev',
    firstName: 'Michael',
    email: 'michaeldev@gmail.com',
    phone: '987 654 321',
  );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'MD';
  }

  @override
  List<Object?> get props => [name, firstName, email, phone];
}
