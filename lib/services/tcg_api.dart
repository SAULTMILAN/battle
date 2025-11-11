import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tcg_card.dart';

/// Web-friendly service:
/// 1) direct call (no API key/header)
/// 2) proxy #1 (isomorphic-git)
/// 3) proxy #2 (allorigins)
/// 4) static fallback cards (always works for demo)
class TcgApi {
  static const String _directBase = 'https://api.pokemontcg.io/v2';
  static const String _proxyIsoGit = 'https://cors.isomorphic-git.org/https://api.pokemontcg.io/v2';
  static const String _proxyAllOrigins = 'https://api.allorigins.win/raw?url=';

  static Future<List<TcgCard>> fetchGrassCards({int page = 1, int pageSize = 20}) async {
    final query = '/cards?q=types:grass&select=id,name,images&page=$page&pageSize=$pageSize&orderBy=name';

    // Try 1: direct (best, no CORS issues on normal networks)
    final direct = await _tryFetch('$_directBase$query');
    if (direct != null) return direct;

    // Try 2: proxy #1 (isomorphic-git)
    final viaIsoGit = await _tryFetch('$_proxyIsoGit$query');
    if (viaIsoGit != null) return viaIsoGit;

    // Try 3: proxy #2 (allorigins) – needs encoded target URL
    final encoded = Uri.encodeFull('$_directBase$query');
    final viaAllOrigins = await _tryFetch('$_proxyAllOrigins$encoded', allOrigins: true);
    if (viaAllOrigins != null) return viaAllOrigins;

    // Try 4: static fallback (guaranteed)
    return _fallbackGrassCards();
  }

  /// Attempts a GET and decodes the standard Pokémon TCG API JSON shape.
  /// If [allOrigins] is true, the body is already the raw target payload.
  static Future<List<TcgCard>?> _tryFetch(String url, {bool allOrigins = false}) async {
    try {
      final uri = Uri.parse(url);
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;

      final body = resp.body;
      final Map<String, dynamic> decoded = json.decode(body) as Map<String, dynamic>;
      final List<dynamic> data = (decoded['data'] as List<dynamic>? ?? []);
      return data.map((e) => TcgCard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null; // swallow and let the next strategy run
    }
  }

  /// Always-works fallback (static grass cards). Uses the official image CDN.
  static List<TcgCard> _fallbackGrassCards() {
    final raw = [
      {
        "id": "base1-44",
        "name": "Bulbasaur",
        "images": {
          "small": "https://images.pokemontcg.io/base1/44.png",
          "large": "https://images.pokemontcg.io/base1/44_hires.png"
        }
      },
      {
        "id": "base1-30",
        "name": "Ivysaur",
        "images": {
          "small": "https://images.pokemontcg.io/base1/30.png",
          "large": "https://images.pokemontcg.io/base1/30_hires.png"
        }
      },
      {
        "id": "base1-15",
        "name": "Venusaur",
        "images": {
          "small": "https://images.pokemontcg.io/base1/15.png",
          "large": "https://images.pokemontcg.io/base1/15_hires.png"
        }
      },
      {
        "id": "base1-58",
        "name": "Oddish",
        "images": {
          "small": "https://images.pokemontcg.io/base1/58.png",
          "large": "https://images.pokemontcg.io/base1/58_hires.png"
        }
      },
      {
        "id": "base1-51",
        "name": "Tangela",
        "images": {
          "small": "https://images.pokemontcg.io/base1/51.png",
          "large": "https://images.pokemontcg.io/base1/51_hires.png"
        }
      },
      {
        "id": "base1-49",
        "name": "Bellsprout",
        
        "images": {
          "small": "https://images.pokemontcg.io/base1/49.png",
          "large": "https://images.pokemontcg.io/base1/49_hires.png"
        }
      }
    ];
    return raw.map((e) => TcgCard.fromJson(e)).toList();
  }
}
