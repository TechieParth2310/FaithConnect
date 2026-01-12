import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  final int viewCount;

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.viewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
      'viewCount': viewCount,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      mediaUrl: map['mediaUrl'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      caption: map['caption'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      viewCount: map['viewCount'] ?? 0,
    );
  }

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel.fromMap(data, doc.id);
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool hasBeenViewedBy(String userId) {
    return viewedBy.contains(userId);
  }

  Duration get timeRemaining {
    return expiresAt.difference(DateTime.now());
  }

  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m left';
    } else {
      return 'Expiring soon';
    }
  }
}
