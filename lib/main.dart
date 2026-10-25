import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const GamesApp());

class GamesApp extends StatelessWidget {
  const GamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1A73E8);
    return MaterialApp(
      title: 'Live Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Games')),
      body: IndexedStack(
        index: _index,
        children: const [ClickerPage(), VoteyPage(), WheelPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.touch_app), label: 'Кликер'),
          NavigationDestination(
              icon: Icon(Icons.how_to_vote), label: 'Голосование'),
          NavigationDestination(icon: Icon(Icons.casino), label: 'Колесо'),
        ],
      ),
    );
  }
}

class ClickerPage extends StatefulWidget {
  const ClickerPage({super.key});

  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Клики', style: t.titleMedium),
          Text('$_count', style: t.displayLarge),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => setState(() => _count += 1),
                child: const Text('Лайк +1'),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: () => setState(() => _count += 10),
                child: const Text('Подарок +10'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _count = 0),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

class VoteyPage extends StatefulWidget {
  const VoteyPage({super.key});

  @override
  State<VoteyPage> createState() => _VoteyPageState();
}

class _VoteyPageState extends State<VoteyPage> {
  int _a = 0;
  int _b = 0;

  Widget _option(String name, int votes, double share, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Вариант $name: $votes (${(share * 100).toStringAsFixed(0)}%)'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: share,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _a + _b;
    final pa = total == 0 ? 0.0 : _a / total;
    final pb = total == 0 ? 0.0 : _b / total;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _option('A', _a, pa, () => setState(() => _a++)),
          const SizedBox(height: 16),
          _option('B', _b, pb, () => setState(() => _b++)),
          const SizedBox(height: 24),
          Text('Всего голосов: $total', textAlign: TextAlign.center),
          TextButton(
            onPressed: () => setState(() {
              _a = 0;
              _b = 0;
            }),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

class WheelPage extends StatefulWidget {
  const WheelPage({super.key});

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage> {
  final Random _rnd = Random();
  final List<String> _prizes = const [
    '50 очков',
    '100 очков',
    '150 очков',
    '200 очков',
    '300 очков',
    '500 очков',
  ];
  final List<String> _history = [];
  double _turns = 0;
  String _result = 'Нажми «Крутить»';

  void _spin() {
    final prize = _prizes[_rnd.nextInt(_prizes.length)];
    setState(() {
      _turns += 3 + _rnd.nextDouble();
      _result = prize;
      _history.insert(0, prize);
      if (_history.length > 10) _history.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedRotation(
            turns: _turns,
            duration: const Duration(seconds: 2),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.casino, size: 120, color: scheme.primary),
          ),
          const SizedBox(height: 24),
          Text(_result, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _spin,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Крутить'),
          ),
          const SizedBox(height: 24),
          Text('История: ${_history.join(', ')}',
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
