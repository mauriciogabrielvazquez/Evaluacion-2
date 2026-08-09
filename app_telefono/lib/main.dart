import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/trip_provider.dart'; 
import 'widgets/wearable_monitor.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: const TravelAppMobile(),
    ),
  );
}

class TravelAppMobile extends StatelessWidget {
  const TravelAppMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1565C0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final String apiUrl = 'http://192.168.100.11:3000/api/auth/login';

  Future<void> _iniciarSesion() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Llena todos los campos')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['userId'] != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainTabScreen(userId: data['userId'].toString()),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error de credenciales')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al conectar con el servidor')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_takeoff, size: 80, color: Color(0xFF1565C0)),
              const SizedBox(height: 20),
              const Text(
                'Bienvenido a TravelApp',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBC02D),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _iniciarSesion,
                      child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  final String userId; 
  
  const MainTabScreen({super.key, required this.userId});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final String socketUrl = 'http://192.168.100.11:3000'; 
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _conectarSocketGlobal();
  }

  void _conectarSocketGlobal() {
    socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'userId': widget.userId}) 
        .disableAutoConnect()
        .build());
        
    socket.connect();

    socket.onConnect((_) {
      debugPrint('✅ CONECTADO AL SOCKET');
    });

    socket.on('tv_trip_selected', (data) {
      if (mounted) {
        _mostrarAlertaDeTV(data['destino'], data['asiento']);
      }
    });

    socket.on('boarding_status_changed', (data) {
      if (mounted && data['boarding'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El abordaje fue cancelado desde el wearable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _mostrarAlertaDeTV(String destino, String asiento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LiveTripModal(
        socket: socket, 
        destino: destino, 
        asiento: asiento
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect(); 
    super.dispose();
  }

  Widget _buildPantalla() {
    if (_currentIndex == 0) return const ExplorarVuelosScreen();
    return MisViajesScreen(socket: socket);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelApp', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              socket.disconnect();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: _buildPantalla(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1565C0),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorar Vuelos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airplane_ticket),
            label: 'Mis Viajes',
          ),
        ],
      ),
    );
  }
}

class ExplorarVuelosScreen extends StatefulWidget {
  const ExplorarVuelosScreen({super.key});

  @override
  State<ExplorarVuelosScreen> createState() => _ExplorarVuelosScreenState();
}

class _ExplorarVuelosScreenState extends State<ExplorarVuelosScreen> {
  List<dynamic> _viajes = [];
  bool _isLoading = true;
  final String apiTripsUrl = 'http://192.168.100.11:3000/api/trips';

  @override
  void initState() {
    super.initState();
    _cargarViajes();
  }

  Future<void> _cargarViajes() async {
    try {
      final response = await http.get(Uri.parse(apiTripsUrl));
      if (response.statusCode == 200) {
        setState(() {
          _viajes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _construirImagenViaje(String? urlImagen) {
    if (urlImagen != null && urlImagen.trim().isNotEmpty) {
      return Image.network(
        urlImagen, height: 220, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset('assets/default_trip.jpg', height: 220, width: double.infinity, fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/default_trip.jpg', height: 220, width: double.infinity, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    if (_viajes.isEmpty) return const Center(child: Text('No hay viajes disponibles.', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viajes.length,
      itemBuilder: (context, index) {
        final viaje = _viajes[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirImagenViaje(viaje['imageUrl']?.toString()),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(viaje['title'] ?? 'Destino Increíble', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)), overflow: TextOverflow.ellipsis)),
                        Text('\$${viaje['price']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFBC02D))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(children: [const Icon(Icons.location_on, size: 18, color: Colors.grey), const SizedBox(width: 5), Text(viaje['destination'] ?? 'Ubicación desconocida', style: const TextStyle(color: Colors.grey, fontSize: 16))]),
                    const SizedBox(height: 15),
                    Text(viaje['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MisViajesScreen extends StatefulWidget {
  final IO.Socket socket;
  const MisViajesScreen({super.key, required this.socket});

  @override
  State<MisViajesScreen> createState() => _MisViajesScreenState();
}

class _MisViajesScreenState extends State<MisViajesScreen> {
  final String baseUrl = 'http://192.168.100.11:3000/api';
  bool _isBoarding = false;
  String _heartRate = "--";
  String _distance = "--";
  String _time = "--";

  @override
  void initState() {
    super.initState();
    
    // Escucha cuando se cancela el viaje
    widget.socket.on('boarding_status_changed', (data) {
      if (mounted) {
        setState(() {
          _isBoarding = data['boarding'];
          if (!_isBoarding) {
            _heartRate = "--";
            _distance = "--";
            _time = "--";
          }
        });
      }
    });

    // Escucha los datos del Wearable en tiempo real
    widget.socket.on('wearable_data_update', (data) {
      if (mounted && _isBoarding) {
        setState(() {
          _heartRate = data['heartRate'].toString();
          _distance = data['steps'].toString(); 
          _time = data['calories'].toString(); 
        });
      }
    });
  }

  Future<void> _iniciarEscaneoVirtual() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escaneando frecuencias BLE...')));
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.get(Uri.parse('$baseUrl/ble/scan'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['found'] == true && mounted) {
          _mostrarModalDeDispositivos(data['device']);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontraron dispositivos en modo emparejamiento.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    } catch (e) {}
  }

  Future<void> _conectarDispositivo() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/ble/connect'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosco vinculado exitosamente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
        }
      }
    } catch (e) {}
  }

  Future<void> _enviarOrdenAbordaje() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/ble/board'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'boarding': true})
      );
      if (mounted) {
        setState(() => _isBoarding = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orden de abordaje enviada al wearable', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      }
    } catch (e) {}
  }

  void _mostrarModalDeDispositivos(Map<String, dynamic> device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 250, 
          child: Column(
            children: [
              const Text('Dispositivo Encontrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.watch, color: Color(0xFF1565C0), size: 40),
                title: Text(device['deviceName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${device['deviceId']}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                  onPressed: _conectarDispositivo,
                  child: const Text('Vincular', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWearableDataColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
            label: const Text('Vincular Wearable Independiente', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            ),
            onPressed: _iniciarEscaneoVirtual, 
          ),
          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('PRÓXIMO VUELO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text('París, Francia', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  const Text('Salida: 10:30 AM | Asiento: 14B'),
                  const SizedBox(height: 20),
                  const Icon(Icons.qr_code_2, size: 100),
                  const SizedBox(height: 20),
                  
                  // SECCIÓN DINÁMICA: Solo aparece cuando el abordaje está activo
                  if (_isBoarding) ...[
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('🛰️ Datos en vivo del Wearable:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1565C0))),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildWearableDataColumn('❤️ Ritmo', '$_heartRate bpm', Colors.red),
                          _buildWearableDataColumn('📍 Dist', '$_distance m', Colors.blue),
                          _buildWearableDataColumn('⏱️ Tiempo', '$_time min', Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  ElevatedButton.icon(
                    icon: Icon(_isBoarding ? Icons.access_time : Icons.flight_takeoff, color: Colors.black),
                    label: Text(_isBoarding ? 'Abordaje en curso...' : 'Abordar', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBoarding ? Colors.grey[400] : const Color(0xFFFBC02D),
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: _isBoarding ? null : _enviarOrdenAbordaje,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveTripModal extends StatefulWidget {
  final IO.Socket socket;
  final String destino;
  final String asiento;

  const LiveTripModal({super.key, required this.socket, required this.destino, required this.asiento});

  @override
  State<LiveTripModal> createState() => _LiveTripModalState();
}

class _LiveTripModalState extends State<LiveTripModal> {
  String _temperatura = "--";
  String _lluvia = "--";
  String _distancia = "--";

  @override
  void initState() {
    super.initState();
    widget.socket.on('live_trip_data', (data) {
      if (mounted) {
        setState(() {
          _temperatura = data['temperatura'].toString();
          _lluvia = data['probLluvia'].toString();
          _distancia = data['distancia'].toString();
        });
      }
    });

    widget.socket.on('close_modal_client', (_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    widget.socket.off('live_trip_data');
    widget.socket.off('close_modal_client');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Color(0xFF1565C0), size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text('Abordaje a ${widget.destino}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text('Asiento reservado: ${widget.asiento}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const Divider(height: 40, thickness: 1),
          const Text('Condiciones del viaje:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDataColumn('🌡️ Temp', '$_temperatura°C', Colors.orange),
                _buildDataColumn('🌧️ Lluvia', '$_lluvia%', Colors.blue),
                _buildDataColumn('📍 Distancia', '$_distancia km', Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBC02D), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Ocultar Detalles', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }
}