import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colorConstants.dart';
import '../constants/fontConstants.dart';
import '../controller/geoFenceController.dart';
import '../globalWidgets/textWidget.dart';
import 'addGeofenceScreenView.dart';
import 'historyView.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GeofenceController geofenceController = Get.find<GeofenceController>();


  @override
  Widget build(BuildContext context) {
    ///Screen Size
    Size screenSize = MediaQuery.of(context).size;

    return GetBuilder<GeofenceController>(
      initState: (_){
        geofenceController.requestPermissions().then((_) => geofenceController.startLocationTracking());
      },
      builder: (controller) {
        return Scaffold(
       backgroundColor: Colors.grey[100],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: ColorConstants.primaryColor,
            title: ReusableTextWidget( text: 'Geofence Tracker',fontFamily: FontConstants.fontFamily,color: ColorConstants.secondaryColor,fontSize: 20,fontWeight: FontWeight.w700,),
            actions: [
              IconButton(
                icon: Icon(Icons.history,size: 30,color: ColorConstants.secondaryColor,),
                onPressed: () => Get.to(() => HistoryScreen()),
              ),
              SizedBox(width: screenSize.width*0.02,)
            ],
          ),
          body: Obx(() => controller.geoFences.isEmpty?Column(
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
          ):ListView.builder(
            padding: EdgeInsets.only(top: screenSize.height*0.02,left: screenSize.width*0.02,right: screenSize.width*0.02,bottom: screenSize.height*0.02),
            itemCount: controller.geoFences.length,
            itemBuilder: (context, index) {
              final geofence = controller.geoFences[index];
              return Card(
                color: ColorConstants.secondaryColor,
                child: ListTile(
                  title: ReusableTextWidget(text:geofence.title,fontWeight: FontWeight.bold,fontSize: 18,fontFamily: FontConstants.fontFamily,color: ColorConstants.primaryColor,maxLines: 1,),
                  subtitle: ReusableTextWidget(
                   text:  'Lat: ${geofence.latitude.toStringAsFixed(4)}, '
                        'Long: ${geofence.longitude.toStringAsFixed(4)}\n'
                        'Radius: ${geofence.radius} m',
                    fontSize: 16,
                    fontFamily: FontConstants.fontFamily,
                    color: ColorConstants.blackColor,
                    // maxLines: 2,

                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        geofence.isInside ? Icons.location_on : Icons.location_off,
                        color: geofence.isInside ? Colors.green : ColorConstants.grey,
                        size: 26,
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_calendar_rounded,size: 26,color: ColorConstants.primaryColor,),
                        onPressed: () => Get.to(() => AddGeofenceScreen(geofence: geofence, index: index)),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete,color: Colors.red,size: 26,),
                        onPressed: () => controller.deleteGeofence(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          )),
          floatingActionButton: FloatingActionButton(
            backgroundColor: ColorConstants.primaryColor,
            onPressed: () => Get.to(() => AddGeofenceScreen()),
            child: Icon(Icons.add,color: ColorConstants.secondaryColor,size: 26,),
          ),
        );
      }
    );
  }
}