import 'package:geofence_tracker/controller/homeController.dart';
import 'package:get/get.dart';

class GlobalBinding extends Bindings {

  @override
  void dependencies() {
    Get.lazyPut(()=>HomeController(),fenix:true);
  }

}