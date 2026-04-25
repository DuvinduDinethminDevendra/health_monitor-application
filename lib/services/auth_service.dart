import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/sync_service.dart';

class AuthService extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final UserRepository _userRepo = UserRepository();
  final SyncService _syncService = SyncService();
  User? _currentUser;

  AuthService() {
    // Listen for auth state changes (persistent login)
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> _onAuthStateChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      // Fetch user details from local SQLite
      _currentUser = await _userRepo.getUserById(firebaseUser.uid);
      
      // If not in SQLite (e.g. first login on new device), 
      // trigger SyncService restoration
      if (_currentUser == null) {
        await _syncService.rehydrateData(firebaseUser.uid);
        _currentUser = await _userRepo.getUserById(firebaseUser.uid);
        
        // Fallback if rehydration failed or no data exists
        if (_currentUser == null) {
          _currentUser = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            password: '',
          );
        }
      }

    }
    notifyListeners();
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      // 1. Create user in Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update Firebase display name
      await credential.user?.updateDisplayName(name);

      // 3. Create local user model
      final user = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        password: '', // We don't store passwords in SQLite for Firebase Auth
      );

      // 4. Save to SQLite for Member 3 Viva requirements
      await _userRepo.insertUser(user);
      
      _currentUser = user;
      notifyListeners();
      return null; // success
    } on fb.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Registration failed: ${e.toString()}';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      // 1. Sign in with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Fetch/Update local user
      var user = await _userRepo.getUserById(credential.user!.uid);
      
      if (user == null) {
        // Trigger Cloud-to-Local Rehydration
        await _syncService.rehydrateData(credential.user!.uid);
        user = await _userRepo.getUserById(credential.user!.uid);
        
        if (user == null) {
          user = User(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? 'User',
            email: email,
            password: '',
          );
          await _userRepo.insertUser(user);
        }
      }


      _currentUser = user;
      notifyListeners();
      return null; // success
    } on fb.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
