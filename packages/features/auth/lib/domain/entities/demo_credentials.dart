final class DemoCredentials {
  const DemoCredentials({required this.identifier, required this.password});

  final String identifier;
  final String password;
}

abstract final class DemoAdmin {
  static const int userId = 1;
  static const String email = 'admin@cootrafa.local';
  static const String fullName = 'Cootrafa Demo Admin';
  static const String password = 'CootrafaDemo2026!';
  static const DemoCredentials credentials = DemoCredentials(
    identifier: email,
    password: password,
  );
}
