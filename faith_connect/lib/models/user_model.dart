import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { worshiper, religiousLeader }

enum FaithType { christianity, islam, judaism, hinduism, other }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final UserRole role;
  final FaithType faith;
  final String? bio;
  final List<String> following; // IDs of leaders being followed
  final List<String> followers; // IDs of followers
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final List<String> fcmTokens; // FCM tokens for push notifications

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    required this.role,
    required this.faith,
    this.bio,
    this.following = const [],
    this.followers = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastSeen,
    this.isOnline = false,
    this.fcmTokens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role.toString().split('.').last,
      'faith': faith.toString().split('.').last,
      'bio': bio,
      'following': following,
      'followers': followers,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
      'fcmTokens': fcmTokens,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'],
      role: map['role'] == 'religiousLeader'
          ? UserRole.religiousLeader
          : UserRole.worshiper,
      faith: _parseFaith(map['faith'] ?? 'other'),
      bio: map['bio'],
      following: List<String>.from(map['following'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toString()),
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] is Timestamp
                ? (map['lastSeen'] as Timestamp).toDate()
                : DateTime.parse(map['lastSeen']))
          : null,
      isOnline: map['isOnline'] ?? false,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhotoUrl,
    UserRole? role,
    FaithType? faith,
    String? bio,
    List<String>? following,
    List<String>? followers,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      faith: faith ?? this.faith,
      bio: bio ?? this.bio,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';
}

FaithType _parseFaith(String faith) {
  switch (faith.toLowerCase()) {
    case 'christianity':
      return FaithType.christianity;
    case 'islam':
      return FaithType.islam;
    case 'judaism':
      return FaithType.judaism;
    case 'hinduism':
      return FaithType.hinduism;
    default:
      return FaithType.other;
  }
}

String faithTypeToString(FaithType faith) {
  switch (faith) {
    case FaithType.christianity:
      return 'Christianity';
    case FaithType.islam:
      return 'Islam';
    case FaithType.judaism:
      return 'Judaism';
    case FaithType.hinduism:
      return 'Hinduism';
    case FaithType.other:
      return 'Other';
  }
}
