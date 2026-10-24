import 'package:flutter/material.dart';
import '../services/mqtt_manager.dart';

class MqttStatusBadge extends StatelessWidget {
  final MqttManager mqtt;

  const MqttStatusBadge({super.key, required this.mqtt});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (mqtt.status) {
      case MqttStatus.connected:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        text = 'Online';
        icon = Icons.cloud_done;
        break;
      case MqttStatus.connecting:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade800;
        text = 'Menghubungkan';
        icon = Icons.cloud_sync;
        break;
      case MqttStatus.disconnected:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
        text = 'Offline';
        icon = Icons.cloud_off;
        break;
      case MqttStatus.error:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        text = 'Gagal';
        icon = Icons.error_outline;
        break;
    }

    return InkWell(
      onTap: () {
        if (!mqtt.isConnected) {
          mqtt.connect();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terhubung ke: ${mqtt.server}:${mqtt.port}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
