import 'package:flutter/material.dart';
import 'package:geofence_tracker/helper/logger.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/colorConstants.dart';
import '../constants/fontConstants.dart';
import '../controller/geoFenceController.dart';
import '../controller/geoFenceHistoryController.dart';
import '../globalWidgets/textWidget.dart';
import 'homeView.dart';


class HistoryScreen extends StatelessWidget {

  final GeofenceController geofenceController = Get.find<GeofenceController>();
  final GeoFenceHistoryController geoFenceHistoryController = Get.find<GeoFenceHistoryController>();

  HistoryScreen({super.key}) {

    /// Initialize listeners for position and history changes
    ever(geofenceController.currentPosition, (_) {
      if (geofenceController.currentPosition.value != null) {
        geoFenceHistoryController.mapPosition.value = LatLng(
          geofenceController.currentPosition.value!.latitude,
          geofenceController.currentPosition.value!.longitude,
        );
        logger.i('Current position updated: ${geoFenceHistoryController.mapPosition.value}');
        geoFenceHistoryController.updateCamera();
      }
    });
    ever(geofenceController.history, (_) {
      logger.i('History updated: ${geofenceController.history.length} entries');
      if (geofenceController.history.isNotEmpty) {
        geoFenceHistoryController.mapPosition.value = LatLng(
          geofenceController.history.last.latitude,
          geofenceController.history.last.longitude,
        );
        logger.i('History position updated: ${geoFenceHistoryController.mapPosition.value}');
        geoFenceHistoryController.updateCamera();
      }
    });
    ever(geofenceController.geoFences, (_) {
      logger.i('Geofences updated: ${geofenceController.geoFences.length} geofences');
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: ()async{
        Get.back();
        return false;
      },
      child: GetBuilder<GeoFenceHistoryController>(
        initState: (_) {
          // Ensure map position is initialized
          geofenceController.requestPermissions().then((_) => geofenceController.startLocationTracking());
          geoFenceHistoryController.initializeMapPosition();
        },
        builder: (controller) {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: ColorConstants.primaryColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: ColorConstants.secondaryColor,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: screenSize.width * 0.04),
                  ReusableTextWidget(
                    text: 'Movement History',
                    fontFamily: FontConstants.fontFamily,
                    color: ColorConstants.secondaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableTextWidget(
                    text: 'Location :',
                    fontFamily: FontConstants.fontFamily,
                    color: ColorConstants.primaryColor,
                    fontSize: 20,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  SizedBox(
                    height: screenSize.height * 0.40,
                    child: Obx(() {
                      // Log map data
                      logger.i('Map loading: ${controller.isMapLoading.value}');
                      logger.i('History count: ${geofenceController.history.length}');
                      logger.i('Geofences count: ${geofenceController.geoFences.length}');
                      return controller.isMapLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.secondaryColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorConstants.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Obx(() => GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: controller.mapPosition.value,
                              zoom: 15,
                            ),
                            onMapCreated: (GoogleMapController mapController) {
                              controller.googleMapController.value = mapController;
                              controller.updateCamera();
                              logger.i('Map created, controller set');
                            },
                            polylines: geofenceController.history.isEmpty
                                ? {}
                                : {
                              Polyline(
                                polylineId: const PolylineId('route'),
                                points: geofenceController.history
                                    .take(100)
                                    .map((e) => LatLng(e.latitude, e.longitude))
                                    .toList(),
                                color: Colors.blue,
                                width: 4,
                              ),
                            },
                            circles: geofenceController.geoFences.isEmpty
                                ? {}
                                : geofenceController.geoFences
                                .take(10)
                                .map((geofence) => Circle(
                              circleId: CircleId(geofence.title),
                              center: LatLng(
                                geofence.latitude,
                                geofence.longitude,
                              ),
                              radius: geofence.radius,
                              fillColor: Colors.blue.withOpacity(0.2),
                              strokeColor: Colors.blue,
                              strokeWidth: 1,
                            ))
                                .toSet(),
                          )),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  ReusableTextWidget(
                    text: 'Movement history :',
                    fontFamily: FontConstants.fontFamily,
                    color: ColorConstants.primaryColor,
                    fontSize: 20,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Obx(() => geofenceController.history.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenSize.height * 0.06),
                      Center(
                        child: ReusableTextWidget(
                          text: 'No data at this movement',
                          fontFamily: FontConstants.fontFamily,
                          color: ColorConstants.blackColor,
                          fontSize: 16,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(screenSize.width * 0.02),
                      itemCount: geofenceController.history.length,
                      itemBuilder: (context, index) {
                        final entry = geofenceController.history[index];
                        // Format timestamp to AM/PM
                        final formattedTime = DateFormat('hh:mm a').format(entry.timestamp);
                        final formattedDate = DateFormat('MMM dd, yyyy').format(entry.timestamp);

                        return Card(
                          color: ColorConstants.secondaryColor,
                          child: ListTile(
                            title: ReusableTextWidget(
                              text: entry.status,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: FontConstants.fontFamily,
                              color: ColorConstants.primaryColor,
                            ),
                            subtitle: ReusableTextWidget(
                              text: '$formattedDate  $formattedTime\n'
                                  'Lat: ${entry.latitude.toStringAsFixed(4)}, '
                                  'Long: ${entry.longitude.toStringAsFixed(4)}',
                              fontSize: 16,
                              fontFamily: FontConstants.fontFamily,
                              color: ColorConstants.blackColor,
                            ),
                          ),
                        );
                      },
                    )
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}