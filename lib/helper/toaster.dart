import 'package:fluttertoast/fluttertoast.dart';
import '../constants/colorConstants.dart';

class Toast{
  static void showToast(String message){
    Fluttertoast.showToast(
        msg: message,
        textColor: ColorConstants.secondaryColor,
        timeInSecForIosWeb: 1,
        webShowClose: true,
        backgroundColor: ColorConstants.grey,
        gravity: ToastGravity.TOP_RIGHT,
        fontSize: 15.0,
    );
  }
}