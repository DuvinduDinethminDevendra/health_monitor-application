import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../models/user.dart' as model;
import 'sync_service.dart';

class AuthService with ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? 'dummy-client-id.apps.googleusercontent.com' : null,
  );
  final UserRepository _userRepository = UserRepository();
  final SyncService _syncService = SyncService();

  fb.User? _firebaseUser;
  model.User? _currentLocalUser;
  bool _isFirstTimeLogin = false;
  final Set<String> _syncingUserIds = {};

  model.User? get currentUser => _currentLocalUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isFirstTimeLogin => _isFirstTimeLogin;
  bool _forceDark = false;

  bool get isDarkMode => _currentLocalUser?.isDarkMode ?? _forceDark;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  void clearFirstTimeLogin() {
    _isFirstTimeLogin = false;
  }

  AuthService() {
    _loadTheme();
    _auth.authStateChanges().listen((fb.User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _syncLocalUser(user);
        _currentLocalUser = await _userRepository.getUserById(user.uid);
        // Trigger both ways: Rehydrate (Cloud -> Local) and Sync (Local -> Cloud)
        await _syncService.rehydrateData(user.uid);
        await _syncService.syncData(user.uid);
      } else {
        _currentLocalUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool?> signInWithGoogle() async {
    try {
      fb.UserCredential credential;
      if (kIsWeb) {
        fb.GoogleAuthProvider googleProvider = fb.GoogleAuthProvider();
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // Return null for cancellation

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final fb.AuthCredential cred = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(cred);
      }
      
      if (credential.user != null) {
        _currentLocalUser = await _userRepository.getUserById(credential.user!.uid);
        notifyListeners();
      }

      final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        _isFirstTimeLogin = true;
      }
      return isNewUser;
    } catch (e) {
      print("Error in Google Sign In: $e");
      rethrow;
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      fb.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await result.user?.updateDisplayName(name);
        _currentLocalUser = await _userRepository.getUserById(result.user!.uid);
        notifyListeners();
      }
      
      _isFirstTimeLogin = true;
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered. Please login or use "Sign in with Google".';
      } else if (e.code == 'weak-password') {
        return 'The password provided is too weak. Please use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is not valid.';
      }
      return e.message ?? 'Registration failed. Please try again.';
    } catch (e) {
      print("Error in register: $e");
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      fb.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        _currentLocalUser = await _userRepository.getUserById(result.user!.uid);
        notifyListeners();
      }
      
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Invalid email or password.';
      }
      return e.message ?? 'Login failed.';
    } catch (e) {
      print("Error in sign in: $e");
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      fb.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        _currentLocalUser = await _userRepository.getUserById(result.user!.uid);
        notifyListeners();
      }
      
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Invalid email or password.\n\nDid you previously register using Google? If so, please use the "Sign in with Google" button below.';
      }
      return e.message ?? 'Login failed. Please try again.';
    } catch (e) {
      print("Error in login: $e");
      return 'An unexpected error occurred.';
    }
  }

  Future<void> logout() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
    _currentLocalUser = null;
    notifyListeners();
  }

  Future<void> _syncLocalUser(fb.User firebaseUser) async {
    if (_syncingUserIds.contains(firebaseUser.uid)) return;
    _syncingUserIds.add(firebaseUser.uid);
    
    try {
      final localUser = await _userRepository.getUserById(firebaseUser.uid);
      if (localUser == null) {
        // Check if profile exists in Firestore FIRST
        final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          // Restore from Cloud!
          final cloudUser = model.User.fromMap(doc.data()!);
          await _userRepository.insertUser(cloudUser);
        } else {
          // Brand new user
          final newUser = model.User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            password: '',
            createdAt: DateTime.now().toIso8601String(),
          );
          await _userRepository.insertUser(newUser);
          await _syncService.syncUserProfile(newUser);
        }
      }
    } finally {
      _syncingUserIds.remove(firebaseUser.uid);
    }
  }

  // Member 3 Feature: Advanced Profile Management
  Future<void> updateUserProfile(model.User updatedUser) async {
    await _userRepository.updateUser(updatedUser);
    await _syncService.syncUserProfile(updatedUser); // Add explicit sync to Firebase!
    _currentLocalUser = updatedUser;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_currentLocalUser == null) {
      _forceDark = !_forceDark;
      notifyListeners();
      return;
    }
    final updatedUser = _currentLocalUser!.copyWith(
      isDarkMode: !_currentLocalUser!.isDarkMode,
    );
    await updateUserProfile(updatedUser);
  }

  Future<void> _loadTheme() async {
    try {
      final db = await _userRepository.database;
      final maps = await db.query('users', orderBy: 'created_at DESC', limit: 1);
      if (maps.isNotEmpty) {
        _forceDark = maps.first['is_dark_mode'] == 1;
        notifyListeners();
      }
    } catch (e) {
      print("Error loading theme: $e");
    }
  }
}
