import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iot_remote/main.dart';
import 'package:iot_remote/services/mqtt_manager.dart';

void main() {
  testWidgets('IotRemoteApp UI smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const IotRemoteApp(autoConnect: false));
    await tester.pumpAndSettle();

    // Verify Page 1 (Relay) UI elements
    expect(find.text('Kontrol Relay'), findsWidgets);
    expect(find.text('Modul Relay 4 Channel'), findsOneWidget);
    expect(find.text('Master Saklar'), findsOneWidget);
    expect(find.text('Nyalakan Semua'), findsOneWidget);
    expect(find.text('Matikan Semua'), findsOneWidget);
    expect(find.text('Relay 1 (Lampu 1)'), findsOneWidget);
    expect(find.text('Relay 2 (Lampu 2)'), findsOneWidget);
    expect(find.text('Relay 3 (Kipas)'), findsOneWidget);
    expect(find.text('Relay 4 (Pompa)'), findsOneWidget);

    // Switch to Page 2 (Temperature)
    await tester.tap(find.text('Monitor Suhu'));
    await tester.pumpAndSettle();

    expect(find.text('Topic: iot/sensor/suhu'), findsOneWidget);
    expect(find.text('Riwayat Pembacaan Suhu'), findsOneWidget);
    expect(find.text('Menunggu Data Suhu...'), findsOneWidget);
  });

  test('MqttManager temperature parser test', () {
    final mqtt = MqttManager();

    // Test raw string parsing
    mqtt.simulateSendTemperature(27.5);
    expect(mqtt.currentTemperature?.value, 27.5);

    // Test simulation with humidity
    mqtt.simulateSendTemperature(31.2, humidity: 70.0);
    expect(mqtt.currentTemperature?.value, 31.2);
    expect(mqtt.currentTemperature?.humidity, 70.0);

    // Test 4 relays initialized
    expect(mqtt.relays.length, 4);
    expect(mqtt.relays[0].id, 1);
    expect(mqtt.relays[3].id, 4);
  });
}
