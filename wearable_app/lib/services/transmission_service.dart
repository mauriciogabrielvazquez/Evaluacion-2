import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/ble_uuids.dart';

class TransmissionService {
  static const String baseUrl = 'http://192.168.100.11:3000/api';
  Future<void> sendSensorData({
    required int heartRate,
    required int steps,
    required int calories,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/wearable/notify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'serviceUuid': BleUuids.sensorService,
          'characteristics': {
            BleUuids.heartRateCharacteristic: heartRate,
            BleUuids.stepsCharacteristic: steps,
            BleUuids.caloriesCharacteristic: calories,
          }
        }),
      );
    } catch (e) {
    }
  }
}