import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TravelAppWearable());
}

class TravelAppWearable extends StatelessWidget {
  const TravelAppWearable({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelApp Wearable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1565C0),
          secondary: Color(0xFFFBC02D),
        ),
      ),
      home: const WearableHomeScreen(),
    );
  }
}

enum DeviceState { disconnected, advertising, connected }

class WearableHomeScreen extends StatefulWidget {
  const WearableHomeScreen({super.key});

  @override
  State<WearableHomeScreen> createState() => _WearableHomeScreenState();
}

class _WearableHomeScreenState extends State<WearableHomeScreen> {
  DeviceState _currentState = DeviceState.disconnected;
  bool _isBoarding = false;
  
  int _heartRate = 75;
  int _distance = 350; 
  int _timeRemaining = 15; 
  int _tickCounter = 0;
  
  Timer? _statusTimer;
  Timer? _boardingTimer;
  Timer? _simulationTimer;

  final String baseUrl = 'http://192.168.100.11:3000/api';

  Future<void> _startAdvertising() async {
    setState(() => _currentState = DeviceState.advertising);
    try {
      await http.post(
        Uri.parse('$baseUrl/ble/advertise'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'advertising': true}),
      );

      _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final response = await http.get(Uri.parse('$baseUrl/ble/status'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['isConnected'] == true) {
              timer.cancel();
              if (mounted) {
                setState(() => _currentState = DeviceState.connected);
                _startBoardingListener();
              }
            }
          }
        } catch (e) {}
      });
    } catch (e) {}
  }

  void _startBoardingListener() {
    _boardingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/ble/board/status'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['boarding'] == true && !_isBoarding) {
            if (mounted) setState(() => _isBoarding = true);
            _startSimulation();
          } else if (data['boarding'] == false && _isBoarding) {
            if (mounted) setState(() => _isBoarding = false);
            _stopSimulation();
          }
        }
      } catch (e) {}
    });
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        setState(() {
          _tickCounter++;
          _heartRate = 80 + Random().nextInt(35);
          if (_distance > 0) _distance -= (Random().nextInt(3) + 1);
          if (_tickCounter % 6 == 0 && _timeRemaining > 0) _timeRemaining -= 1;
        });
      }
      try {
        await http.post(
          Uri.parse('$baseUrl/wearable/notify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'characteristics': {
              '00002A37-0000-1000-8000-00805f9b34fb': _heartRate,
              '00001234-0000-1000-8000-00805f9b34fb': _distance,
              '00005678-0000-1000-8000-00805f9b34fb': _timeRemaining,
            }
          }),
        );
      } catch (e) {}
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
  }

  Future<void> _cancelBoarding() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/ble/board'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'boarding': false}),
      );
      if (mounted) setState(() => _isBoarding = false);
      _stopSimulation();
    } catch (e) {}
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _boardingTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentState(),
    );
  }

  Widget _buildCurrentState() {
    switch (_currentState) {
      case DeviceState.disconnected: return _buildDisconnectedScreen();
      case DeviceState.advertising: return _buildAdvertisingScreen();
      case DeviceState.connected: return _isBoarding ? _buildBoardingActiveScreen() : _buildWaitingScreen();
    }
  }

  Widget _buildDisconnectedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('Sin emparejar', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            onPressed: _startAdvertising,
            child: const Text('Vincular Teléfono', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertisingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFBC02D)),
          SizedBox(height: 20),
          Text('Esperando conexión...', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bluetooth_connected, size: 40, color: Colors.blue),
          SizedBox(height: 15),
          Text('CONECTADO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
          SizedBox(height: 10),
          Text('Esperando orden\nde abordaje...', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBoardingActiveScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ABORDANDO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFBC02D))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.favorite, size: 16, color: Colors.redAccent), const SizedBox(width: 5), Text('$_heartRate bpm', style: const TextStyle(fontSize: 16, color: Colors.redAccent))]),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.map, size: 16, color: Colors.lightBlueAccent), const SizedBox(width: 5), Text('$_distance m', style: const TextStyle(fontSize: 16, color: Colors.lightBlueAccent))]),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.timer, size: 16, color: Colors.greenAccent), const SizedBox(width: 5), Text('$_timeRemaining min', style: const TextStyle(fontSize: 16, color: Colors.greenAccent))]),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(80, 35)),
            onPressed: _cancelBoarding,
            child: const Text('Cancelar', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}