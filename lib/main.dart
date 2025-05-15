import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofence_tracker/globalWidgets/globalBindings.dart';
import 'package:geofence_tracker/helper/logger.dart';
import 'package:geofence_tracker/view/homeView.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize SharedPreferences
  await SharedPreferences.getInstance();

  /// Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // Use launcher icon
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  /// Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            initialBinding: GlobalBinding(),
            useInheritedMediaQuery: true,
            title: 'Geofence Tracker',
            darkTheme: ThemeData.dark(),
            initialRoute: '/',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            getPages: [

            ],
            defaultTransition: Transition.rightToLeft,

            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key,});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {


  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }



  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }


  ///Flutter LifeCycleState
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        logger.i("App is in the foreground (Resumed)");
        break;
      case AppLifecycleState.inactive:
        logger.i("App is inactive");
        break;
      case AppLifecycleState.paused:
        logger.i("App is in the background (Paused)");
        break;
      case AppLifecycleState.detached:
        logger.i("App is detached");
        break;
      case AppLifecycleState.hidden:
        logger.i("App is in hidden state"); // ✅ fixed
        break;
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister as observer
    super.dispose();
  }
}


