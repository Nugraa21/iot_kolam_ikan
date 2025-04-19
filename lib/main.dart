import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';

void main() => runApp(MonitoringKolamIkanApp());

class MonitoringKolamIkanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashbord Monitoring',
      theme: ThemeData.light(),
      home: DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SensorCardData {
  final Widget icon;
  final String label;
  final String value;
  final Color color;

  _SensorCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
//  Done 19/04/2025
