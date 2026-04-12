import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthService extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final existing = await _userRepo.getUserByEmail(email);
      if (existing != null) {
        return 'An account with this email already exists.';
      }

      final user = User(
        name: name,
        email: email,
        password: _hashPassword(password),
      );

      final id = await _userRepo.insertUser(user);
      _currentUser = user.copyWith(id: id);
      notifyListeners();
      return null; // success
    } catch (e) {
      return 'Registration failed: ${e.toString()}';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final user = await _userRepo.getUserByEmail(email);
      if (user == null) {
        return 'No account found with this email.';
      }

      if (user.password != _hashPassword(password)) {
        return 'Incorrect password.';
      }

      _currentUser = user;
      notifyListeners();
      return null; // success
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
