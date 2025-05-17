class History {
  DateTime timestamp;
  double latitude;
  double longitude;
  String status;
  String? geofenceTitle; // New field to store geofence title

  History({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.geofenceTitle, // Nullable to handle existing data
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'geofenceTitle': geofenceTitle, // Include in JSON
  };

  factory History.fromJson(Map<String, dynamic> json) => History(
    timestamp: DateTime.parse(json['timestamp']),
    latitude: json['latitude'],
    longitude: json['longitude'],
    status: json['status'],
    geofenceTitle: json['geofenceTitle'], // Read from JSON, null if absent
  );
}