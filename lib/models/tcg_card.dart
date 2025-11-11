class TcgCard {
  final String id;
  final String name;
  final String? smallImageUrl;
  final String? largeImageUrl;
  final int hp; // numeric, non-negative

  TcgCard({
    required this.id,
    required this.name,
    required this.smallImageUrl,
    required this.largeImageUrl,
    required this.hp,
  });

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final rawHp = (json['hp'] ?? '').toString().trim();
    final parsedHp = int.tryParse(rawHp) ?? 0; // many cards store HP as string

    return TcgCard(
      id: json['id'] as String,
      name: json['name'] as String,
      smallImageUrl: images != null ? images['small'] as String? : null,
      largeImageUrl: images != null ? images['large'] as String? : null,
      hp: parsedHp < 0 ? 0 : parsedHp,
    );
  }
}
