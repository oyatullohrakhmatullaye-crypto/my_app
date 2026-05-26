/// Dasturda faqat ikkita rol: do‘kon egasi va sotuvchi.
enum UserRole {
  admin,
  worker,
}

extension UserRoleLabel on UserRole {
  String get labelUz => switch (this) {
        UserRole.admin => 'Administrator',
        UserRole.worker => 'Ishchi',
      };
}
