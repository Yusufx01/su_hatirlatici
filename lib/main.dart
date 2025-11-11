import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const WaterReminderApp());
}

// Ana uygulama
class WaterReminderApp extends StatefulWidget {
  const WaterReminderApp({super.key});

  @override
  State<WaterReminderApp> createState() => _WaterReminderAppState();
}

class _WaterReminderAppState extends State<WaterReminderApp> {
  bool isDarkTheme = false;

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Su Hatırlatıcı',
      theme: isDarkTheme
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.grey[900])
          : ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.grey[100]),
      home: HomeScreen(
        isDarkTheme: isDarkTheme,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

// Su damlası modeli
class Droplet {
  double x, y, speed, size;
  Droplet({required this.x, required this.y, required this.speed, required this.size});
}

// Ana ekran
class HomeScreen extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback toggleTheme;

  const HomeScreen({required this.isDarkTheme, required this.toggleTheme, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int waterAmount = 0;
  int dailyGoal = 2000;
  int reminderIntervalMinutes = 60;
  int drinkAmount = 200;

  Timer? _reminderTimer;
  late AnimationController _waveController;
  late ConfettiController _confettiController;
  List<Droplet> droplets = [];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _generateDroplets();
    _startReminder();
  }

  void _generateDroplets() {
    final rand = Random();
    for (int i = 0; i < 50; i++) {
      droplets.add(Droplet(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        speed: 0.002 + rand.nextDouble() * 0.004,
        size: 2 + rand.nextDouble() * 3,
      ));
    }
  }

  void _updateDroplets() {
    for (var d in droplets) {
      d.y += d.speed;
      if (d.y > 1.2) d.y = -0.2;
    }
  }

  void _startReminder() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(Duration(minutes: reminderIntervalMinutes), (timer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Su içmeyi unutma! 💧"),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });
  }

  void _drinkWater(int amount) {
    setState(() {
      waterAmount += amount;
      if (waterAmount >= dailyGoal) _confettiController.play();
      if (waterAmount > dailyGoal) waterAmount = dailyGoal;
    });
  }

  void _reduceWater(int amount) {
    setState(() {
      waterAmount -= amount;
      if (waterAmount < 0) waterAmount = 0;
    });
  }

  void _resetWater() {
    setState(() {
      waterAmount = 0;
    });
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentGoal: dailyGoal,
          currentDrinkAmount: drinkAmount,
          onSettingsSaved: (goal, drink) {
            setState(() {
              dailyGoal = goal;
              drinkAmount = drink;
              if (waterAmount > dailyGoal) waterAmount = dailyGoal;
            });
          },
          isDarkTheme: widget.isDarkTheme,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _reminderTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = widget.isDarkTheme ? Colors.blueGrey : Colors.blue;
    Color reduceButtonColor = widget.isDarkTheme ? Colors.red.shade400 : Colors.red;
    Color resetButtonColor = widget.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade400;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Su Hatırlatıcı"),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/indir(2).png', // Sağ üst ayarlar butonu
              width: 28,
              height: 28,
            ),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              _updateDroplets();
              return CustomPaint(
                size: Size.infinite,
                painter: DropletPainter(droplets, widget.isDarkTheme),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 4),
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.isDarkTheme
                          ? [Colors.grey[900]!, Colors.grey[800]!]
                          : [Colors.grey[200]!, Colors.grey[100]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: WavePainter(
                            animationValue: _waveController.value,
                            fillLevel: waterAmount / dailyGoal,
                            isDarkTheme: widget.isDarkTheme,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "$waterAmount / $dailyGoal ml",
                  style: TextStyle(
                    fontSize: 20,
                    color: widget.isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _drinkWater(drinkAmount),
                      style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                      child: Text("Su İç (+$drinkAmount ml)"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _reduceWater(drinkAmount),
                      style: ElevatedButton.styleFrom(backgroundColor: reduceButtonColor),
                      child: Text("-$drinkAmount ml"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _resetWater,
                      style: ElevatedButton.styleFrom(backgroundColor: resetButtonColor),
                      child: const Text("Sıfırla"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.blue, Colors.lightBlue, Colors.white],
              numberOfParticles: 50,
            ),
          ),
          // Sağ alttaki tema değiştirme butonu
          Positioned(
            bottom: 16,
            right: 16,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.toggleTheme,
                child: Image.asset(
                  widget.isDarkTheme
                      ? 'assets/icons/indir.png'       // Karanlık tema
                      : 'assets/icons/indir(1).png',  // Açık tema
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ayarlar sayfası
class SettingsScreen extends StatefulWidget {
  final int currentGoal;
  final int currentDrinkAmount;
  final Function(int, int) onSettingsSaved;
  final bool isDarkTheme;

  const SettingsScreen({
    required this.currentGoal,
    required this.currentDrinkAmount,
    required this.onSettingsSaved,
    required this.isDarkTheme,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _goalController;
  late TextEditingController _drinkController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.currentGoal.toString());
    _drinkController = TextEditingController(text: widget.currentDrinkAmount.toString());
  }

  @override
  void dispose() {
    _goalController.dispose();
    _drinkController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final goal = int.tryParse(_goalController.text) ?? widget.currentGoal;
    final drink = int.tryParse(_drinkController.text) ?? widget.currentDrinkAmount;

    widget.onSettingsSaved(goal, drink);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = widget.isDarkTheme ? Colors.white : Colors.black;
    Color labelColor = widget.isDarkTheme ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Günlük hedef (ml)",
                labelStyle: TextStyle(color: labelColor),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _drinkController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Su ekleme miktarı (ml)",
                labelStyle: TextStyle(color: labelColor),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("Ayarları Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}

// Dalga painter
class WavePainter extends CustomPainter {
  final double animationValue;
  final double fillLevel;
  final bool isDarkTheme;

  WavePainter({
    required this.animationValue,
    required this.fillLevel,
    required this.isDarkTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkTheme ? Colors.blueGrey.shade800 : Colors.blue.shade300
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Path path = Path();
    double baseHeight = size.height * (1 - fillLevel);
    double waveHeight = 15;

    path.moveTo(0, baseHeight);
    for (double x = 0; x <= size.width; x++) {
      double y = waveHeight * sin(2 * pi * (x / size.width) + animationValue * 2 * pi) + baseHeight;
      path.lineTo(x, y);
    }

    Paint foamPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (double x = 0; x <= size.width; x += 5) {
      double y = waveHeight * sin(2 * pi * (x / size.width) + animationValue * 2 * pi) + baseHeight;
      canvas.drawCircle(Offset(x, y), 1.5, foamPaint);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

// Arka plan damlaları
class DropletPainter extends CustomPainter {
  List<Droplet> droplets;
  bool isDark;

  DropletPainter(this.droplets, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.blueAccent.shade100;

    for (var d in droplets) {
      canvas.drawCircle(Offset(d.x * size.width, d.y * size.height), d.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DropletPainter oldDelegate) => true;
}
