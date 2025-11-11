import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/tcg_card.dart';

class TcgApi {
  static const String _base = 'https://api.pokemontcg.io/v2';

  /// Fetches two random cards (any type) that have:
  /// - an image
  /// - a numeric HP
  /// If the network is blocked, returns a static fallback pair.
  static Future<List<TcgCard>> fetchRandomBattlePair() async {
    // First try: use random order with a small page
    final firstTry = await _tryFetchRandom(pageSize: 24);
    if (firstTry.length >= 2) {
      return _pickTwoValid(firstTry);
    }

    // Second try: bigger page then shuffle locally
    final secondTry = await _tryFetch(pageSize: 80, orderRandom: false);
    if (secondTry.isNotEmpty) {
      return _pickTwoValid(secondTry);
    }

    // Final: guaranteed fallback
    return _fallbackPair();
  }

  static Future<List<TcgCard>> _tryFetchRandom({int pageSize = 24}) async {
    try {
      final uri = Uri.parse(
        '$_base/cards'
        '?select=id,name,images,hp'
        '&pageSize=$pageSize'
        '&orderBy=random', // server-side randomness
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) return [];
      final decoded = json.decode(r.body) as Map<String, dynamic>;
      final data = (decoded['data'] as List<dynamic>? ?? []);
      return data.map((e) => TcgCard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<TcgCard>> _tryFetch({int pageSize = 80, bool orderRandom = false}) async {
    try {
      final uri = Uri.parse(
        '$_base/cards'
        '?select=id,name,images,hp'
        '&pageSize=$pageSize'
        '${orderRandom ? '&orderBy=random' : ''}',
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) return [];
      final decoded = json.decode(r.body) as Map<String, dynamic>;
      final data = (decoded['data'] as List<dynamic>? ?? []);
      return data.map((e) => TcgCard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static List<TcgCard> _pickTwoValid(List<TcgCard> all) {
    // filter usable: must have image + hp > 0
    final usable = all.where((c) =>
        (c.smallImageUrl != null || c.largeImageUrl != null) && c.hp > 0).toList();
    if (usable.length <= 2) return usable.take(2).toList();

    usable.shuffle(Random());
    return usable.take(2).toList();
  }

  static List<TcgCard> _fallbackPair() {
    // Static pair with valid HP + images
    final raw = [
      {
        "id": "base1-44",
        "name": "Bulbasaur",
        "hp": "40",
        "images": {
          "small": "https://images.pokemontcg.io/base1/44.png",
          "large": "https://images.pokemontcg.io/base1/44_hires.png"
        }
      },
      {
        "id": "base1-30",
        "name": "Ivysaur",
        "hp": "60",
        "images": {
          "small": "https://images.pokemontcg.io/base1/30.png",
          "large": "https://images.pokemontcg.io/base1/30_hires.png"
        }
      },
    ];
    return raw.map((e) => TcgCard.fromJson(e)).toList();
  }
}
