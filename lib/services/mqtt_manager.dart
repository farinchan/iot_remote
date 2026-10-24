import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/relay_item.dart';
import '../models/temperature_data.dart';

enum MqttStatus {
  disconnected,
  connecting,
  connected,
  error,
}

enum RelayPayloadType {
  binaryNumeric, // "1" / "0"
  textOnOff, // "ON" / "OFF"
}

class MqttManager extends ChangeNotifier {
  static final MqttManager _instance = MqttManager._internal();
  factory MqttManager() => _instance;

  MqttManager._internal() {
    _initRelays();
  }

  MqttServerClient? _client;
  MqttStatus _status = MqttStatus.disconnected;
  String _statusMessage = 'Belum terhubung';

  // MQTT Connection Settings
  String server = 'broker.emqx.io';
  int port = 1883;
  late String clientId = 'flutter_iot_${Random().nextInt(999999)}';
  String username = '';
  String password = '';

  // Topics
  String relayTopicPrefix = 'iot/relay/';
  String temperatureTopic = 'iot/sensor/suhu';
  RelayPayloadType payloadType = RelayPayloadType.binaryNumeric;

  // 4 Modul Relay
  late List<RelayItem> relays;

  // Temperature State
  TemperatureData? currentTemperature;
  final List<TemperatureData> temperatureHistory = [];

  // Logs
  final List<String> logs = [];

  // Getters
  MqttStatus get status => _status;
  bool get isConnected => _status == MqttStatus.connected;
  String get statusMessage => _statusMessage;

  void _initRelays() {
    relays = [
      RelayItem(id: 1, name: 'Relay 1 (Lampu 1)', topic: '${relayTopicPrefix}1'),
      RelayItem(id: 2, name: 'Relay 2 (Lampu 2)', topic: '${relayTopicPrefix}2'),
      RelayItem(id: 3, name: 'Relay 3 (Kipas)', topic: '${relayTopicPrefix}3'),
      RelayItem(id: 4, name: 'Relay 4 (Pompa)', topic: '${relayTopicPrefix}4'),
    ];
  }

  void updateRelayTopicPrefix(String prefix) {
    relayTopicPrefix = prefix;
    for (int i = 0; i < relays.length; i++) {
      relays[i].topic = '$relayTopicPrefix${i + 1}';
    }
    notifyListeners();
  }

  void updateRelayName(int index, String newName) {
    if (index >= 0 && index < relays.length) {
      relays[index].name = newName;
      notifyListeners();
    }
  }

  void addLog(String message) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    logs.insert(0, '[$timeStr] $message');
    if (logs.length > 100) {
      logs.removeLast();
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (_status == MqttStatus.connecting || _status == MqttStatus.connected) {
      return;
    }

    _status = MqttStatus.connecting;
    _statusMessage = 'Menghubungkan ke $server:$port...';
    addLog('Menghubungkan ke $server:$port');
    notifyListeners();

    try {
      _client = MqttServerClient.withPort(server, clientId, port);
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 30;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.autoReconnect = true;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      if (username.isNotEmpty) {
        connMessage.authenticateAs(username, password);
      }

      _client!.connectionMessage = connMessage;

      final result = await _client!.connect();

      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _status = MqttStatus.connected;
        _statusMessage = 'Terhubung ke $server';
        addLog('Sukses terhubung ke broker MQTT');

        // Subscribe to temperature topic
        _subscribeToTemperature();

        // Listen for incoming messages
        _client!.updates?.listen(_onMessageReceived);
      } else {
        _status = MqttStatus.error;
        _statusMessage = 'Gagal terhubung: $result';
        addLog('Gagal terhubung: $result');
        _client?.disconnect();
      }
    } catch (e) {
      _status = MqttStatus.error;
      _statusMessage = 'Error: $e';
      addLog('Error koneksi: $e');
      _client?.disconnect();
    }

    notifyListeners();
  }

  void _subscribeToTemperature() {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.subscribe(temperatureTopic, MqttQos.atLeastOnce);
      addLog('Subscribed ke topik: $temperatureTopic');
    }
  }

  void resubscribeTemperatureTopic(String newTopic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      if (temperatureTopic.isNotEmpty) {
        _client!.unsubscribe(temperatureTopic);
      }
      temperatureTopic = newTopic;
      _subscribeToTemperature();
      notifyListeners();
    } else {
      temperatureTopic = newTopic;
      notifyListeners();
    }
  }

  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _status = MqttStatus.disconnected;
      _statusMessage = 'Terputus dari broker';
      addLog('Terputus dari broker');
      notifyListeners();
    }
  }

  void _onConnected() {
    _status = MqttStatus.connected;
    _statusMessage = 'Terhubung ke $server';
    notifyListeners();
  }

  void _onDisconnected() {
    _status = MqttStatus.disconnected;
    _statusMessage = 'Koneksi terputus';
    addLog('Koneksi ke broker terputus');
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    addLog('Topic dikonfirmasi: $topic');
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final pubMessage = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(pubMessage.payload.message);
      final topic = message.topic;

      addLog('Pesan diterima [$topic]: $payload');

      if (topic == temperatureTopic) {
        _parseTemperaturePayload(payload);
      }
    }
  }

  void _parseTemperaturePayload(String payload) {
    try {
      double? tempValue;
      double? humValue;

      final trimmed = payload.trim();

      // Check if it's JSON
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        
        // Flexible key lookups for temperature
        final t = decoded['temp'] ?? decoded['temperature'] ?? decoded['suhu'] ?? decoded['val'] ?? decoded['value'];
        if (t != null) {
          tempValue = double.tryParse(t.toString());
        }

        // Flexible key lookups for humidity
        final h = decoded['humidity'] ?? decoded['hum'] ?? decoded['kelembapan'];
        if (h != null) {
          humValue = double.tryParse(h.toString());
        }
      } else {
        // Raw string number, e.g. "28.5" or "28.5 C"
        final cleanString = trimmed.replaceAll(RegExp(r'[^\d.-]'), '');
        tempValue = double.tryParse(cleanString);
      }

      if (tempValue != null) {
        final data = TemperatureData(
          value: tempValue,
          humidity: humValue,
          timestamp: DateTime.now(),
          rawPayload: payload,
        );
        currentTemperature = data;
        temperatureHistory.insert(0, data);
        if (temperatureHistory.length > 50) {
          temperatureHistory.removeLast();
        }
        notifyListeners();
      }
    } catch (e) {
      addLog('Gagal parsing data suhu: $e');
    }
  }

  // Publish message to topic
  void publish(String topic, String message, {bool retain = false}) {
    if (!isConnected || _client == null) {
      addLog('Gagal publish: belum terhubung ke broker');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: retain);
    addLog('Publish [$topic]: $message');
  }

  // Toggle relay
  void toggleRelay(int index) {
    if (index < 0 || index >= relays.length) return;

    final relay = relays[index];
    relay.isOn = !relay.isOn;

    final payload = _getPayloadForState(relay.isOn);
    publish(relay.topic, payload, retain: true);

    notifyListeners();
  }

  // Set relay explicitly
  void setRelay(int index, bool state) {
    if (index < 0 || index >= relays.length) return;

    final relay = relays[index];
    relay.isOn = state;

    final payload = _getPayloadForState(state);
    publish(relay.topic, payload, retain: true);

    notifyListeners();
  }

  // Turn all relays ON or OFF
  void setAllRelays(bool state) {
    for (int i = 0; i < relays.length; i++) {
      setRelay(i, state);
    }
  }

  String _getPayloadForState(bool state) {
    if (payloadType == RelayPayloadType.binaryNumeric) {
      return state ? '1' : '0';
    } else {
      return state ? 'ON' : 'OFF';
    }
  }

  // Test Simulation helper: simulate publishing temperature data
  void simulateSendTemperature(double temp, {double? humidity}) {
    String payload;
    if (humidity != null) {
      payload = jsonEncode({'suhu': temp, 'humidity': humidity});
    } else {
      payload = temp.toStringAsFixed(1);
    }

    if (isConnected) {
      publish(temperatureTopic, payload);
    } else {
      // Local simulation if not connected
      _parseTemperaturePayload(payload);
      addLog('Simulasi lokal data suhu: $payload');
    }
  }
}
