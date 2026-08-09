import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/api_service.dart';

class TripProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Trip> _trips = [];
  bool _isLoading = true;
  String _errorMessage = '';

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  TripProvider() {
    fetchTrips(); // Obtiene los viajes automáticamente al iniciar
  }

  Future<void> fetchTrips() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _trips = await _apiService.getTrips();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los viajes. Verifica tu conexión al servidor.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}