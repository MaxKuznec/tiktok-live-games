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
  final List<int> _prizes = const [50, 100, 150, 200, 250, 300, 500, 1000];
  final List<String> _history = [];
  double _turns = 0;
  bool _spinning = false;
  int? _pendingIndex;
  String _result = 'Нажми «Крутить»';

  void _spin() {
    if (_spinning) return;
    final n = _prizes.length;
    final i = _rnd.nextInt(n);
    final f = 1 - (i + 0.5) / n + (_rnd.nextDouble() - 0.5) * 0.8 / n;
    setState(() {
      _spinning = true;
      _pendingIndex = i;
      _turns = _turns.floorToDouble() + 4 + f;
    });
  }

  void _onSpinEnd() {
    final i = _pendingIndex;
    if (i == null) return;
    setState(() {
      final prize = '${_prizes[i]} очков';
      _result = prize;
      _history.insert(0, prize);
      if (_history.length > 10) _history.removeLast();
      _spinning = false;
      _pendingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 320,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 24,
                    child: AnimatedRotation(
                      turns: _turns,
                      duration: const Duration(seconds: 4),
                      curve: Curves.easeOutCubic,
                      onEnd: _onSpinEnd,
                      child: SizedBox(
                        width: 296,
                        height: 296,
                        child: CustomPaint(
                          painter: WheelPainter(
                            labels: _prizes.map((p) => '$p').toList(),
                            colors: [
                              scheme.primaryContainer,
                              scheme.secondaryContainer,
                              scheme.tertiaryContainer,
                            ],
                            textColors: [
                              scheme.onPrimaryContainer,
                              scheme.onSecondaryContainer,
                              scheme.onTertiaryContainer,
                            ],
                            lineColor: scheme.surface,
                            hubColor: scheme.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      size: 56, color: scheme.onSurface),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_result, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _spinning ? null : _spin,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Крутить'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('История: ${_history.join(', ')}',
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  WheelPainter({
    required this.labels,
    required this.colors,
    required this.textColors,
    required this.lineColor,
    required this.hubColor,
  });

  final List<String> labels;
  final List<Color> colors;
  final List<Color> textColors;
  final Color lineColor;
  final Color hubColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2;
    final n = labels.length;
    final sweep = 2 * pi / n;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = lineColor;

    for (var i = 0; i < n; i++) {
      final start = -pi / 2 + i * sweep;
      fill.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, true, fill);
      canvas.drawArc(rect, start, sweep, true, line);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(start + sweep / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: textColors[i % textColors.length],
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.6);
      tp.paint(canvas, Offset(radius * 0.38, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, radius * 0.1, Paint()..color = hubColor);
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) => true;
}
