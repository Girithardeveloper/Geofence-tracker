import 'package:geofence_tracker/helper/logger.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/geoFenceController.dart';

class GeoFenceHistoryController extends GetxController {
  Rx<LatLng> mapPosition = const LatLng(37.7749, -122.4194).obs; // Fallback: San Francisco
  Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();
  RxBool isMapLoading = true.obs;

  final GeofenceController geofenceController = Get.find<GeofenceController>();

  @override
  void onInit() {
    super.onInit();
    initializeMapPosition();
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
        }
      }
      updateCamera();
      isMapLoading.value = false;
    } catch (e) {
      logger.i('Error initializing map position: $e');
      Get.snackbar('Error', 'Unable to initialize map: $e');
      isMapLoading.value = false;
    }
  }

  void updateCamera() {
    if (googleMapController.value != null) {
      logger.i('Updating camera to: ${mapPosition.value}');
      googleMapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(mapPosition.value, 15),
      );
    }
  }
}