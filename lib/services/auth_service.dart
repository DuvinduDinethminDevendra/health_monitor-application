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

  model.User? get currentUser => _currentLocalUser;
  bool get isLoggedIn => _firebaseUser != null;

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

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth's built-in Web Google provider
        // This uses the config you already provided in main.dart!
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
      } else {
        // Standard mobile flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
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
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
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
      await _userRepository.insertUser(model.User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        password: '',
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
  }
}
