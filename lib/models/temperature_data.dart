class TemperatureData {
  final double value;
  final double? humidity;
  final DateTime timestamp;
  final String rawPayload;

  TemperatureData({
    required this.value,
    this.humidity,
    required this.timestamp,
    required this.rawPayload,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
