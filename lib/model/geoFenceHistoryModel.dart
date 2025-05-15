import 'dart:convert';

class History {
  DateTime timestamp;
  double latitude;
  double longitude;
  String status;

  History({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
  };

  factory History.fromJson(Map<String, dynamic> json) => History(
    timestamp: DateTime.parse(json['timestamp']),
    latitude: json['latitude'],
    longitude: json['longitude'],
    status: json['status'],
  );
}