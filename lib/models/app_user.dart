import 'user_role.dart';

/// Oddiy foydalanuvchi — faqat ism va rol (server yo‘q).
class AppUser {
  const AppUser({
    required this.name,
    required this.role,
  });

  final String name;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
}
