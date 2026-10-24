import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mqtt_manager.dart';

class SettingsPage extends StatefulWidget {
  final MqttManager mqtt;

  const SettingsPage({super.key, required this.mqtt});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _serverController;
  late TextEditingController _portController;
  late TextEditingController _clientIdController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _relayPrefixController;
  late TextEditingController _tempTopicController;
  late RelayPayloadType _payloadType;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: widget.mqtt.server);
    _portController = TextEditingController(text: widget.mqtt.port.toString());
    _clientIdController = TextEditingController(text: widget.mqtt.clientId);
    _usernameController = TextEditingController(text: widget.mqtt.username);
    _passwordController = TextEditingController(text: widget.mqtt.password);
    _relayPrefixController = TextEditingController(text: widget.mqtt.relayTopicPrefix);
    _tempTopicController = TextEditingController(text: widget.mqtt.temperatureTopic);
    _payloadType = widget.mqtt.payloadType;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _relayPrefixController.dispose();
    _tempTopicController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final newServer = _serverController.text.trim();
    final newPort = int.tryParse(_portController.text.trim()) ?? 1883;
    final newClientId = _clientIdController.text.trim();
    final newUsername = _usernameController.text.trim();
    final newPassword = _passwordController.text.trim();
    final newRelayPrefix = _relayPrefixController.text.trim();
    final newTempTopic = _tempTopicController.text.trim();

    widget.mqtt.server = newServer;
    widget.mqtt.port = newPort;
    widget.mqtt.clientId = newClientId.isNotEmpty ? newClientId : widget.mqtt.clientId;
    widget.mqtt.username = newUsername;
    widget.mqtt.password = newPassword;
    widget.mqtt.payloadType = _payloadType;

    if (newRelayPrefix != widget.mqtt.relayTopicPrefix) {
      widget.mqtt.updateRelayTopicPrefix(newRelayPrefix);
    }

    if (newTempTopic != widget.mqtt.temperatureTopic) {
      widget.mqtt.resubscribeTemperatureTopic(newTempTopic);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan berhasil disimpan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEsp32CodeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contoh Kode ESP32 / Arduino',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Berikut template kode ESP32 menggunakan PubSubClient untuk 4 relay dan sensor DHT22/DHT11:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SelectableText(
                        '''// Template ESP32 IoT Remote (MQTT)
#include <WiFi.h>
#include <PubSubClient.h>
#include "DHT.h"

const char* ssid = "NAMA_WIFI";
const char* password = "PASSWORD_WIFI";
const char* mqtt_server = "broker.emqx.io";

WiFiClient espClient;
PubSubClient client(espClient);

// Pin Relay (sesuaikan dengan board ESP32 Anda)
const int relayPins[4] = {26, 27, 14, 12};

#define DHTPIN 4
#define DHTTYPE DHT11 // atau DHT22
DHT dht(DHTPIN, DHTTYPE);

unsigned long lastTempSend = 0;

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  // Kontrol 4 Relay: iot/relay/1 .. 4
  for (int i = 0; i < 4; i++) {
    String expectedTopic = "iot/relay/" + String(i + 1);
    if (String(topic) == expectedTopic) {
      if (message == "1" || message == "ON") {
        digitalWrite(relayPins[i], HIGH);
      } else {
        digitalWrite(relayPins[i], LOW);
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  for (int i = 0; i < 4; i++) {
    pinMode(relayPins[i], OUTPUT);
    digitalWrite(relayPins[i], LOW);
  }
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) delay(500);

  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    while (!client.connected()) {
      if (client.connect("ESP32_IoT_Client")) {
        // Subscribe ke 4 Relay
        for (int i = 1; i <= 4; i++) {
          client.subscribe(("iot/relay/" + String(i)).c_str());
        }
      } else {
        delay(3000);
      }
    }
  }
  client.loop();

  // Kirim data suhu setiap 5 detik
  if (millis() - lastTempSend > 5000) {
    lastTempSend = millis();
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    if (!isnan(t)) {
      String json = "{\\"suhu\\":" + String(t, 1) + ",\\"humidity\\":" + String(h, 1) + "}";
      client.publish("iot/sensor/suhu", json.c_str());
    }
  }
}''',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text: '''// ESP32 Arduino MQTT code
#include <WiFi.h>
#include <PubSubClient.h>
// ...
''',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode disalin ke clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Salin Kode ESP32'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.mqtt.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan MQTT'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Broker MQTT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    decoration: const InputDecoration(
                      labelText: 'Server / Broker Host',
                      hintText: 'e.g. broker.emqx.io atau 192.168.1.100',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '1883',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _clientIdController,
                          decoration: const InputDecoration(
                            labelText: 'Client ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.fingerprint),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (Opsional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (Opsional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Topic Configuration Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konfigurasi Topik MQTT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _relayPrefixController,
                    decoration: const InputDecoration(
                      labelText: 'Prefix Topik Relay',
                      hintText: 'iot/relay/',
                      helperText: 'Akan menghasilkan: iot/relay/1, 2, 3, 4',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.toggle_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tempTopicController,
                    decoration: const InputDecoration(
                      labelText: 'Topik Sensor Suhu',
                      hintText: 'iot/sensor/suhu',
                      helperText: 'Topik yang disubscribe untuk menerima data suhu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thermostat),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Format Payload Relay:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<RelayPayloadType>(
                      segments: const [
                        ButtonSegment(
                          value: RelayPayloadType.binaryNumeric,
                          label: Text('"1" / "0"'),
                          icon: Icon(Icons.pin),
                        ),
                        ButtonSegment(
                          value: RelayPayloadType.textOnOff,
                          label: Text('"ON" / "OFF"'),
                          icon: Icon(Icons.text_fields),
                        ),
                      ],
                      selected: {_payloadType},
                      onSelectionChanged: (Set<RelayPayloadType> newSelection) {
                        setState(() {
                          _payloadType = newSelection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _saveSettings();
                    if (!isConnected) {
                      widget.mqtt.connect();
                    } else {
                      widget.mqtt.disconnect();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        widget.mqtt.connect();
                      });
                    }
                  },
                  icon: Icon(isConnected ? Icons.refresh : Icons.cloud_done),
                  label: Text(isConnected ? 'Terapkan & Reconnect' : 'Simpan & Hubungkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (isConnected) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => widget.mqtt.disconnect(),
                  icon: const Icon(Icons.power_off, color: Colors.red),
                  label: const Text('Putus', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Guide card
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.teal.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.code, color: Colors.teal),
              title: const Text(
                'Lihat Contoh Kode Arduino / ESP32',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text('Siap pakai untuk 4 Modul Relay & DHT Sensor'),
              trailing: const Icon(Icons.chevron_right, color: Colors.teal),
              onTap: _showEsp32CodeModal,
            ),
          ),
        ],
      ),
    );
  }
}
