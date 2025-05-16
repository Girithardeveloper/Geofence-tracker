import 'package:get/get.dart';
import '../controller/addGeoFenceController.dart';
import '../controller/geoFenceController.dart';
import '../controller/geoFenceHistoryController.dart';

class GlobalBinding extends Bindings {

  @override
  void dependencies() {
    Get.lazyPut(()=>GeofenceController(),fenix:true);
    Get.lazyPut(()=>AddGeoFenceController(),fenix:true);
    Get.lazyPut(()=>GeoFenceHistoryController(),fenix:true);
  }

}