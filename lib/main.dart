import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_app/routes/routes.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/screens/auth/splash_screen.dart';
import 'package:uber_app/screens/driver/dashboard_screen_driver.dart';
import 'package:uber_app/screens/driver/driver_module.dart';
import 'package:uber_app/screens/home/navigation_screen.dart';
import 'package:uber_app/screens/user_module/user_module.dart';
import 'package:uber_app/screens/user_module/user_module_firebase.dart';
import 'package:uber_app/services/preference_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   final firebaseService = FirebaseService();
//   await firebaseService.initializeNotifications();

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }

Widget? initialRoute;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final bool isLoggedIn = await PreferenceService.isLoggedIn();
  
  if (isLoggedIn) {
    final details = await PreferenceService.getUserDetails();
    final String? userType = details['userType'];
    final String? userId = details['userId'];

    if (userId != null && userType != null) {
      if (userType == 'driver') {
        initialRoute = NavigationScreen(userId: userId);
      } else if (userType == 'user' || userType == 'company') {
        initialRoute = TruckDeliveryApp(userId: userId);
      } else {

        initialRoute = const SplashScreen();
       
        await PreferenceService.clearPreferences();
      }
    } else {
     
      initialRoute = const SplashScreen();
      await PreferenceService.clearPreferences();
    }
  } else {
    
    initialRoute = const SplashScreen();
  }


  final firebaseService = FirebaseService();
  await firebaseService.initializeNotifications();

  runApp(MyApp(initialRoute: initialRoute!));
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;
  
  const MyApp({super.key, required this.initialRoute});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Use the determined widget as the home screen
      home: initialRoute, 
    );
  }
}
