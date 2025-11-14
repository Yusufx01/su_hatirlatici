String formatReminderInterval(int minutes) {
  if (minutes >= 60 && minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? 'Her 1 saatte' : 'Her $hours saatte';
  }
  if (minutes > 60) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return 'Her $hours saatte ${remainder.toString().padLeft(2, '0')} dk';
  }
  return 'Her $minutes dakikada';
}
