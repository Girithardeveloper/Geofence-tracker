import 'package:flutter/material.dart';
import 'package:geofence_tracker/helper/logger.dart';
import 'package:geofence_tracker/view/homeView.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/colorConstants.dart';
import '../constants/fontConstants.dart';
import '../controller/geoFenceController.dart';
import '../controller/geoFenceHistoryController.dart';
import '../globalWidgets/textWidget.dart';

class HistoryScreen extends StatelessWidget {
  final GeofenceController geofenceController = Get.find<GeofenceController>();
  final GeoFenceHistoryController geoFenceHistoryController = Get.find<GeoFenceHistoryController>();

  HistoryScreen({super.key}) {
    ever(geofenceController.currentPosition, (_) {
      if (geofenceController.currentPosition.value != null) {
        geoFenceHistoryController.mapPosition.value = LatLng(
          geofenceController.currentPosition.value!.latitude,
          geofenceController.currentPosition.value!.longitude,
        );
        logger.i('Current position updated: ${geoFenceHistoryController.mapPosition.value}');
        geoFenceHistoryController.setCameraPosition(geoFenceHistoryController.polylineCoordinates);
      }
    });
    ever(geofenceController.history, (_) {
      logger.i('History updated: ${geofenceController.history.length} entries');
      geoFenceHistoryController.getPolylinesForHistory(); // Refresh polylines on history change
      if (geofenceController.history.isNotEmpty) {
        geoFenceHistoryController.mapPosition.value = LatLng(
          geofenceController.history.last.latitude,
          geofenceController.history.last.longitude,
        );
        logger.i('History position updated: ${geoFenceHistoryController.mapPosition.value}');
        geoFenceHistoryController.setCameraPosition(geoFenceHistoryController.polylineCoordinates);
      }
    });
    ever(geofenceController.geoFences, (_) {
      logger.i('Geofences updated: ${geofenceController.geoFences.length} geofences');
      geoFenceHistoryController.setCameraPosition(geoFenceHistoryController.polylineCoordinates);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        Get.off(()=>HomeScreen());
        return false;
      },
      child: GetBuilder<GeoFenceHistoryController>(
        initState: (_) {
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
                      Get.off(()=>HomeScreen());
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
                      logger.i('Map loading: ${controller.isMapLoading.value}');
                      logger.i('History count: ${geofenceController.history.length}');
                      logger.i('Geofences count: ${geofenceController.geoFences.length}');
                      return controller.isMapLoading.value
                          ?  Center(child: CircularProgressIndicator(color: ColorConstants.primaryColor,))
                          : Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.secondaryColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorConstants.grey),
                        ),
                        child: Obx(()=>ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              GoogleMap(
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                mapToolbarEnabled: true,
                                compassEnabled: true,
                                initialCameraPosition: CameraPosition(
                                  target: controller.mapPosition.value,
                                  zoom: 15,
                                ),
                                onMapCreated: (GoogleMapController mapController) {
                                  controller.googleMapController.value = mapController;
                                  controller.setCameraPosition(controller.polylineCoordinates);
                                  logger.i('Map created, controller set');
                                },
                                polylines: controller.polylines.values.toSet(),
                                markers: controller.markers.values.toSet(), // Add markers
                                circles: geofenceController.geoFences.isEmpty
                                    ? {
                                  Circle(
                                    circleId: CircleId('test_circle'),
                                    center: LatLng(11.005064, 76.950846),
                                    radius: 500,
                                    fillColor: Colors.red.withOpacity(0.5),
                                    strokeColor: Colors.redAccent,
                                    strokeWidth: 2,
                                  ),
                                }
                                    : geofenceController.geoFences.take(10).map((geofence) {
                                  logger.i('Creating circle: ${geofence.title}, Lat: ${geofence.latitude}, Lng: ${geofence.longitude}, Radius: ${geofence.radius}');
                                  return Circle(
                                    circleId: CircleId(geofence.title ?? 'circle_${geofence.hashCode}'),
                                    center: LatLng(geofence.latitude, geofence.longitude),
                                    radius: geofence.radius.clamp(10, 1000),
                                    fillColor: Colors.blue.withOpacity(0.5),
                                    strokeColor: Colors.blueAccent,
                                    strokeWidth: 2,
                                  );
                                }).toSet(),
                              ),
                              // Legend for polylines
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(100),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: controller.geofenceColors.entries.map((entry) {
                                      return Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 10,
                                            color: entry.value,
                                          ),
                                          SizedBox(width: 8),
                                          ReusableTextWidget(
                                            text: entry.key,
                                            fontSize: 14,
                                            color: ColorConstants.blackColor,
                                            fontFamily: FontConstants.fontFamily,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),)

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
                          text: 'No data at this moment',
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
                      itemCount: geofenceController.history.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = geofenceController.history.length - 1 - index;
                        final entry = geofenceController.history[reversedIndex];
                        final formattedTime = DateFormat('hh:mm a').format(entry.timestamp);
                        final formattedDate = DateFormat('MMM dd, yyyy').format(entry.timestamp);

                        return Card(
                          color: ColorConstants.secondaryColor,
                          child: ListTile(
                            title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReusableTextWidget(
                                  text: '${entry.geofenceTitle ?? "Unknown Geofence"} ',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: FontConstants.fontFamily,
                                  color: ColorConstants.primaryColor,
                                ),
                                ReusableTextWidget(
                                  text: '${entry.status} ',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: FontConstants.fontFamily,
                                  color: ColorConstants.primaryColor,
                                ),
                              ],
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
                    ),
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