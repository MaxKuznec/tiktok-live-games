import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------- События ----------

enum LiveEventType { like, gift, comment }

class LiveEvent {
  LiveEvent(
    this.type, {
    this.user = 'Зритель',
    this.text = '',
    this.amount = 1,
  });

  final LiveEventType type;
  final String user;
  final String text;
  final int amount;

  IconData get icon {
    switch (type) {
      case LiveEventType.like:
        return Icons.favorite;
      case LiveEventType.gift:
        return Icons.card_giftcard;
      case LiveEventType.comment:
        return Icons.chat_bubble;
    }
  }

  String get describe {
    switch (type) {
      case LiveEventType.like:
        return '$user: лайк';
      case LiveEventType.gift:
        return '$user: подарок ×$amount';
      case LiveEventType.comment:
        return '$user: $text';
    }
  }
}

class EventBus {
  EventBus._();
  static final EventBus instance = EventBus._();

  final StreamController<LiveEvent> _controller =
      StreamController<LiveEvent>.broadcast();
  final List<LiveEvent> log = [];

  Stream<LiveEvent> get stream => _controller.stream;

  void emit(LiveEvent event) {
    log.insert(0, event);
    if (log.length > 30) log.removeLast();
    _controller.add(event);
  }
}

// ---------- Приложение ----------

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

  void _openSimulator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const SimulatorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'Симулятор событий',
            onPressed: _openSimulator,
          ),
        ],
      ),
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

// ---------- Симулятор событий ----------

class SimulatorSheet extends StatelessWidget {
  const SimulatorSheet({super.key});

  static final Random _rnd = Random();
  static const List<String> _names = [
    'Аня',
    'Макс',
    'Лена',
    'Игорь',
    'Соня',
    'Артём',
  ];

  void _emit(LiveEventType type, {String text = '', int amount = 1}) {
    final name = _names[_rnd.nextInt(_names.length)];
    EventBus.instance.emit(
      LiveEvent(type, user: name, text: text, amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Симулятор событий', style: t.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Так будут приходить лайки, подарки и комментарии из эфира.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _emit(LiveEventType.like),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Лайк'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _emit(LiveEventType.gift),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Подарок'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _emit(LiveEventType.gift, amount: 5),
                  icon: const Icon(Icons.redeem),
                  label: const Text('Большой подарок ×5'),
                ),
                OutlinedButton(
                  onPressed: () => _emit(LiveEventType.comment, text: 'A'),
                  child: const Text('Комментарий A'),
                ),
                OutlinedButton(
                  onPressed: () => _emit(LiveEventType.comment, text: 'B'),
                  child: const Text('Комментарий B'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Последние события', style: t.titleSmall),
            SizedBox(
              height: 220,
              child: StreamBuilder<LiveEvent>(
                stream: EventBus.instance.stream,
                builder: (context, snapshot) {
                  final log = EventBus.instance.log;
                  if (log.isEmpty) {
                    return const Center(child: Text('Пока пусто'));
                  }
                  return ListView.builder(
                    itemCount: log.length,
                    itemBuilder: (context, i) {
                      final e = log[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(e.icon),
                        title: Text(e.describe),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Кликер ----------

class ClickerPage extends StatefulWidget {
  const ClickerPage({super.key});

  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage> {
  int _count = 0;
  StreamSubscription<LiveEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = EventBus.instance.stream.listen((e) {
      if (e.type == LiveEventType.like) {
        setState(() => _count += e.amount);
      } else if (e.type == LiveEventType.gift) {
        setState(() => _count += 10 * e.amount);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
                onPressed: () => EventBus.instance
                    .emit(LiveEvent(LiveEventType.like, user: 'Ты')),
                child: const Text('Лайк +1'),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: () => EventBus.instance
                    .emit(LiveEvent(LiveEventType.gift, user: 'Ты')),
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

// ---------- Голосование ----------

class VoteyPage extends StatefulWidget {
  const VoteyPage({super.key});

  @override
  State<VoteyPage> createState() => _VoteyPageState();
}

class _VoteyPageState extends State<VoteyPage> {
  int _a = 0;
  int _b = 0;
  StreamSubscription<LiveEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = EventBus.instance.stream.listen((e) {
      if (e.type != LiveEventType.comment) return;
      final text = e.text.trim().toUpperCase();
      if (text == 'A' || text == 'А' || text == '1') {
        setState(() => _a++);
      } else if (text == 'B' || text == 'В' || text == '2') {
        setState(() => _b++);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _vote(String letter) {
    EventBus.instance.emit(
      LiveEvent(LiveEventType.comment, user: 'Ты', text: letter),
    );
  }

  Widget _option(String name, int votes, double share) {
    return Card(
      child: InkWell(
        onTap: () => _vote(name),
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
          _option('A', _a, pa),
          const SizedBox(height: 16),
          _option('B', _b, pb),
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

// ---------- Колесо ----------

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
  String _result = 'Нажми «Крутить» или пришли подарок';
  StreamSubscription<LiveEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = EventBus.instance.stream.listen((e) {
      if (e.type == LiveEventType.gift) _spin();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _spin() {
    if (_spinning || !mounted) return;
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
