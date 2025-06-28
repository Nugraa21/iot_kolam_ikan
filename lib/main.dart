// import 'package:flutter/material.dart';
// import 'pages/dashboard_page.dart';

// void main() => runApp(MonitoringKolamIkanApp());

// class MonitoringKolamIkanApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dashbord Monitoring',
//       theme: ThemeData.light(),
//       home: DashboardPage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class _SensorCardData {
//   final Widget icon;
//   final String label;
//   final String value;
//   final Color color;

//   _SensorCardData({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.color,
//   });
// }
//  Done 19/04/2025
// ================================= EDIT
// import 'package:flutter/material.dart';
// import 'pages/bottom_navigation.dart';

// void main() => runApp(MonitoringKolamIkanApp());

// class MonitoringKolamIkanApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dashboard Monitoring',
//       theme: ThemeData.light(),
//       home: BottomNavigation(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // File yang dihasilkan oleh FlutterFire CLI
// import 'pages/bottom_navigation.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(MonitoringKolamIkanApp());
// }

// class MonitoringKolamIkanApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Dashboard Monitoring',
//       theme: ThemeData.light(),
//       home: BottomNavigation(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/bottom_navigation.dart';

void main() {
  runApp(MonitoringKolamIkanApp());
}

class MonitoringKolamIkanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error initializing Firebase: ${snapshot.error}'),
                ),
              ),
            );
          }
          return MaterialApp(
            title: 'Dashboard Monitoring',
            theme: ThemeData.light(),
            home: BottomNavigation(),
            debugShowCheckedModeBanner: false,
          );
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}
