import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.100.11:3000/api';

  Future<List<Trip>> getTrips() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/trips'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Trip> trips = body.map((dynamic item) => Trip.fromJson(item)).toList();
        return trips;
      } else {
        throw Exception('Error al cargar los viajes del servidor');
      }
    } catch (e) {
      throw Exception('Error de red: No se pudo conectar a la API. $e');
    }
  }
}