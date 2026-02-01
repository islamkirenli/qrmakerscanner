class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarIndex,
    required this.lastScan,
    required this.lastGenerated,
  });

  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final int avatarIndex;
  final String? lastScan;
  final String? lastGenerated;

  UserProfile copyWith({
    String? email,
    String? firstName,
    String? lastName,
    int? avatarIndex,
    String? lastScan,
    String? lastGenerated,
  }) {
    return UserProfile(
      userId: userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      lastScan: lastScan ?? this.lastScan,
      lastGenerated: lastGenerated ?? this.lastGenerated,
    );
  }
}
