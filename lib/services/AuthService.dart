import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/User.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream - écoute l'état de connexion en temps réel
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur courant
  firebase_auth.User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // ─── Inscription ─────────────────────────────────────────────────────────
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final userModel = User(
      uid: user.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    // Sauvegarder le profil dans Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // ─── Connexion ────────────────────────────────────────────────────────────
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return User.fromMap(user.uid, doc.data()!);
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Récupérer le profil utilisateur ────────────────────────────────────
  Future<User?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return User.fromMap(uid, doc.data()!);
  }

  // ─── Mettre à jour le profil ─────────────────────────────────────────────
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ─── Réinitialisation de mot de passe ───────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
