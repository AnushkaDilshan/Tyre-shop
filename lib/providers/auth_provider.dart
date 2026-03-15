import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _service.authStateChanges.listen((user) {
      final previousUser = _user;
      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;

      // If user changed (logout or new login), notify to clear data
      if (previousUser?.uid != user?.uid) {
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.signIn(email.trim(), password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

Future<bool> signUp(String email, String password, {String shopName = 'My Tyre Shop'}) async {
  _status = AuthStatus.loading;
  _errorMessage = null;
  notifyListeners();
  try {
    await _service.signUp(email.trim(), password, shopName: shopName);
    return true;
  } on FirebaseAuthException catch (e) {
    _errorMessage = _mapFirebaseError(e.code);
    _status = AuthStatus.error;
    notifyListeners();
    return false;
  } catch (e) {
    if (_service.userId.isNotEmpty) return true;
    _errorMessage = 'Registration failed. Please try again.';
    _status = AuthStatus.error;
    notifyListeners();
    return false;
  }
}

  Future<void> signOut() async {
    await _service.signOut();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
