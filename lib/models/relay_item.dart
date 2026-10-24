class RelayItem {
  final int id;
  String name;
  bool isOn;
  String topic;

  RelayItem({
    required this.id,
    required this.name,
    this.isOn = false,
    required this.topic,
  });
}
