class MediaAsset {
  final String id;
  final String uri;
  final String mediaType;
  final int duration;

  MediaAsset({
    required this.id,
    required this.uri,
    required this.mediaType,
    required this.duration,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      uri: json['uri'] as String,
      mediaType: json['mediaType'] as String,
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uri': uri,
      'mediaType': mediaType,
      'duration': duration,
    };
  }

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'MediaAsset(id: $id, uri: $uri, mediaType: $mediaType, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaAsset &&
        other.id == id &&
        other.uri == uri &&
        other.mediaType == mediaType &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uri.hashCode ^
        mediaType.hashCode ^
        duration.hashCode;
  }
}
