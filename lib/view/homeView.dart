import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/geoFenceController.dart';
import 'addGeofenceScreenView.dart';
import 'historyView.dart';

class HomeScreen extends StatelessWidget {


   HomeScreen({super.key});

   final GeofenceController controller = Get.put(GeofenceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geofence Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Get.to(() => HistoryScreen()),
          ),
        ],
      ),
      body: Obx(() => ListView.builder(
        itemCount: controller.geofences.length,
        itemBuilder: (context, index) {
          final geofence = controller.geofences[index];
          return ListTile(
            title: Text(geofence.title),
            subtitle: Text(
                'Lat: ${geofence.latitude.toStringAsFixed(4)}, '
                    'Lon: ${geofence.longitude.toStringAsFixed(4)}\n'
                    'Radius: ${geofence.radius}m'
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  geofence.isInside ? Icons.check_circle : Icons.cancel,
                  color: geofence.isInside ? Colors.green : Colors.red,
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => Get.to(() => AddGeofenceScreen(geofence: geofence, index: index)),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => controller.deleteGeofence(index),
                ),
              ],
            ),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddGeofenceScreen()),
        child: Icon(Icons.add),
      ),
    );
  }
}