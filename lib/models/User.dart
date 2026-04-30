import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? photoUrl;
  final String? country;
  final DateTime? dateOfBirth;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.photoUrl,
    this.country,
    this.dateOfBirth,
  });

  factory User.fromMap(String uid, Map<String, dynamic> map) {
    return User(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      photoUrl: map['photoUrl'],
      country: map['country'],
      dateOfBirth: map['dateOfBirth'] != null ? (map['dateOfBirth'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'country': country,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
    };
  }
}
