import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service pour le stockage local chiffré (Encrypted Storage).
/// Répond à l'exigence du cahier des charges concernant la sécurisation des données.
class SecureStorageService {
  // Instance de stockage chiffré
  // Android : Utilise Keystore (AES)
  // iOS : Utilise Keychain
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Clés de stockage
  static const String _keyLastEmail = 'last_login_email';

  // --- Singleton Pattern ---
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  /// Sauvegarde l'email de manière chiffrée
  Future<void> saveLastEmail(String email) async {
    await _storage.write(key: _keyLastEmail, value: email);
  }

  /// Récupère l'email chiffré
  Future<String?> getLastEmail() async {
    return await _storage.read(key: _keyLastEmail);
  }

  /// Supprime toutes les données chiffrées (utile lors de la déconnexion totale)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
