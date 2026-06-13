import '../../core/coordinate/coordinate_converter.dart';

class LiveLocation {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final LatLng84 position;
  final DateTime updatedAt;

  LiveLocation({
    required this.userId,
    required this.userName,
    required this.position,
    required this.updatedAt,
    this.avatarUrl,
  });

  LiveLocation copyWith({
    String? userId,
    String? userName,
    String? avatarUrl,
    LatLng84? position,
    DateTime? updatedAt,
  }) {
    return LiveLocation(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'position': {
        'lat': position.latitude,
        'lng': position.longitude,
      },
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    return LiveLocation(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'],
      position: LatLng84(
        (json['position']['lat'] as num).toDouble(),
        (json['position']['lng'] as num).toDouble(),
      ),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
