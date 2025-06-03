import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:monitoring_kolam_ikan/pages/dashboard_page.dart';
import 'package:monitoring_kolam_ikan/pages/about_page.dart';
import 'package:monitoring_kolam_ikan/pages/connection_page.dart';
import 'package:monitoring_kolam_ikan/pages/history_page.dart';
import 'package:monitoring_kolam_ikan/services/mqtt_service.dart';
import 'package:animations/animations.dart';

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;
  late MqttService mqttService;

  @override
  void initState() {
    super.initState();
    mqttService = MqttService();
    mqttService
        .connect(); // Pastikan koneksi MQTT dimulai saat aplikasi dimulai
  }

  @override
  void dispose() {
    mqttService.disconnect(); // Putuskan koneksi saat aplikasi ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardPage(mqttService: mqttService),
      ConnectionPage(
          mqttService: mqttService, onConnected: () => setState(() {})),
      AboutPage(mqttService: mqttService),
      HistoryPage(mqttService: mqttService),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monitoring Kolam Ikan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(221, 0, 0, 0),
      ),
      body: PageTransitionSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (child, animation, secondaryAnimation) =>
            SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.chartLine),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.wifi),
            label: 'Connection',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.circleInfo),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
