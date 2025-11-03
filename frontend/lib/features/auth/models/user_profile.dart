import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.points,
  });

  final int id;
  final String username;
  final String email;
  final int points;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: (json['email'] ?? '') as String,
      points: (json['points'] ?? 0) as int,
    );
  }

  UserProfile copyWith({int? points}) {
    return UserProfile(
      id: id,
      username: username,
      email: email,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [id, username, email, points];
}
