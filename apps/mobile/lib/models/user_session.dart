class UserSession {
  final String id;
  final String username;
  final String role; // 'ADMIN', 'AGENT', 'FARMER'
  final String fullName;
  final String? county;
  final String token;

  UserSession({
    required this.id,
    required this.username,
    required this.role,
    required this.fullName,
    this.county,
    required this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json, String token) {
    final u = json['user'] ?? json;
    return UserSession(
      id: u['id'] ?? '',
      username: u['username'] ?? '',
      role: u['role'] ?? 'FARMER',
      fullName: u['full_name'] ?? 'User',
      county: u['county'],
      token: token,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isAgent => role == 'AGENT';
  bool get isFarmer => role == 'FARMER';
}
