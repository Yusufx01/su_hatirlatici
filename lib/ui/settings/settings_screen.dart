import 'package:flutter/material.dart';

import '../../models/settings_data.dart';
import '../../utils/reminder_formatter.dart';

class SettingsScreen extends StatefulWidget {
  final int initialGoal;
  final int initialDrinkAmount;
  final int initialReminderMinutes;
  final bool isDarkTheme;

  const SettingsScreen({
    required this.initialGoal,
    required this.initialDrinkAmount,
    required this.initialReminderMinutes,
    required this.isDarkTheme,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _goal;
  late double _drink;
  late double _reminder;

  @override
  void initState() {
    super.initState();
    _goal = widget.initialGoal.toDouble().clamp(1000, 5000);
    _drink = widget.initialDrinkAmount.toDouble().clamp(100, 600);
    _reminder = widget.initialReminderMinutes.toDouble().clamp(15, 180);
  }

  void _saveSettings() {
    Navigator.pop(
      context,
      SettingsData(
        goal: _goal.round(),
        drinkAmount: _drink.round(),
        reminderMinutes: _reminder.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captionColor = widget.isDarkTheme ? Colors.white60 : Colors.black54;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsSliderCard(
                title: 'Günlük hedef',
                description: 'Gün boyunca ulaşmak istediğiniz toplam su miktarı.',
                valueLabel: '${_goal.round()} ml',
                min: 1000,
                max: 5000,
                divisions: 40,
                value: _goal,
                footer: '1000 - 5000 ml',
                onChanged: (value) => setState(() => _goal = value),
                isDarkTheme: widget.isDarkTheme,
              ),
              const SizedBox(height: 20),
              _SettingsSliderCard(
                title: 'İçme miktarı',
                description: 'Tek seferde eklemek istediğiniz su miktarı.',
                valueLabel: '${_drink.round()} ml',
                min: 100,
                max: 600,
                divisions: 25,
                value: _drink,
                footer: '100 - 600 ml',
                onChanged: (value) => setState(() => _drink = value),
                isDarkTheme: widget.isDarkTheme,
              ),
              const SizedBox(height: 20),
              _SettingsSliderCard(
                title: 'Hatırlatma sıklığı',
                description:
                    'Uygulamanın sizi hangi periyotlarda uyarmasını istersiniz? Daha kısa aralıklar daha sık hatırlatır.',
                valueLabel: formatReminderInterval(_reminder.round()),
                min: 15,
                max: 180,
                divisions: 11,
                value: _reminder,
                footer: '15 - 180 dk',
                onChanged: (value) => setState(() => _reminder = value),
                isDarkTheme: widget.isDarkTheme,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Ayarları Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Vazgeç',
                  style: TextStyle(
                    color: captionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSliderCard extends StatelessWidget {
  final String title;
  final String description;
  final String valueLabel;
  final String footer;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isDarkTheme;

  const _SettingsSliderCard({
    required this.title,
    required this.description,
    required this.valueLabel,
    required this.footer,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkTheme
      ? Colors.white.withOpacity( 0.07)
      : Colors.white.withOpacity( 0.92);
    final borderColor =
      Colors.white.withOpacity( isDarkTheme ? 0.07 : 0.16);
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final subtitleColor = isDarkTheme ? Colors.white60 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cardColor,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( isDarkTheme ? 0.45 : 0.16),
            blurRadius: 20,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                footer,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity( 0.2),
              thumbColor: Theme.of(context).colorScheme.primary,
                overlayColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity( 0.15),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
