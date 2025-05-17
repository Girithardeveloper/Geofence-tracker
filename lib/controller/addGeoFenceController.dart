import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../helper/logger.dart';

class AddGeoFenceController extends GetxController{

///Google Map
  final Rx<LatLng?> selectedLocation = Rxn<LatLng>();
  final Rx<GoogleMapController?> googleMapController = Rxn<GoogleMapController>();
  final Rx<LatLng> initialPosition = const LatLng(0.0, 0.0).obs;

  ///Text Controller

  final titleController = TextEditingController();
  final radiusController = TextEditingController();



///Initial Position
  Future<void> getInitialPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      initialPosition.value = LatLng(position.latitude, position.longitude);
      if (selectedLocation.value == null) {
        selectedLocation.value = initialPosition.value;
      }
      logger.i('Initial position: ${initialPosition.value}');
      googleMapController.value?.animateCamera(
        CameraUpdate.newLatLng(initialPosition.value),
      );
    } catch (e) {
      logger.e('Failed to get initial position: $e');
      // Fallback to a default location (e.g., city center)
      initialPosition.value = const LatLng(11.005064, 76.950846); // San Francisco
      selectedLocation.value ??= initialPosition.value;
    }
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

  }
}