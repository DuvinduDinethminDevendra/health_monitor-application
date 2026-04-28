import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../repositories/user_repository.dart';
import '../models/user.dart' as model;
import 'sync_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? 'dummy-client-id.apps.googleusercontent.com' : null,
  );
  final UserRepository _userRepository = UserRepository();
  final SyncService _syncService = SyncService();

  User? _firebaseUser;
  model.User? _currentLocalUser;
  bool _isFirstTimeLogin = false;

  model.User? get currentUser => _currentLocalUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isFirstTimeLogin => _isFirstTimeLogin;

  void clearFirstTimeLogin() {
    _isFirstTimeLogin = false;
  }

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
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

  Future<bool> signInWithGoogle() async {
    try {
      UserCredential credential;
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return false;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(cred);
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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);
      _isFirstTimeLogin = true;
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered. Please login or use "Sign in with Google".';
      } else if (e.code == 'weak-password') {
        return 'The password provided is too weak. Please use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is not valid.';
      }
      return e.message ?? 'Registration failed. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Invalid email or password.\n\nDid you previously register using Google? If so, please use the "Sign in with Google" button below.';
      }
      return e.message ?? 'Login failed. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> logout() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
    _currentLocalUser = null;
    notifyListeners();
  }

  Future<void> _syncLocalUser(User firebaseUser) async {
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
  }

  // Member 3 Feature: Advanced Profile Management
  Future<void> updateUserProfile(model.User updatedUser) async {
    await _userRepository.updateUser(updatedUser);
    await _syncService.syncUserProfile(updatedUser); // Add explicit sync to Firebase!
    _currentLocalUser = updatedUser;
    notifyListeners();
  }
}
