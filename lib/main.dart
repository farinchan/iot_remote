import 'package:flutter/material.dart';
import 'services/mqtt_manager.dart';
import 'pages/relay_page.dart';
import 'pages/temperature_page.dart';
import 'pages/settings_page.dart';
import 'widgets/mqtt_status_badge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IotRemoteApp());
}

class IotRemoteApp extends StatelessWidget {
  final bool autoConnect;

  const IotRemoteApp({super.key, this.autoConnect = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Remote MQTT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: MainNavigationScreen(autoConnect: autoConnect),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool autoConnect;

  const MainNavigationScreen({super.key, this.autoConnect = true});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final MqttManager _mqtt = MqttManager();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-connect to MQTT on startup if enabled
    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mqtt.connect();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mqtt,
      builder: (context, _) {
        final pages = [
          RelayPage(mqtt: _mqtt),
          TemperaturePage(mqtt: _mqtt),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  _currentIndex == 0 ? Icons.toggle_on : Icons.thermostat,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentIndex == 0 ? 'Kontrol Relay' : 'Monitor Suhu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MqttStatusBadge(mqtt: _mqtt),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Pengaturan MQTT',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(mqtt: _mqtt),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.power_settings_new_outlined),
                selectedIcon: Icon(Icons.power_settings_new, color: Colors.teal),
                label: 'Kontrol Relay',
              ),
              NavigationDestination(
                icon: Icon(Icons.device_thermostat_outlined),
                selectedIcon: Icon(Icons.device_thermostat, color: Colors.teal),
                label: 'Monitor Suhu',
              ),
            ],
          ),
        );
      },
    );
  }
}
