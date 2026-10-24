import 'package:flutter/material.dart';
import '../services/mqtt_manager.dart';

class RelayPage extends StatelessWidget {
  final MqttManager mqtt;

  const RelayPage({super.key, required this.mqtt});

  static const List<IconData> defaultIcons = [
    Icons.lightbulb_outline,
    Icons.wb_incandescent_outlined,
    Icons.mode_fan_off_outlined,
    Icons.water_drop_outlined,
  ];

  static const List<IconData> defaultActiveIcons = [
    Icons.lightbulb,
    Icons.wb_incandescent,
    Icons.toys, // Fan-like icon
    Icons.water_drop,
  ];

  void _showRenameDialog(BuildContext context, int index) {
    final relay = mqtt.relays[index];
    final controller = TextEditingController(text: relay.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Nama Relay ${relay.id}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Perangkat',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                mqtt.updateRelayName(index, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = mqtt.isConnected;

    final activeCount = mqtt.relays.where((r) => r.isOn).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Connection Warning Banner if offline
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
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MQTT Offline. Hubungkan untuk mengontrol relay.',
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

          // Master Control Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Master Saklar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$activeCount dari 4 relay aktif',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: activeCount > 0
                                  ? Colors.teal.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: activeCount > 0
                                    ? Colors.teal.shade300
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Text(
                              activeCount > 0 ? '$activeCount ON' : 'ALL OFF',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: activeCount > 0
                                    ? Colors.teal.shade800
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isConnected
                                  ? () => mqtt.setAllRelays(true)
                                  : null,
                              icon: const Icon(Icons.power_settings_new, size: 18),
                              label: const Text('Nyalakan Semua'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isConnected
                                  ? () => mqtt.setAllRelays(false)
                                  : null,
                              icon: const Icon(Icons.power_off, size: 18),
                              label: const Text('Matikan Semua'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
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

          // Header for 4 Modul
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Modul Relay 4 Channel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Prefix: ${mqtt.relayTopicPrefix}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4 Relay Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final relay = mqtt.relays[index];
                  final isOn = relay.isOn;
                  final icon = isOn
                      ? defaultActiveIcons[index]
                      : defaultIcons[index];

                  final cardColor = isOn
                      ? Colors.teal.shade50
                      : theme.colorScheme.surface;
                  final borderColor = isOn
                      ? Colors.teal.shade300
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

                  return InkWell(
                    onTap: isConnected ? () => mqtt.toggleRelay(index) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: isOn ? 1.8 : 1),
                        boxShadow: isOn
                            ? [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOn
                                      ? Colors.teal.shade600
                                      : Colors.grey.shade200,
                                ),
                                child: Icon(
                                  icon,
                                  size: 24,
                                  color: isOn ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: isOn,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: Colors.teal.shade600,
                                  onChanged: isConnected
                                      ? (_) => mqtt.toggleRelay(index)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      relay.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isOn
                                            ? Colors.teal.shade900
                                            : theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showRenameDialog(context, index),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                relay.topic,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOn
                                      ? Colors.teal.shade700
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? Colors.teal.shade600
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOn ? 'ON (1)' : 'OFF (0)',
                                  style: TextStyle(
                                    color: isOn ? Colors.white : Colors.grey.shade800,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: mqtt.relays.length,
              ),
            ),
          ),

          // Log section / Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Log Aktivitas MQTT',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${mqtt.logs.length} entri',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(10),
                    color: Colors.black87,
                    child: mqtt.logs.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada log',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: mqtt.logs.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                mqtt.logs[i],
                                style: const TextStyle(
                                  color: Colors.lightGreenAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
