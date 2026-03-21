import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../services/AuthService.dart';
import '../services/secure_storage_service.dart';
import '../models/User.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SecureStorageService _secureStorage = SecureStorageService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _authService.getUserProfile(firebaseUser.uid);
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      if (_user != null) {
        // Stockage sécurisé de l'email (chiffré sur l'appareil)
        await _secureStorage.saveLastEmail(email);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Une erreur inattendue est survenue: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );
      if (_user != null) {
        // Stockage sécurisé de l'email (chiffré sur l'appareil)
        await _secureStorage.saveLastEmail(email);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Une erreur inattendue est survenue: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    // On ne supprime PAS l'email du secure storage pour pouvoir pré-remplir la prochaine fois
    _user = null;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Une erreur est survenue: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible (min. 6 caractères).';
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'operation-not-allowed':
        return 'Connexion email/password non activée.';
      case 'network-request-failed':
        return 'Pas de connexion internet. Verifiez votre reseau puis reessayez.';
      case 'too-many-requests':
        return 'Trop de tentatives. Reessayez dans quelques minutes.';
      default:
        return 'Erreur [${e.code}] : ${e.message}';
    }
  }
}
