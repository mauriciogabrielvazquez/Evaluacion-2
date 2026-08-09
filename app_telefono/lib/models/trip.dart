class Trip {
  final String id;
  final String title;
  final String destination;
  final String description;
  final double price;
  final String date;
  final String imageUrl;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.description,
    required this.price,
    required this.date,
    required this.imageUrl,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      description: json['description'] ?? '',
      // Se asegura de convertir enteros a double para evitar errores de parseo
      price: (json['price'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}