import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/logger.dart';
import '../model/geoFenceHistoryModel.dart';
import '../model/geoFenceModel.dart';

class GeofenceController extends GetxController {
  var geofences = <Geofence>[].obs;
  var history = <History>[].obs;
  var currentPosition = Rxn<Position>();


  Position? resultPosition;


  var currentLat;
  var currentLong;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? _locationTimer;

  @override
  void onInit() {
    super.onInit();
    loadGeofences();
    loadHistory();
    startLocationTracking();
    requestPermissions();
  }

  ///Google Map
  getCurrentLocation()async{
    resultPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentLat = resultPosition?.latitude.toString();
    currentLong = resultPosition?.longitude.toString();
   update();
    logger.i('currentLatinlocation $currentLat');
    logger.i('currentLonglocation $currentLong');
  }

  Future<void> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Location services are disabled. Please enable them in settings.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Error',
        'Location permissions are permanently denied. Please enable them in settings.',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
      await Geolocator.openAppSettings();
      return;
    }
  }


  Future<void> loadGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final geofenceList = prefs.getString('geofences') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(geofenceList);
    geofences.assignAll(jsonList.map((json) => Geofence.fromJson(json)).toList());
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getString('history') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(historyList);
    history.assignAll(jsonList.map((json) => History.fromJson(json)).toList());
  }

  Future<void> saveGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = geofences.map((geofence) => geofence.toJson()).toList();
    await prefs.setString('geofences', jsonEncode(jsonList));
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((entry) => entry.toJson()).toList();
    await prefs.setString('history', jsonEncode(jsonList));
  }

  Future<void> addGeofence(Geofence geofence) async {
    geofences.add(geofence);
    await saveGeofences();
  }

  Future<void> updateGeofence(int index, Geofence geofence) async {
    geofences[index] = geofence;
    await saveGeofences();
  }

  Future<void> deleteGeofence(int index) async {
    geofences.removeAt(index);
    await saveGeofences();
  }

  void startLocationTracking() {
    _locationTimer = Timer.periodic(Duration(minutes: 2), (_) {
      updateLocation();
    });

    Geolocator.getPositionStream().listen((Position position) {
      currentPosition.value = position;
      checkGeofences(position);
    });
  }

  Future<void> updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      checkGeofences(position);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
    }
  }

  void checkGeofences(Position position) {
    for (var geofence in geofences) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      bool isInside = distance <= geofence.radius;

      if (isInside != geofence.isInside) {
        geofence.isInside = isInside;
        updateGeofence(geofences.indexOf(geofence), geofence);

        String status = isInside ? 'Entered' : 'Exited';
        showNotification(geofence.title, '$status ${geofence.title}');
        Get.snackbar('Geofence Update', '$status ${geofence.title}');

        addHistory(History(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          status: status,
        ));
      }
    }
  }

  Future<void> addHistory(History entry) async {
    history.add(entry);
    await saveHistory();
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    super.onClose();
  }
}