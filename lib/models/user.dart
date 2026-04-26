import 'dart:convert';

class User {
  final String? id; // Firebase UID
  final String name;
  final String email;
  final String password;
  final String createdAt;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? profilePicture; // Base64 string for SQLite offline image
  final List<String>? interests; // Spotify-style topics (Fitness, Diet, etc)

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    String? createdAt,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.profilePicture,
    this.interests,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': createdAt,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'profile_picture': profilePicture,
      // Store list as JSON string for SQLite parsing
      'interests': interests != null ? jsonEncode(interests) : null,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    List<String>? parsedInterests;
    if (map['interests'] != null) {
      if (map['interests'] is String) {
        parsedInterests = List<String>.from(jsonDecode(map['interests']));
      } else if (map['interests'] is List) {
        parsedInterests = List<String>.from(
            map['interests']); // If Firebase gives an array directly
      }
    }

    return User(
      id: map['id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: map['created_at'] as String,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      profilePicture: map['profile_picture'] as String?,
      interests: parsedInterests,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? createdAt,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? profilePicture,
    List<String>? interests,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profilePicture: profilePicture ?? this.profilePicture,
      interests: interests ?? this.interests,
    );
  }
}
