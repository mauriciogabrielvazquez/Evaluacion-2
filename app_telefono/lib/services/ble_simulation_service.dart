import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BleSimulationService {
  static const String baseUrl = 'http://192.168.100.11:3000/api';

  final _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sensorDataStream => _sensorDataController.stream;
  
  Timer? _pollingTimer;

  void startListening() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/wearable/data'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _sensorDataController.add(data);
        }
      } catch (e) {
      }
    });
  }

  void stopListening() {
    _pollingTimer?.cancel();
    _sensorDataController.close();
  }
}