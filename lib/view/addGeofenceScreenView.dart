import 'package:flutter/material.dart';
import 'package:geofence_tracker/constants/colorConstants.dart';
import 'package:geofence_tracker/constants/fontConstants.dart';
import 'package:geofence_tracker/globalWidgets/textWidget.dart';
import 'package:geofence_tracker/view/homeView.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/addGeoFenceController.dart';
import '../controller/geoFenceController.dart';
import '../model/geoFenceModel.dart';

class AddGeofenceScreen extends StatelessWidget {

  final Geofence? geofence;
  final int? index;


  AddGeofenceScreen({super.key, this.geofence, this.index}) ;


  final _formKey = GlobalKey<FormState>();

  AddGeoFenceController addGeoFenceController = Get.find<AddGeoFenceController>();

  GeofenceController geofenceController = Get.find<GeofenceController>();


  @override
  Widget build(BuildContext context) {

    ///Screen Size
    Size screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: ()async{
        Get.back();
        return false;
      },
      child: GetBuilder<AddGeoFenceController>(
        initState: (_){
          geofenceController.requestPermissions().then((_) => geofenceController.startLocationTracking());
          addGeoFenceController.titleController.text = geofence?.title ?? '';
          addGeoFenceController.radiusController.text = geofence?.radius.toString() ?? '';
          addGeoFenceController.selectedLocation.value = geofence != null
              ? LatLng(geofence!.latitude, geofence!.longitude)
              : null;
          addGeoFenceController.getInitialPosition();
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
                      highlightColor: Colors.transparent,  // Remove the highlight shadow
                      splashColor: Colors.transparent,
                      hoverColor:  Colors.transparent,
                    onTap: (){
                      Get.back();
                    },
                      child: Icon(Icons.arrow_back,color: ColorConstants.secondaryColor,size: 26,)),
                  SizedBox(width:screenSize.width*0.04 ,),
                  ReusableTextWidget( text: geofence == null ? 'Add Geofence' : 'Edit Geofence',fontFamily: FontConstants.fontFamily,color: ColorConstants.secondaryColor,fontSize: 20,fontWeight: FontWeight.w700,),
                ],
              ),
            ),
            body: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding:  EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableTextWidget( text: 'Title :',fontFamily: FontConstants.fontFamily,color: ColorConstants.primaryColor,fontSize: 20,textAlign: TextAlign.center,fontWeight: FontWeight.bold,),
                      SizedBox(height: screenSize.height*0.02,),
                      TextFormField(
                        controller: controller.titleController,
                        cursorColor: ColorConstants.primaryColor,
                        style: TextStyle(color: ColorConstants.blackColor,fontFamily: FontConstants.fontFamily,fontSize: 14,fontWeight: FontWeight.normal),
                        decoration: InputDecoration(
                            labelText: 'Title',
                          labelStyle: TextStyle(color: ColorConstants.primaryColor,fontFamily: FontConstants.fontFamily),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide:  const BorderSide(
                              color: ColorConstants.lightGrey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide:  BorderSide(
                              color: ColorConstants.lightGrey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide:  BorderSide(
                              color: ColorConstants.lightGrey,
                              width: 1.0,
                            ),
                          ),

                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                       SizedBox(height: screenSize.height*0.02),
                      ReusableTextWidget( text: 'Location :',fontFamily: FontConstants.fontFamily,color: ColorConstants.primaryColor,fontSize: 20,textAlign: TextAlign.center,fontWeight: FontWeight.bold,),
                      SizedBox(height: screenSize.height*0.02,),
                      SizedBox(
                        height: screenSize.height*0.40,
                        child: Obx(() {
                          return Container(
                            decoration: BoxDecoration(color: ColorConstants.secondaryColor,borderRadius: BorderRadius.circular(10),border: Border.all(color: ColorConstants.grey)),

                            child: ClipRRect(
                              borderRadius:  BorderRadius.circular(10),
                              child: GoogleMap(
                                buildingsEnabled: true,
                                compassEnabled: true,
                                initialCameraPosition: CameraPosition(
                                  target: controller.initialPosition.value,
                                  zoom: 15,
                                ),
                                onMapCreated: (GoogleMapController mapController) {
                                  controller.googleMapController.value = mapController;
                                  if ( controller.selectedLocation.value != null) {
                                    mapController.animateCamera(
                                      CameraUpdate.newLatLng( controller.selectedLocation.value!),
                                    );
                                  }
                                },
                                onTap: (LatLng location) {
                                  controller.selectedLocation.value = location;
                                },
                                markers:  controller.selectedLocation.value != null
                                    ? {
                                  Marker(
                                    markerId: const MarkerId('selected'),
                                    position:  controller.selectedLocation.value!,
                                  ),
                                }
                                    : {},
                              ),
                            ),
                          );
                        }),
                      ),
                       SizedBox(height: screenSize.height*0.02),
                      ReusableTextWidget( text: 'Location Radius :',fontFamily: FontConstants.fontFamily,color: ColorConstants.primaryColor,fontSize: 20,textAlign: TextAlign.center,fontWeight: FontWeight.bold,),
                      SizedBox(height: screenSize.height*0.02,),
                      TextFormField(
                        cursorColor: ColorConstants.primaryColor,
                        controller:  controller.radiusController,
                        style: TextStyle(color: ColorConstants.blackColor,fontFamily: FontConstants.fontFamily,fontSize: 14,fontWeight: FontWeight.normal),
                        decoration:  InputDecoration(
                            labelText: 'Radius (meters)',
                          labelStyle: TextStyle(color: ColorConstants.primaryColor,fontFamily: FontConstants.fontFamily),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide:  const BorderSide(
                              color: ColorConstants.lightGrey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide:  BorderSide(
                              color: ColorConstants.lightGrey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            borderSide:  BorderSide(
                              color: ColorConstants.lightGrey,
                              width: 1.0,
                            ),
                          ),


                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a radius';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                       SizedBox(height: screenSize.height*0.06),
                      InkWell(
                        highlightColor: Colors.transparent,  // Remove the highlight shadow
                        splashColor: Colors.transparent,
                        hoverColor:  Colors.transparent,
                        onTap: () {
                          if (_formKey.currentState!.validate() &&
                              controller.selectedLocation.value != null) {
                            final newGeofence = Geofence(
                              title:  controller.titleController.text,
                              latitude:  controller.selectedLocation.value!.latitude,
                              longitude:  controller.selectedLocation.value!.longitude,
                              radius: double.parse( controller.radiusController.text),
                            );

                            if (geofence == null) {
                              geofenceController.addGeofence(newGeofence);
                            } else {
                              geofenceController.updateGeofence(index!, newGeofence);
                            }
                            Get.back();
                          } else if ( controller.selectedLocation.value == null) {
                            Get.snackbar('Error', 'Please select a location on the map');
                          }
                        },
                        child: Container(
                          width: screenSize.width,
                          padding: EdgeInsets.only(top: screenSize.height*0.01,bottom: screenSize.height*0.01),
                          decoration: BoxDecoration(color: ColorConstants.secondaryColor,borderRadius: BorderRadius.circular(10),border: Border.all(color: ColorConstants.grey)),

                          child: ReusableTextWidget( text:geofence == null ? 'Add' : 'Update',fontFamily: FontConstants.fontFamily,color: ColorConstants.primaryColor,fontSize: 20,textAlign: TextAlign.center,fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
