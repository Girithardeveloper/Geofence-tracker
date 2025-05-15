import 'dart:convert';

class Geofence {
  String title;
  double latitude;
  double longitude;
  double radius;
  bool isInside;

  Geofence({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isInside = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'isInside': isInside,
  };

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    title: json['title'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    radius: json['radius'],
    isInside: json['isInside'],
  );
}