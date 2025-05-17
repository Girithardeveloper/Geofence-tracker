import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofence_tracker/constants/colorConstants.dart';
import 'package:geofence_tracker/constants/fontConstants.dart';
import 'package:geofence_tracker/globalWidgets/textWidget.dart';
import 'package:geofence_tracker/helper/toaster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' as location;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/logger.dart';
import '../model/geoFenceHistoryModel.dart';
import '../model/geoFenceModel.dart';

@pragma('vm:entry-point')
class GeofenceController extends GetxController {
  var geoFences = <Geofence>[].obs;
  var history = <History>[].obs;
  var currentPosition = Rxn<Position>();
  var currentLat = ''.obs;
  var currentLong = ''.obs;
  var isTracking = false.obs;

  static int _notificationId = 0;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  Timer? _permissionRecheckTimer;

  Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      bool? initialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      if (initialized != true) {
        logger.e('Notification initialization failed');
        throw Exception('Failed to initialize notifications');
      }
      if (Platform.isAndroid) {
        const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
          'geofence_background',
          'Geofence Background Service',
          description: 'Notification channel for geofence background service',
          importance: Importance.low,
        );
        const AndroidNotificationChannel geofenceChannel = AndroidNotificationChannel(
          'geofence_channel',
          'Geofence Notifications',
          description: 'Notifications for geofence entry and exit events',
          importance: Importance.high,
        );
        final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(backgroundChannel);
        await androidPlugin?.createNotificationChannel(geofenceChannel);
        logger.i('Notification channels created');
      }
    } catch (e) {
      logger.e('Failed to initialize notifications: $e');
      Toast.showToast('Notifications may not work. Please check permissions.');
    }
  }

  Future<void> initializeBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'geofence_background',
          initialNotificationTitle: 'Geofence Tracker',
          initialNotificationContent: 'Monitoring location in background',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onBackgroundServiceStart,
          onBackground: onIosBackground,
        ),
      );
      await service.startService();
      logger.i('Background service initialized and started');
    } catch (e) {
      logger.e('Failed to initialize background service: $e');
      Toast.showToast('Failed to start background service');
    }
  }

  @pragma('vm:entry-point')
  static void onBackgroundServiceStart(ServiceInstance service) async {
    logger.i('Background service started');
    try {
      if (Platform.isAndroid) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          logger.w('Notification permission not granted for background service');
          return;
        }
      }
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      if (service is AndroidServiceInstance) {
        await service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: 'Geofence Tracker',
          content: 'Monitoring location in background',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final geofenceList = prefs.getString('geofences') ?? '[]';
      final List<Geofence> geofences = (jsonDecode(geofenceList) as List).map((json) => Geofence.fromJson(json)).toList();

      Timer.periodic(Duration(seconds: 60), (timer) async {
        logger.i('Updating location in background');
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await _checkGeofencesInBackground(position, geofences);
        } catch (e) {
          logger.e('Background location update failed: $e');
        }
      });
    } catch (e) {
      logger.e('Error in background service start: $e');
    }
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    logger.i('iOS background service running');
    Timer(Duration(seconds: 60), () async {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final prefs = await SharedPreferences.getInstance();
        final geofenceList = prefs.getString('geofences') ?? '[]';
        final List<Geofence> geofences = (jsonDecode(geofenceList) as List).map((json) => Geofence.fromJson(json)).toList();
        await _checkGeofencesInBackground(position, geofences);
      } catch (e) {
        logger.e('iOS background location update failed: $e');
      }
    });
    return true;
  }

  static Future<void> _checkGeofencesInBackground(Position position, List<Geofence> geofences) async {
    try {
      final updates = _checkGeofencesIsolate({'position': position, 'geofences': geofences});
      if (updates.isEmpty) {
        logger.i('No geofence status changes detected in background');
        return;
      }
      for (var update in updates) {
        final index = update['index'] as int;
        final status = update['status'] as String;
        final geofence = geofences[index];
        logger.i('Background geofence event: $status ${geofence.title}');
        await showNotification(
          geofence.title,
          '$status ${geofence.title} at (${geofence.latitude.toStringAsFixed(4)}, ${geofence.longitude.toStringAsFixed(4)})',
        );
        final prefs = await SharedPreferences.getInstance();
        final historyList = prefs.getString('history') ?? '[]';
        final List<History> history = (jsonDecode(historyList) as List).map((json) => History.fromJson(json)).toList();
        history.add(History(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          status: status,
          geofenceTitle: geofence.title, // Add geofence title
        ));
        await prefs.setString('history', jsonEncode(history.map((h) => h.toJson()).toList()));
      }
    } catch (e) {
      logger.e('Error checking geofences in background: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentLat.value = position.latitude.toString();
      currentLong.value = position.longitude.toString();
      currentPosition.value = position;
      logger.i('Current location: Lat: ${currentLat.value}, Long: ${currentLong.value}');
    } catch (e) {
      logger.e('Failed to get current location: $e');
      Toast.showToast('Failed to get location: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      bool canStartService = true;

      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.w('Location services disabled');
        openAppSettings();

        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          logger.w('Location services still disabled');
          Toast.showToast('Location services are required for tracking.');
          canStartService = false;
        }
      }

      // Request foreground location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          logger.w('Foreground location permission denied');
          Toast.showToast('Please allow location access.');
          canStartService = false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        logger.w('Foreground location permission permanently denied');
        openAppSettings();
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.deniedForever) {
          logger.w('Foreground location permission still denied forever');
          Toast.showToast('Location permission is required for tracking.');
          canStartService = false;
        }
      }

      if (Platform.isAndroid && canStartService) {
        // Request background location permission
        var status = await Permission.locationAlways.status;
        if (!status.isGranted) {
          status = await Permission.locationAlways.request();
          if (!status.isGranted) {
            logger.w('Background location permission denied');
            openAppSettings();
            status = await Permission.locationAlways.status;
            if (!status.isGranted) {
              logger.w('Background location permission still denied');
              Toast.showToast('Background location access is required.');
              canStartService = false;
            }
          }
        }

        // Request notification permission
        status = await Permission.notification.status;
        if (!status.isGranted) {
          status = await Permission.notification.request();
          if (!status.isGranted) {
            logger.w('Notification permission denied');
            openAppSettings();

            status = await Permission.notification.status;
            if (!status.isGranted) {
              logger.w('Notification permission still denied');
              Toast.showToast('Notifications are required for geofence alerts.');
              canStartService = false;
            }
          }
        }

        // Request battery optimization exemption
        status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
          status = await Permission.ignoreBatteryOptimizations.request();
          if (!status.isGranted) {
            logger.w('Battery optimization not disabled');
            openAppSettings();

            status = await Permission.ignoreBatteryOptimizations.status;
            if (!status.isGranted) {
              logger.w('Battery optimization still not disabled');
              Toast.showToast('Disabling battery optimization is recommended.');
              // Optional: Proceed even if not granted
            }
          }
        }
      }

      if (canStartService) {
        logger.i('All required permissions granted, starting service');
        await initializeBackgroundService();
        startLocationTracking();
      } else {
        logger.w('Some permissions missing, service not started');
        Toast.showToast('Please grant all permissions to enable tracking.');
      }
    } catch (e) {
      logger.e('Failed to request permissions: $e');
      Toast.showToast('Failed to request permissions: $e');
    }
  }


  Future<void> loadGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofenceList = prefs.getString('geofences') ?? '[]';
      final List<dynamic> jsonList = jsonDecode(geofenceList);
      geoFences.assignAll(jsonList.map((json) => Geofence.fromJson(json)).toList());
      logger.i('Geofences loaded: ${geoFences.length}');
    } catch (e) {
      logger.e('Failed to load geofences: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getString('history') ?? '[]';
      final List<dynamic> jsonList = jsonDecode(historyList);
      final List<History> loadedHistory = jsonList.map((json) => History.fromJson(json)).toList();

      // Migrate old entries to include geofenceTitle (optional)
      for (var entry in loadedHistory) {
        if (entry.geofenceTitle == null) {
          // Find the closest geofence based on coordinates
          Geofence? closestGeofence;
          double minDistance = double.infinity;
          for (var geofence in geoFences) {
            double distance = Geolocator.distanceBetween(
              entry.latitude,
              entry.longitude,
              geofence.latitude,
              geofence.longitude,
            );
            if (distance < minDistance && distance <= geofence.radius) {
              minDistance = distance;
              closestGeofence = geofence;
            }
          }
          if (closestGeofence != null) {
            entry.geofenceTitle = closestGeofence.title;
          } else {
            entry.geofenceTitle = 'Unknown Geofence';
          }
        }
      }

      history.assignAll(loadedHistory);
      logger.i('History loaded: ${history.length}');
    } catch (e) {
      logger.e('Failed to load history: $e');
    }
  }

  Future<void> saveGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = geoFences.map((geofence) => geofence.toJson()).toList();
      await prefs.setString('geofences', jsonEncode(jsonList));
      logger.i('Geofences saved');
    } catch (e) {
      logger.e('Failed to save geofences: $e');
    }
  }

  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((entry) => entry.toJson()).toList();
      await prefs.setString('history', jsonEncode(jsonList));
      logger.i('History saved');
    } catch (e) {
      logger.e('Failed to save history: $e');
    }
  }

  Future<void> addGeofence(Geofence geofence) async {
    try {
      geoFences.add(geofence);
      await saveGeofences();
      logger.i('Geofence added: ${geofence.title}');
    } catch (e) {
      logger.e('Failed to add geofence: $e');
    }
  }

  Future<void> updateGeofence(int index, Geofence geofence) async {
    try {
      geoFences[index] = geofence;
      await saveGeofences();
      logger.i('Geofence updated at index: $index');
    } catch (e) {
      logger.e('Failed to update geofence: $e');
    }
  }

  Future<void> deleteGeofence(int index) async {
    try {
      geoFences.removeAt(index);
      await saveGeofences();
      logger.i('Geofence deleted at index: $index');
    } catch (e) {
      logger.e('Failed to delete geofence: $e');
    }
  }


  Future<void> startLocationTracking() async {
    try {
      bool isPermissionGranted = await _checkLocationPermission();
      if (!isPermissionGranted) {
        logger.w('Location permission not granted');
        return;
      }

      _locationTimer?.cancel();
      _positionStream?.cancel();

      _locationTimer = Timer.periodic(Duration(seconds: 60), (_) async {
        await updateLocation();
      });

      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(
            (Position position) {
          currentPosition.value = position;
          checkGeofences(position);
        },
        onError: (e) {
          logger.e('Location stream error: $e');
          Toast.showToast('Location access denied or unavailable: $e');
        },
      );

      isTracking.value = true;
      logger.i('Location tracking started');
    } catch (e) {
      logger.e('Failed to start location tracking: $e');
      Toast.showToast('Failed to start location tracking: $e');
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      final locationService = location.Location();

      bool serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) {
          logger.w("Location service is disabled.");
          return false;
        }
      }

      final status = await Permission.location.status;

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final newStatus = await Permission.location.request();
        if (newStatus.isGranted) {
          return true;
        } else if (newStatus.isPermanentlyDenied) {
          openAppSettings();
          Toast.showToast('Please enable location permission in settings.');
          return false;
        } else {
          logger.i("Location permission denied.");
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
        Toast.showToast('Please enable location permission in settings.');
        return false;
      }

      return false;
    } catch (e) {
      logger.e("Permission check error: $e");
      return false;
    }
  }



  Future<void> updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      checkGeofences(position);
    } catch (e) {
      logger.e('Failed to update location: $e');
      Toast.showToast('Failed to get location: $e');
    }
  }

  Future<void> checkGeofences(Position position) async {
    try {
      final result = await compute(_checkGeofencesIsolate, {
        'position': position,
        'geofences': geoFences.toList(),
      });
      if (result.isEmpty) {
        logger.i('No geofence status changes detected');
        return;
      }
      for (var update in result) {
        final index = update['index'] as int;
        final status = update['status'] as String;
        final geofence = geoFences[index];
        geofence.isInside = status == 'Entered';
        geoFences[index] = geofence;
        logger.i('Foreground geofence event: $status ${geofence.title}');
        await showNotification(
          geofence.title,
          '$status ${geofence.title} at (${geofence.latitude.toStringAsFixed(4)}, ${geofence.longitude.toStringAsFixed(4)})',
        );
        addHistory(History(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          status: status,
          geofenceTitle: geofence.title, // Add geofence title
        ));
      }
    } catch (e) {
      logger.e('Error checking geofences: $e');
      Toast.showToast('Failed to check geofences: $e');
    }
  }

  static List<Map<String, dynamic>> _checkGeofencesIsolate(Map<String, dynamic> data) {
    try {
      final position = data['position'] as Position;
      final geofences = data['geofences'] as List<Geofence>;
      final updates = <Map<String, dynamic>>[];
      for (var i = 0; i < geofences.length; i++) {
        final geofence = geofences[i];
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          geofence.latitude,
          geofence.longitude,
        );
        bool isInside = distance <= geofence.radius;
        if (isInside != geofence.isInside) {
          String status = isInside ? 'Entered' : 'Exited';
          updates.add({
            'index': i,
            'status': status,
          });
        }
      }
      return updates;
    } catch (e) {
      logger.e('Error in geofence isolate: $e');
      return [];
    }
  }

  Future<void> addHistory(History entry) async {
    try {
      history.add(entry);
      await saveHistory();
      logger.i('History entry added: ${entry.status} for ${entry.geofenceTitle ?? "unknown"}');
    } catch (e) {
      logger.e('Failed to add history: $e');
    }
  }

  static Future<void> showNotification(String title, String body) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          logger.w('Notification permission not granted');
          return;
        }
      }
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'geofence_channel',
        'Geofence Notifications',
        channelDescription: 'Notifications for geofence entry and exit events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );
      await flutterLocalNotificationsPlugin.show(
        _notificationId++,
        title,
        body,
        platformChannelSpecifics,
      );
      logger.i('Notification shown: $title - $body');
    } catch (e) {
      logger.e('Failed to show notification: $e');
    }
  }


  @override
  void onInit() {
    super.onInit();
    logger.i('GeofenceController initialized');
    initializeNotifications().then((_) {
      loadGeofences();
      loadHistory();
      requestPermissions();
    }).catchError((e) {
      logger.e('Error initializing notifications: $e');
      Toast.showToast('Notification initialization failed');
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Recheck permissions after a delay to ensure activity is restored
    _permissionRecheckTimer?.cancel();
    _permissionRecheckTimer = Timer(const Duration(seconds: 2), () {
      requestPermissions();
    });
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    _permissionRecheckTimer?.cancel();
    logger.i('GeofenceController closed');
    super.onClose();
  }
}