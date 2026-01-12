import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String leaderId;
  final String leaderName;
  final String? leaderProfilePhotoUrl;
  final String caption;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> likedBy; // User IDs who liked
  final List<CommentModel> comments;
  final int shareCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.leaderId,
    required this.leaderName,
    this.leaderProfilePhotoUrl,
    required this.caption,
    this.imageUrl,
    this.videoUrl,
    this.likedBy = const [],
    this.comments = const [],
    this.shareCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'leaderProfilePhotoUrl': leaderProfilePhotoUrl,
      'caption': caption,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'likedBy': likedBy,
      'comments': comments.map((c) => c.toMap()).toList(),
      'shareCount': shareCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      leaderId: map['leaderId'] ?? '',
      leaderName: map['leaderName'] ?? '',
      leaderProfilePhotoUrl: map['leaderProfilePhotoUrl'],
      caption: map['caption'] ?? '',
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      likedBy: List<String>.from(map['likedBy'] ?? []),
      comments:
          (map['comments'] as List?)
              ?.map((c) => CommentModel.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      shareCount: map['shareCount'] ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    return PostModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  PostModel copyWith({
    String? id,
    String? leaderId,
    String? leaderName,
    String? leaderProfilePhotoUrl,
    String? caption,
    String? imageUrl,
    String? videoUrl,
    List<String>? likedBy,
    List<CommentModel>? comments,
    int? shareCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      leaderProfilePhotoUrl:
          leaderProfilePhotoUrl ?? this.leaderProfilePhotoUrl,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get likesCount => likedBy.length;

  int get commentsCount => comments.length;
}

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToUserName;
  final bool isEdited;
  final List<String> likedBy;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.replyToUserName,
    this.isEdited = false,
    this.likedBy = const [],
  });

  int get likeCount => likedBy.length;

  CommentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? createdAt,
    String? replyToId,
    String? replyToUserName,
    bool? isEdited,
    List<String>? likedBy,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      replyToId: replyToId ?? this.replyToId,
      replyToUserName: replyToUserName ?? this.replyToUserName,
      isEdited: isEdited ?? this.isEdited,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': createdAt,
      'replyToId': replyToId,
      'replyToUserName': replyToUserName,
      'isEdited': isEdited,
      'likedBy': likedBy,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      replyToId: map['replyToId'],
      replyToUserName: map['replyToUserName'],
      isEdited: map['isEdited'] ?? false,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }
}
