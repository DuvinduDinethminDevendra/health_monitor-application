import 'dart:convert';

// A "Model" in Flutter is just a blueprint for an object.
// Think of this like a blank form that every new user has to fill out.
class User {
  // These are the properties (the blank fields on the form)
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
  final bool isDarkMode;

  // This is the Constructor. It tells Flutter how to create a new User object in memory.
  // The 'required' keyword means that a User MUST have a name, email, and password to be created.
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
    this.isDarkMode = false,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // toMap() is a Translator. 
  // SQLite and Firebase do NOT understand Dart objects. They only understand Maps (Key-Value pairs).
  // This function takes our Dart User object and converts it into a Map so it can be saved in the database.
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
      'is_dark_mode': isDarkMode ? 1 : 0,
      // We convert the list of topics into a JSON string because SQLite can't store Lists directly
      'interests': interests != null ? jsonEncode(interests) : null,
    };
  }

  // factory fromMap() is the Reverse Translator.
  // When we pull data from SQLite or Firebase, it comes back as a Map.
  // This function takes that Map and builds a proper Dart User object so our app's UI can use it.
  factory User.fromMap(Map<String, dynamic> map) {
    List<String>? parsedInterests;
    if (map['interests'] != null) {
      if (map['interests'] is String) {
        // If it came from SQLite, decode it from a string back into a List
        parsedInterests = List<String>.from(jsonDecode(map['interests']));
      } else if (map['interests'] is List) {
        // If it came from Firebase directly as an array
        parsedInterests = List<String>.from(map['interests']); 
      }
    }

    return User(
      id: map['id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: map['created_at'] as String,
      age: (map['age'] as num?)?.toInt(),
      gender: map['gender'] as String?,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      profilePicture: map['profile_picture'] as String?,
      interests: parsedInterests,
      isDarkMode: (map['is_dark_mode'] == 1 || map['is_dark_mode'] == true),
    );
  }

  // copyWith() is a shortcut function for updating users.
  // Dart objects are often "immutable" (unchangeable). So if you want to change just a user's age, 
  // you don't edit the object directly. You use copyWith to create a completely new clone of the user 
  // with everything identical, EXCEPT the one variable (like age) you want to change.
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
    bool? isDarkMode,
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
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
