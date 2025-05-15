import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controller/geoFenceController.dart';

class HistoryScreen extends StatelessWidget {
  final GeofenceController controller = Get.find();

   HistoryScreen({super.key});




  @override
  Widget build(BuildContext context) {
    return GetBuilder<GeofenceController>(
      initState: (_){
        controller.getCurrentLocation();

      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(title: Text('Movement History')),
          body: Obx(() => Column(
            children: [
              SizedBox(
                height: 300,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: controller.history.isNotEmpty
                        ? LatLng(
                      controller.history.last.latitude,
                      controller.history.last.longitude,
                    )
                        : LatLng(double.parse(controller.currentLat??''), double.parse(controller.currentLong??'')), // Fallback
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: PolylineId('route'),
                      points: controller.history
                          .map((e) => LatLng(e.latitude, e.longitude))
                          .toList(),
                      color: Colors.blue,
                      width: 4,
                    ),
                  },
                  circles: controller.geofences
                      .map((geofence) => Circle(
                    circleId: CircleId(geofence.title),
                    center: LatLng(geofence.latitude, geofence.longitude),
                    radius: geofence.radius,
                    fillColor: Colors.blue.withOpacity(0.2),
                    strokeColor: Colors.blue,
                    strokeWidth: 1,
                  ))
                      .toSet(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.history.length,
                  itemBuilder: (context, index) {
                    final entry = controller.history[index];
                    return ListTile(
                      title: Text(entry.status),
                      subtitle: Text(
                          '${entry.timestamp}\n'
                              'Lat: ${entry.latitude.toStringAsFixed(4)}, '
                              'Lon: ${entry.longitude.toStringAsFixed(4)}'
                      ),
                    );
                  },
                ),
              ),
            ],
          )),
        );
      }
    );
  }
}
