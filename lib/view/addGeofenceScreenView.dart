import 'package:flutter/material.dart';
import 'package:geofence_tracker/helper/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controller/geoFenceController.dart';
import '../model/geoFenceModel.dart';

class AddGeofenceScreen extends StatefulWidget {
  final Geofence? geofence;
  final int? index;

  AddGeofenceScreen({this.geofence, this.index});

  @override
  _AddGeofenceScreenState createState() => _AddGeofenceScreenState();
}

class _AddGeofenceScreenState extends State<AddGeofenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final GeofenceController controller = Get.find();
  late TextEditingController _titleController;
  late TextEditingController _radiusController;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  Position? resultPosition;
  
  
  var currentLat;
  var currentLong;

  @override
  void initState() {
    getCurrentLocation();
    super.initState();
    _titleController = TextEditingController(text: widget.geofence?.title ?? '');
    _radiusController = TextEditingController(
      text: widget.geofence?.radius.toString() ?? '',
    );
    _selectedLocation = widget.geofence != null
        ? LatLng(widget.geofence!.latitude, widget.geofence!.longitude)
        : null;


  }

  ///Google Map
  getCurrentLocation()async{
    resultPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentLat = resultPosition?.latitude.toString();
    currentLong = resultPosition?.longitude.toString();
    setState(() {

    });
    logger.i('currentLatinlocation $currentLat');
    logger.i('currentLonglocation $currentLong');
  }


  @override
  Widget build(BuildContext context) {
    logger.i('currentLataddgeofence $currentLat');
    return Scaffold(
      appBar: AppBar(title: Text(widget.geofence == null ? 'Add Geofence' : 'Edit Geofence')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: GoogleMap(

                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? LatLng(double.parse(currentLat??''), double.parse(currentLong??'')), // Fallback
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onTap: (LatLng location) {
                      setState(() {
                        _selectedLocation = location;
                      });
                    },
                    markers: _selectedLocation != null
                        ? {
                      Marker(
                        markerId: MarkerId('selected'),
                        position: _selectedLocation!,
                      ),
                    }
                        : {},
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _radiusController,
                  decoration: InputDecoration(labelText: 'Radius (meters)'),
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
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedLocation != null) {
                      final geofence = Geofence(
                        title: _titleController.text,
                        latitude: _selectedLocation!.latitude,
                        longitude: _selectedLocation!.longitude,
                        radius: double.parse(_radiusController.text),
                      );

                      if (widget.geofence == null) {
                        controller.addGeofence(geofence);
                      } else {
                        controller.updateGeofence(widget.index!, geofence);
                      }
                      Get.back();
                    } else if (_selectedLocation == null) {
                      Get.snackbar('Error', 'Please select a location on the map');
                    }
                  },
                  child: Text(widget.geofence == null ? 'Add' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _radiusController.dispose();
    super.dispose();
  }
}