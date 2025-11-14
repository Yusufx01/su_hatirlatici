import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/droplet.dart';
import '../../models/settings_data.dart';
import '../../painters/droplet_painter.dart';
import '../../painters/progress_ring_painter.dart';
import '../../utils/reminder_formatter.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback toggleTheme;

  const HomeScreen({
    required this.isDarkTheme,
    required this.toggleTheme,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const _waterKey = 'waterAmount';
  static const _dailyGoalKey = 'dailyGoal';
  static const _drinkAmountKey = 'drinkAmount';
  static const _reminderKey = 'reminderInterval';

  int waterAmount = 0;
  int dailyGoal = 2000;
  int reminderIntervalMinutes = 60;
  int drinkAmount = 200;

  Timer? _reminderTimer;
  SharedPreferences? _prefs;
  late AnimationController _waveController;
  late ConfettiController _confettiController;
  final List<Droplet> droplets = [];
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _generateDroplets();
    _initializeState();
  }

  Future<void> _initializeState() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      waterAmount = _prefs?.getInt(_waterKey) ?? waterAmount;
      dailyGoal = _prefs?.getInt(_dailyGoalKey) ?? dailyGoal;
      drinkAmount = _prefs?.getInt(_drinkAmountKey) ?? drinkAmount;
      reminderIntervalMinutes =
          _prefs?.getInt(_reminderKey) ?? reminderIntervalMinutes;
      _isReady = true;
    });
    _startReminder();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _reminderTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateDroplets() {
    final rand = Random();
    for (int i = 0; i < 50; i++) {
      droplets.add(
        Droplet(
          x: rand.nextDouble(),
          y: rand.nextDouble(),
          speed: 0.002 + rand.nextDouble() * 0.004,
          size: 2 + rand.nextDouble() * 3,
        ),
      );
    }
  }

  void _updateDroplets() {
    for (final droplet in droplets) {
      droplet.y += droplet.speed;
      if (droplet.y > 1.2) droplet.y = -0.2;
    }
  }

  void _startReminder() {
    _reminderTimer?.cancel();
    if (reminderIntervalMinutes <= 0) return;
    _reminderTimer = Timer.periodic(
      Duration(minutes: reminderIntervalMinutes),
      (_) => _showReminder(),
    );
  }

  void _showReminder() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Su içmeyi unutma! 💧 +$drinkAmount ml ile hedefe yaklaş.'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _persistState() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt(_waterKey, waterAmount);
    await prefs.setInt(_dailyGoalKey, dailyGoal);
    await prefs.setInt(_drinkAmountKey, drinkAmount);
    await prefs.setInt(_reminderKey, reminderIntervalMinutes);
  }

  void _drinkWater(int amount) {
    setState(() {
      waterAmount += amount;
      if (waterAmount >= dailyGoal) {
        _confettiController.play();
        waterAmount = min(waterAmount, dailyGoal);
      }
    });
    _persistState();
  }

  void _reduceWater(int amount) {
    setState(() {
      waterAmount = max(0, waterAmount - amount);
    });
    _persistState();
  }

  void _resetWater() {
    setState(() => waterAmount = 0);
    _persistState();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<SettingsData>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialGoal: dailyGoal,
          initialDrinkAmount: drinkAmount,
          initialReminderMinutes: reminderIntervalMinutes,
          isDarkTheme: widget.isDarkTheme,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      dailyGoal = result.goal;
      drinkAmount = result.drinkAmount;
      reminderIntervalMinutes = result.reminderMinutes;
      if (waterAmount > dailyGoal) waterAmount = dailyGoal;
    });
    _persistState();
    _startReminder();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final gradientColors = widget.isDarkTheme
        ? [
            const Color(0xFF0F2027),
            const Color(0xFF203A43),
            const Color(0xFF2C5364),
          ]
        : [
            const Color(0xFF74EBD5),
            const Color(0xFFACB6E5),
          ];
    final accentColor = widget.isDarkTheme
        ? const Color(0xFF3BC9DB)
        : const Color(0xFF1FA2FF);
    final progress = dailyGoal == 0 ? 0.0 : (waterAmount / dailyGoal).clamp(0.0, 1.0);
    final remaining = max(dailyGoal - waterAmount, 0);
    final reminderLabel = formatReminderInterval(reminderIntervalMinutes);
    final goalCompleted = progress >= 1.0;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Su Hatırlatıcı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _buildGlowCircle(accentColor, 300),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _buildGlowCircle(
              widget.isDarkTheme
                  ? const Color(0xFF1C7ED6)
                  : const Color(0xFF4DD0E1),
              340,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  _updateDroplets();
                  return CustomPaint(
                    painter: DropletPainter(droplets, widget.isDarkTheme),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProgressCard(
                      progress,
                      remaining,
                      accentColor,
                      goalCompleted,
                      reminderLabel,
                    ),
                    const SizedBox(height: 24),
                    _buildStatGrid(accentColor, remaining, progress),
                    const SizedBox(height: 24),
                    _buildActionButtons(accentColor),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.blue, Colors.lightBlue, Colors.white],
                  numberOfParticles: 50,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 24,
            child: GestureDetector(
              onTap: widget.toggleTheme,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: widget.isDarkTheme
                      ? Colors.white.withOpacity( 0.12)
                      : Colors.white.withOpacity( 0.85),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: widget.isDarkTheme ? 0.14 : 0.25,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: widget.isDarkTheme ? 0.45 : 0.22,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isDarkTheme
                      ? Icons.wb_sunny_rounded
                      : Icons.nights_stay_rounded,
                  color: accentColor,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    double progress,
    int remaining,
    Color accentColor,
    bool goalCompleted,
    String reminderLabel,
  ) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: widget.isDarkTheme
                    ? Colors.white.withOpacity( 0.07)
                    : Colors.white.withOpacity( 0.78),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: widget.isDarkTheme ? 0.08 : 0.18,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDarkTheme ? 0.48 : 0.18,
                    ),
                    blurRadius: 26,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: CustomPaint(
                      painter: ProgressRingPainter(
                        progress: progress,
                        shimmer: _waveController.value,
                        isDarkTheme: widget.isDarkTheme,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 40,
                              color: accentColor,
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                '$waterAmount ml',
                                key: ValueKey<int>(waterAmount),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isDarkTheme
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              goalCompleted
                                  ? 'Harika! Hedef tamamlandı 🎉'
                                  : 'Kalan $remaining ml',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: goalCompleted
                                    ? accentColor
                                    : (widget.isDarkTheme
                                        ? Colors.white70
                                        : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _infoChip(
                        Icons.flag_outlined,
                        'Günlük hedef',
                        '$dailyGoal ml',
                        accentColor,
                      ),
                      _infoChip(
                        Icons.local_drink_outlined,
                        'İçilen miktar',
                        '$waterAmount ml',
                        accentColor,
                      ),
                      _infoChip(
                        Icons.access_time,
                        'Hatırlatma',
                        reminderLabel,
                        accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatGrid(Color accentColor, int remaining, double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final itemWidth = isWide
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        final background = widget.isDarkTheme
          ? Colors.white.withOpacity( 0.08)
          : Colors.white.withOpacity( 0.78);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statTile(
              width: itemWidth,
              icon: Icons.flag_circle,
              label: 'Hedef',
              value: '$dailyGoal ml',
              accentColor: accentColor,
              background: background,
            ),
            _statTile(
              width: itemWidth,
              icon: Icons.water_drop_outlined,
              label: 'İçilen su',
              value: '$waterAmount ml',
              accentColor: accentColor,
              background: background,
            ),
            _statTile(
              width: itemWidth,
              icon: Icons.hourglass_bottom,
              label: 'Kalan miktar',
              value: '$remaining ml',
              accentColor: accentColor,
              background: background,
            ),
            _statTile(
              width: itemWidth,
              icon: Icons.percent_rounded,
              label: 'İlerleme',
              value: '${(progress * 100).clamp(0, 100).toStringAsFixed(1)} %',
              accentColor: accentColor,
              background: background,
            ),
          ],
        );
      },
    );
  }

  Widget _statTile({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required Color background,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity( widget.isDarkTheme ? 0.06 : 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( widget.isDarkTheme ? 0.45 : 0.16),
              blurRadius: 22,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity( 0.9),
                    accentColor.withOpacity( 0.6),
                  ],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkTheme
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color:
                          widget.isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color accentColor) {
    final removeColor = widget.isDarkTheme
        ? const Color(0xFFE57373)
        : const Color(0xFFE53935);
    final resetBackground = widget.isDarkTheme
      ? Colors.white.withOpacity( 0.05)
      : Colors.white;
    final resetForeground = widget.isDarkTheme
        ? Colors.white70
        : Colors.black87;

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildActionButton(
            label: 'Su İç (+$drinkAmount ml)',
            icon: Icons.water_drop_rounded,
            onPressed: () => _drinkWater(drinkAmount),
            background: accentColor,
            foreground: Colors.white,
          ),
          _buildActionButton(
            label: '-$drinkAmount ml',
            icon: Icons.remove_circle_outline,
            onPressed: () => _reduceWater(drinkAmount),
            background: removeColor,
            foreground: Colors.white,
          ),
          _buildActionButton(
            label: 'Sıfırla',
            icon: Icons.refresh_rounded,
            onPressed: _resetWater,
            background: resetBackground,
            foreground: resetForeground,
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color background,
    required Color foreground,
    bool outlined = false,
  }) {
    return SizedBox(
      width: 220,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label, textAlign: TextAlign.center),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: outlined ? 0 : 6,
          shadowColor: Colors.black.withOpacity( outlined ? 0 : 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: outlined
                ? BorderSide(color: foreground.withOpacity( 0.45), width: 1.4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color accentColor) {
    final background = widget.isDarkTheme
      ? Colors.white.withOpacity( 0.08)
      : Colors.white.withOpacity( 0.82);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: background,
        border: Border.all(
          color: Colors.white.withOpacity( widget.isDarkTheme ? 0.05 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDarkTheme ? Colors.white70 : Colors.black54,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isDarkTheme ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity( 0.38),
            color.withOpacity( 0.0),
          ],
        ),
      ),
    );
  }
}
