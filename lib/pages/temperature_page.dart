import 'package:flutter/material.dart';
import '../services/mqtt_manager.dart';

class TemperaturePage extends StatelessWidget {
  final MqttManager mqtt;

  const TemperaturePage({super.key, required this.mqtt});

  Color _getTempColor(double temp) {
    if (temp < 20.0) return Colors.blue.shade600;
    if (temp <= 29.0) return Colors.teal.shade600;
    if (temp <= 34.0) return Colors.amber.shade800;
    return Colors.red.shade600;
  }

  String _getTempStatusText(double temp) {
    if (temp < 20.0) return 'Dingin / Sejuk';
    if (temp <= 29.0) return 'Suhu Nyaman / Normal';
    if (temp <= 34.0) return 'Cukup Hangat';
    return 'Peringatan: Panas!';
  }

  IconData _getTempIcon(double temp) {
    if (temp < 20.0) return Icons.ac_unit;
    if (temp <= 29.0) return Icons.sentiment_satisfied_alt;
    if (temp <= 34.0) return Icons.wb_sunny_outlined;
    return Icons.whatshot;
  }

  void _showSimulationDialog(BuildContext context) {
    final tempController = TextEditingController(text: '28.5');
    final humController = TextEditingController(text: '65.0');
    bool includeHum = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.teal),
              SizedBox(width: 8),
              Text('Simulasi Sensor'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kirim data simulasi ke topik MQTT untuk menguji tampilan aplikasi:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Suhu (°C)',
                  border: OutlineInputBorder(),
                  suffixText: '°C',
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sertakan Kelembapan', style: TextStyle(fontSize: 14)),
                value: includeHum,
                onChanged: (val) => setState(() => includeHum = val ?? false),
              ),
              if (includeHum)
                TextField(
                  controller: humController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Kelembapan (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('22°C (Sejuk)'),
                    onPressed: () => setState(() => tempController.text = '22.0'),
                  ),
                  ActionChip(
                    label: const Text('28°C (Normal)'),
                    onPressed: () => setState(() => tempController.text = '28.0'),
                  ),
                  ActionChip(
                    label: const Text('36°C (Panas)'),
                    onPressed: () => setState(() => tempController.text = '36.5'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final temp = double.tryParse(tempController.text.trim()) ?? 28.0;
                final hum = includeHum ? double.tryParse(humController.text.trim()) : null;
                mqtt.simulateSendTemperature(temp, humidity: hum);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Simulasi suhu $temp°C dikirim ke ${mqtt.temperatureTopic}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Kirim Simulasi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = mqtt.currentTemperature;
    final isConnected = mqtt.isConnected;

    final tempColor = current != null ? _getTempColor(current.value) : Colors.grey;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Offline Banner
          if (!isConnected)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MQTT Offline. Hubungkan untuk menerima data real-time.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => mqtt.connect(),
                      child: const Text('HUBUNGKAN'),
                    ),
                  ],
                ),
              ),
            ),

          // Topic Info & Action Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sensors,
                            size: 18,
                            color: isConnected ? Colors.teal : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Topic: ${mqtt.temperatureTopic}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _showSimulationDialog(context),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Simulasi'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Temperature Gauge Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: current != null
                        ? tempColor.withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: current != null
                          ? [
                              tempColor.withValues(alpha: 0.08),
                              tempColor.withValues(alpha: 0.02),
                            ]
                          : [
                              theme.colorScheme.surface,
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            ],
                    ),
                  ),
                  child: current == null
                      ? Column(
                          children: [
                            const SizedBox(height: 20),
                            Icon(
                              Icons.device_thermostat,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Menunggu Data Suhu...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Kirim data suhu dari ESP32/Arduino ke topik "${mqtt.temperatureTopic}" atau klik tombol "Simulasi".',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getTempIcon(current.value),
                                      color: tempColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getTempStatusText(current.value),
                                      style: TextStyle(
                                        color: tempColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time, size: 12, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        current.formattedTime,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Large Temperature Value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.value.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 68,
                                    fontWeight: FontWeight.w900,
                                    color: tempColor,
                                    letterSpacing: -2,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '°C',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: tempColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Visual Temperature Bar Indicator (0°C to 50°C)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (current.value / 50.0).clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(tempColor),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0°C', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('25°C', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('50°C', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Extra Cards: Humidity & Raw Payload
                            Row(
                              children: [
                                if (current.humidity != null) ...[
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            color: Colors.blue.shade700,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Kelembapan',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              Text(
                                                '${current.humidity!.toStringAsFixed(1)} %',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.code,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Payload MQTT',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              Text(
                                                current.rawPayload,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'monospace',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // History Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Pembacaan Suhu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (mqtt.temperatureHistory.isNotEmpty)
                    Text(
                      '${mqtt.temperatureHistory.length} data',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // History List
          if (mqtt.temperatureHistory.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Belum ada riwayat data suhu yang diterima.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = mqtt.temperatureHistory[index];
                    final color = _getTempColor(item.value);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(
                            _getTempIcon(item.value),
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${item.value.toStringAsFixed(1)} °C${item.humidity != null ? ' | ${item.humidity!.toStringAsFixed(0)}% RH' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: color,
                          ),
                        ),
                        subtitle: Text(
                          'Raw: ${item.rawPayload}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          item.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: mqtt.temperatureHistory.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
