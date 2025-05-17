import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geofence_tracker/helper/logger.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../controller/geoFenceController.dart';
import '../helper/toaster.dart';
import '../model/geoFenceHistoryModel.dart';

class GeoFenceHistoryController extends GetxController {
  /// Observables
  Rx<LatLng> mapPosition = const LatLng(11.005064, 76.950846).obs;
  Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();
  RxBool isMapLoading = true.obs;
  RxBool isPolylineLoading = true.obs;

  /// PolyLines
  RxMap<PolylineId, Polyline> polylines = <PolylineId, Polyline>{}.obs;
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  /// Markers
  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  /// Dependencies
  final GeofenceController geofenceController = Get.find<GeofenceController>();

  /// Polyline colors
  final Map<String, Color> geofenceColors = {};
  final List<Color> polylineColorPool = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.cyan,
    Colors.pink,
    Colors.teal,
  ];

  /// Cache
  final Map<String, List<LatLng>> _polylineCache = {};
  SharedPreferences? _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    logger.i('GeoFenceHistoryController initialized');
    try {
      _prefs = await SharedPreferences.getInstance();
      await initializeMapPosition();
      await getPolylinesForHistory();
    } catch (e) {
      logger.e('Error during controller initialization: $e');
      isMapLoading.value = false;
      isPolylineLoading.value = false;
    }
  }

  @override
  void onClose() {
    googleMapController.value?.dispose();
    super.onClose();
    logger.i('GeoFenceHistoryController closed');
  }

  Future<void> initializeMapPosition() async {
    try {
      logger.i('Initializing map position');
      if (geofenceController.currentPosition.value != null) {
        mapPosition.value = LatLng(
          geofenceController.currentPosition.value!.latitude,
          geofenceController.currentPosition.value!.longitude,
        );
        logger.i('Set position from currentPosition: ${mapPosition.value}');
      } else if (geofenceController.history.isNotEmpty) {
        mapPosition.value = LatLng(
          geofenceController.history.last.latitude,
          geofenceController.history.last.longitude,
        );
        logger.i('Set position from history: ${mapPosition.value}');
      } else {
        await geofenceController.getCurrentLocation();
        if (geofenceController.currentPosition.value != null) {
          mapPosition.value = LatLng(
            geofenceController.currentPosition.value!.latitude,
            geofenceController.currentPosition.value!.longitude,
          );
          logger.i('Set position from getCurrentLocation: ${mapPosition.value}');
        } else {
          logger.w('No position available, using default: ${mapPosition.value}');
        }
      }
      await setCameraPosition(polylineCoordinates);
      isMapLoading.value = false;
    } catch (e) {
      logger.e('Error initializing map position: $e');
      isMapLoading.value = false;
    }
  }

  Future<void> getPolylinesForHistory({int limit = 50}) async {
    String googleApiKey = 'YOUR_API_KEY_HERE';
    if (googleApiKey.isEmpty) {
      logger.e('Google Maps API key is missing');
      Toast.showToast('API key not configured');
      isPolylineLoading.value = false;
      return;
    }

    isPolylineLoading.value = true;
    polylines.clear();
    polylineCoordinates.clear();
    geofenceColors.clear();
    markers.clear(); // Clear existing markers

    try {
      logger.i('Fetching polylines and markers for history, limit: $limit');

      /// Group history entries by geofence title
      Map<String, List<History>> groupedHistory = {};
      for (var entry in geofenceController.history.take(limit)) {
        String title = entry.geofenceTitle ?? 'Unknown_${entry.hashCode}';
        groupedHistory.putIfAbsent(title, () => []).add(entry);
      }
      logger.i('Grouped history: ${groupedHistory.keys.length} geofences');

      /// Assign colors
      int colorIndex = 0;
      for (var title in groupedHistory.keys) {
        geofenceColors[title] = polylineColorPool[colorIndex % polylineColorPool.length];
        colorIndex++;
      }

      /// Process each geofence group
      for (var entry in groupedHistory.entries) {
        String geofenceTitle = entry.key;
        List<History> entries = entry.value..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        List<LatLng> routeCoordinates = [];
        logger.i('Processing geofence: $geofenceTitle, entries: ${entries.length}');

        /// Add markers for each history entry
        addMarkers(entries, geofenceTitle, geofenceColors[geofenceTitle] ?? Colors.blue);

        /// Batch points (up to 8 waypoints + origin/destination)
        for (int i = 0; i < entries.length - 1; i += 8) {
          List<History> batch = entries.sublist(
            i,
            (i + 9) < entries.length ? i + 9 : entries.length,
          );
          if (batch.length < 2) continue;

          try {
            List<LatLng> batchCoordinates = await _getBatchRouteCoordinates(
              googleApiKey,
              batch,
              geofenceTitle,
            );
            routeCoordinates.addAll(batchCoordinates);
          } catch (e) {
            logger.e('Error in batch for $geofenceTitle: $e');
            Toast.showToast('Failed to load route for $geofenceTitle');
            for (int j = 0; j < batch.length - 1; j++) {
              routeCoordinates.add(LatLng(batch[j].latitude, batch[j].longitude));
              routeCoordinates.add(LatLng(batch[j + 1].latitude, batch[j + 1].longitude));
            }
          }
        }

        if (routeCoordinates.isNotEmpty) {
          addPolyLine(
            routeCoordinates,
            geofenceTitle,
            geofenceColors[geofenceTitle] ?? Colors.blue,
          );
          polylineCoordinates.addAll(routeCoordinates);
          logger.i('Added polyline for $geofenceTitle, points: ${routeCoordinates.length}');
        }
      }

      /// Update camera
      if (polylineCoordinates.isNotEmpty || geofenceController.geoFences.isNotEmpty) {
        await setCameraPosition(polylineCoordinates);
      } else {
        logger.w('No polylines or geofences to display');
      }
    } catch (e) {
      logger.e('Error fetching polylines: $e');
      // Get.snackbar('Error', 'Failed to load polylines: $e');
    } finally {
      isPolylineLoading.value = false;
      update();
      logger.i('Polyline and marker loading complete');
    }
  }

  Future<List<LatLng>> _getBatchRouteCoordinates(
      String googleApiKey,
      List<History> batch,
      String geofenceTitle,
      ) async {
    if (batch.length < 2) return [];

    /// Cache key
    String cacheKey = batch.map((e) => '${e.latitude},${e.longitude}').join('|');
    String prefsKey = 'polyline_$cacheKey';

    /// Check in-memory cache
    if (_polylineCache.containsKey(cacheKey)) {
      logger.i('Cache hit for $cacheKey');
      return _polylineCache[cacheKey]!;
    }

    /// Check SharedPreferences
    String? cachedData = _prefs?.getString(prefsKey);
    if (cachedData != null) {
      List<dynamic> cachedPoints = jsonDecode(cachedData);
      List<LatLng> cachedCoordinates = cachedPoints
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList();
      _polylineCache[cacheKey] = cachedCoordinates;
      logger.i('Shared Preferences cache hit for $prefsKey');
      return cachedCoordinates;
    }

    /// Prepare waypoints as PolylineWayPoint
    List<PolylineWayPoint> waypoints = batch
        .sublist(1, batch.length - 1)
        .map((e) => PolylineWayPoint(location: '${e.latitude},${e.longitude}'))
        .toList();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(batch.first.latitude, batch.first.longitude),
        destination: PointLatLng(batch.last.latitude, batch.last.longitude),
        mode: TravelMode.driving,
        wayPoints: waypoints,
      ),
    );

    List<LatLng> coordinates = [];
    if (result.points.isNotEmpty) {
      coordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      /// Cache result
      _polylineCache[cacheKey] = coordinates;
      await _prefs?.setString(
        prefsKey,
        jsonEncode(coordinates
            .map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
            .toList()),
      );
      logger.i('Cached polyline for $prefsKey');
    } else {
      logger.w('No route found for batch in $geofenceTitle');
      coordinates = batch
          .asMap()
          .entries
          .expand((entry) => [
        if (entry.key < batch.length - 1) ...[
          LatLng(entry.value.latitude, entry.value.longitude),
          LatLng(batch[entry.key + 1].latitude, batch[entry.key + 1].longitude),
        ]
      ])
          .toList();
    }

    return coordinates;
  }

  void addPolyLine(List<LatLng> coordinates, String geofenceTitle, Color color) {
    PolylineId id = PolylineId('poly_$geofenceTitle');
    Polyline polyline = Polyline(
      polylineId: id,
      color: color,
      points: coordinates,
      jointType: JointType.mitered,
      geodesic: true,
      visible: true,
      width: 10,
    );
    polylines[id] = polyline;
    logger.i('Polyline added: $geofenceTitle, points: ${coordinates.length}');
  }

  void addMarkers(List<History> entries, String geofenceTitle, Color color) {
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final markerId = MarkerId('marker_${geofenceTitle}_$i');
      final marker = Marker(
        markerId: markerId,
        position: LatLng(entry.latitude, entry.longitude),
        infoWindow: InfoWindow(
          title: geofenceTitle,
          snippet: '${entry.status} at ${DateFormat('hh:mm a, MMM dd').format(entry.timestamp)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getHueFromColor(color)),
      );
      markers[markerId] = marker;
      logger.i('Added marker for $geofenceTitle at (${entry.latitude}, ${entry.longitude})');
    }
  }

  double _getHueFromColor(Color color) {
    // Convert Color to HSV to extract hue
    final hsvColor = HSVColor.fromColor(color);
    return hsvColor.hue;
  }

  Future<void> setCameraPosition(List<LatLng> coordinates) async {
    if (googleMapController.value == null) {
      logger.w('GoogleMapController not ready');
      return;
    }

    List<LatLng> allPoints = [...coordinates];
    allPoints.addAll(geofenceController.geoFences.map((g) => LatLng(g.latitude, g.longitude)));

    if (allPoints.isEmpty) {
      logger.w('No points for camera bounds, using default position');
      await googleMapController.value?.animateCamera(
        CameraUpdate.newLatLngZoom(mapPosition.value, 15),
      );
      return;
    }

    LatLngBounds bounds = boundsFromLatLngList(allPoints);
    logger.i('Camera bounds: NE(${bounds.northeast.latitude}, ${bounds.northeast.longitude}), SW(${bounds.southwest.latitude}, ${bounds.southwest.longitude})');

    if (bounds.northeast == bounds.southwest) {
      await googleMapController.value?.animateCamera(
        CameraUpdate.newLatLngZoom(allPoints.first, 15),
      );
    } else {
      await googleMapController.value?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      x0 = x0 == null ? latLng.latitude : latLng.latitude < x0 ? latLng.latitude : x0;
      x1 = x1 == null ? latLng.latitude : latLng.latitude > x1 ? latLng.latitude : x1;
      y0 = y0 == null ? latLng.longitude : latLng.longitude < y0 ? latLng.longitude : y0;
      y1 = y1 == null ? latLng.longitude : latLng.longitude > y1 ? latLng.longitude : y1;
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }
}