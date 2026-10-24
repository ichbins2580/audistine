class ImagerySlot {
  final int id; // 1, 2, 3
  final String title;
  final String imageUrl; // preset URL or custom URL or empty
  final String description;

  const ImagerySlot({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'description': description,
  };

  factory ImagerySlot.fromJson(Map<String, dynamic> json) {
    return ImagerySlot(
      id: (json['id'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '평온한 안식처',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  static List<ImagerySlot> defaultSlots() => const [
    ImagerySlot(
      id: 1,
      title: '아침 햇살의 숲길',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
      description: '상쾌한 피톤치드 향기와 나뭇잎 사이로 내리는 따스한 빛',
    ),
    ImagerySlot(
      id: 2,
      title: '고요한 산정 호수',
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      description: '거울처럼 잔잔한 물결과 맑고 청명한 공기',
    ),
    ImagerySlot(
      id: 3,
      title: '따스한 노을 해변',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      description: '부드러운 파도 소리와 붉게 물든 포근한 하늘',
    ),
  ];

  static const List<({String title, String url, String desc})> presets = [
    (
      title: '아침 햇살의 숲길',
      url: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
      desc: '피톤치드 가득한 숲속의 맑은 공기와 잎새 사이 햇살',
    ),
    (
      title: '고요한 산정 호수',
      url: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      desc: '물결 하나 없이 맑고 투명한 평온의 호수',
    ),
    (
      title: '따스한 노을 해변',
      url: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      desc: '부드럽게 밀려오는 파도 소리와 따스한 저녁 바람',
    ),
    (
      title: '그윽한 대나무 숲',
      url: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80',
      desc: '바람에 서걱이는 댓잎 소리와 깊은 숲의 청량함',
    ),
    (
      title: '평화로운 안개 초원',
      url: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=800&q=80',
      desc: '시원한 풀 내음과 아득히 펼쳐진 초록의 들판',
    ),
    (
      title: '아늑한 밤하늘과 은하수',
      url: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80',
      desc: '별빛이 쏟아지는 조용하고 장엄한 밤의 휴식',
    ),
  ];
}
