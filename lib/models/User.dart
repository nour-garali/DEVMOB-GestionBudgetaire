import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? photoUrl;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.photoUrl,
  });

  factory User.fromMap(String uid, Map<String, dynamic> map) {
    return User(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
    };
  }
}
