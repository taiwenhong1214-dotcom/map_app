import '../../domain/entities/itinerary.dart';

class SocialPost {
  final String id;
  final String authorName;
  final String? authorId;
  final String authorAvatarUrl;
  final String title;
  final String description;
  final String coverImageUrl;
  final int likesCount;
  final int copyCount;
  final Itinerary itinerary;
  final DateTime postedAt;
  final bool isLikedByMe;

  const SocialPost({
    required this.id,
    required this.authorName,
    this.authorId,
    required this.authorAvatarUrl,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.likesCount,
    required this.copyCount,
    required this.itinerary,
    required this.postedAt,
    this.isLikedByMe = false,
  });

  SocialPost copyWith({
    String? id,
    String? authorName,
    String? authorId,
    String? authorAvatarUrl,
    String? title,
    String? description,
    String? coverImageUrl,
    int? likesCount,
    int? copyCount,
    Itinerary? itinerary,
    DateTime? postedAt,
    bool? isLikedByMe,
  }) {
    return SocialPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      likesCount: likesCount ?? this.likesCount,
      copyCount: copyCount ?? this.copyCount,
      itinerary: itinerary ?? this.itinerary,
      postedAt: postedAt ?? this.postedAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'authorId': authorId,
        'authorAvatarUrl': authorAvatarUrl,
        'title': title,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'likesCount': likesCount,
        'copyCount': copyCount,
        'itinerary': itinerary.toJson(),
        'postedAt': postedAt.toIso8601String(),
        // isLikedByMe is local state, usually don't persist to global feed
      };

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        authorId: json['authorId'] as String?,
        authorAvatarUrl: json['authorAvatarUrl'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        coverImageUrl: json['coverImageUrl'] as String,
        likesCount: json['likesCount'] as int? ?? 0,
        copyCount: json['copyCount'] as int? ?? 0,
        itinerary: Itinerary.fromJson(json['itinerary'] as Map<String, dynamic>),
        postedAt: DateTime.parse(json['postedAt'] as String),
      );
}