import 'package:flutter/material.dart';
import '../services/ble_simulation_service.dart';

class WearableMonitor extends StatefulWidget {
  const WearableMonitor({super.key});

  @override
  State<WearableMonitor> createState() => _WearableMonitorState();
}

class _WearableMonitorState extends State<WearableMonitor> {
  final BleSimulationService _bleService = BleSimulationService();
  bool _isAlertActive = false;

  @override
  void initState() {
    super.initState();
    _bleService.startListening();

    _bleService.sensorDataStream.listen((data) {
      final int heartRate = data['heartRate'] ?? 0;
    
      if (heartRate > 100 && !_isAlertActive) {
        _isAlertActive = true;
        _mostrarAlertaCritica();
      } else if (heartRate <= 100) {
        _isAlertActive = false;
      }
    });
  }

  void _mostrarAlertaCritica() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ ALERTA: Ritmo cardíaco elevado detectado. Su vuelo ha sido notificado.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _bleService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _bleService.sensorDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Sincronizando con el reloj...'),
                  ],
                ),
              );
            }

            final data = snapshot.data ?? {'heartRate': 0, 'steps': 0, 'calories': 0};

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Estado del Pasajero (Abordaje)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSensorMetric(Icons.favorite, Colors.red, '${data['heartRate']} bpm'),
                    _buildSensorMetric(Icons.map, Colors.blue, '${data['steps']} m'),
                    _buildSensorMetric(Icons.timer, Colors.orange, '${data['calories']} min'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSensorMetric(IconData icon, Color color, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}