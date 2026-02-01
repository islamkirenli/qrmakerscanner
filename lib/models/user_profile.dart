class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarIndex,
  });

  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final int avatarIndex;

  UserProfile copyWith({
    String? email,
    String? firstName,
    String? lastName,
    int? avatarIndex,
  }) {
    return UserProfile(
      userId: userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }
}
