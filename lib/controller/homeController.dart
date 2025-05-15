import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/logger.dart';

class HomeController extends GetxController{

  ///Location Coordinates
  String latitude = '';
  String longitude = '';

  Timer? timer;

  var currentLocations;


  ///Current Location



  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();


  }

}



