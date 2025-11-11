import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'models/tcg_card.dart';
import 'services/tcg_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HpBattleApp());
}

class HpBattleApp extends StatelessWidget {
  const HpBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon HP Battle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
      ),
      home: const HpBattleScreen(),
    );
  }
}

class HpBattleScreen extends StatefulWidget {
  const HpBattleScreen({super.key});

  @override
  State<HpBattleScreen> createState() => _HpBattleScreenState();
}

class _HpBattleScreenState extends State<HpBattleScreen> {
  late Future<List<TcgCard>> _futurePair;

  @override
  void initState() {
    super.initState();
    _futurePair = TcgApi.fetchRandomBattlePair();
  }

  void _battleAgain() {
    setState(() {
      _futurePair = TcgApi.fetchRandomBattlePair();
    });
  }

  String _winnerText(List<TcgCard> pair) {
    if (pair.length < 2) return 'Waiting for cards...';
    final a = pair[0];
    final b = pair[1];
    if (a.hp > b.hp) return '${a.name} wins! (${a.hp} HP vs ${b.hp} HP)';
    if (b.hp > a.hp) return '${b.name} wins! (${b.hp} HP vs ${a.hp} HP)';
    return 'It\'s a tie! (${a.hp} HP each)';
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokémon HP Battle')),
      body: FutureBuilder<List<TcgCard>>(
        future: _futurePair,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snap.error}\n\nIf you\'re on Web and the API is blocked, a static fallback may be used.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final pair = (snap.data ?? []);
          if (pair.length < 2) {
            return const Center(child: Text('Could not load two valid cards.'));
          }

          final a = pair[0];
          final b = pair[1];

          return Column(
            children: [
              const SizedBox(height: 12),
              Text(
                _winnerText(pair),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _CardPanel(card: a)),
                    const VerticalDivider(width: 1),
                    Expanded(child: _CardPanel(card: b)),
                  ],
                ),
              ),

              SafeArea(
                minimum: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _battleAgain,
                    icon: const Icon(Icons.casino),
                    label: const Text('Battle Again'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardPanel extends StatelessWidget {
  const _CardPanel({required this.card});
  final TcgCard card;

  @override
  Widget build(BuildContext context) {
    final imageUrl = card.largeImageUrl ?? card.smallImageUrl;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openEnlarged(context, card),
            child: Hero(
              tag: 'hero-${card.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                        )
                      : const ColoredBox(
                          color: Color(0xFFEAEAEA),
                          child: Center(child: Icon(Icons.image_not_supported, size: 48)),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(card.name, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('HP: ${card.hp}', style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }

  void _openEnlarged(BuildContext context, TcgCard card) {
    final url = card.largeImageUrl ?? card.smallImageUrl;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Hero(
              tag: 'hero-${card.id}',
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: url != null
                    ? CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)
                    : const Icon(Icons.image_not_supported, color: Colors.white, size: 64),
              ),
            ),
          ),
        );
      },
    );
  }
}
