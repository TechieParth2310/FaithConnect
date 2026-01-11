import 'package:cloud_firestore/cloud_firestore.dart';

class ReelModel {
  final String id;
  final String authorId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final List<String> likes;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReelModel({
    required this.id,
    required this.authorId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    this.likes = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.hashtags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'likes': likes,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'hashtags': hashtags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ReelModel.fromMap(Map<String, dynamic> map) {
    return ReelModel(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      caption: map['caption'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      hashtags: List<String>.from(map['hashtags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory ReelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReelModel.fromMap(data);
  }

  ReelModel copyWith({
    String? id,
    String? authorId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? likes,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReelModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Extract hashtags from caption
  static List<String> extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!.toLowerCase()).toList();
  }
}
