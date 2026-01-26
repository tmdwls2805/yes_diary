class Emotion {
  final int id;
  final String name;
  final String? imageUrl;

  Emotion({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  /// Emotion 객체를 Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  /// Map에서 Emotion 객체로 변환 (데이터베이스 조회용)
  factory Emotion.fromMap(Map<String, dynamic> map) {
    return Emotion(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Emotion &&
        other.id == id &&
        other.name == name &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ imageUrl.hashCode;

  @override
  String toString() {
    return 'Emotion(id: $id, name: $name, imageUrl: $imageUrl)';
  }
}
