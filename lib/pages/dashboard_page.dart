import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../widgets/sensor_card.dart';
import '../services/mqtt_service.dart';
import 'about_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'connection_page.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late MqttService mqttService;
  int _selectedIndex = 0;
  int selectedPond = 0;

  final warningColor = const Color.fromARGB(255, 150, 0, 0);

  List<List<SensorCardData>> sensorData = [];
  List<List<String>> activeSensorKeysPerPond = [];
  List<String> pondStatus = [];

  final Map<String, SensorCardData> allSensors = {
    'suhu': SensorCardData(
      icon: FaIcon(FontAwesomeIcons.temperatureHigh),
      label: 'Suhu',
      value: '0.0 °C',
      color: Colors.teal,
    ),
    'do': SensorCardData(
      icon: FaIcon(FontAwesomeIcons.water),
      label: 'Kadar DO',
      value: '0.0 mg/L',
      color: Colors.teal,
    ),
    'ph': SensorCardData(
      icon: FaIcon(FontAwesomeIcons.flaskVial),
      label: 'pH Air',
      value: '0.0',
      color: Colors.teal,
    ),
    'berat_pakan': SensorCardData(
      icon: FaIcon(FontAwesomeIcons.weightHanging),
      label: 'Berat Pakan',
      value: '0.0 Kg',
      color: Colors.teal,
    ),
    'level_air': SensorCardData(
      icon: FaIcon(FontAwesomeIcons.arrowsDownToLine),
      label: 'Ketinggian Air',
      value: '0%',
      color: Colors.teal,
    ),
  };

  @override
  void initState() {
    super.initState();
    mqttService = MqttService();
    mqttService.onDataReceived = updateSensorData;
    mqttService.connect();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPonds();
    });
  }

  void _loadPonds() async {
    final prefs = await SharedPreferences.getInstance();
    final pondCount = prefs.getInt('pondCount') ?? 3;
    final sensorLists = prefs.getStringList('activeSensors');

    List<List<String>> loadedSensorKeys = [];

    if (sensorLists != null && sensorLists.length == pondCount) {
      loadedSensorKeys = sensorLists
          .map((s) => (jsonDecode(s) as List).map((e) => e.toString()).toList())
          .toList();
    } else {
      loadedSensorKeys =
          List.generate(pondCount, (_) => allSensors.keys.toList());
    }

    setState(() {
      activeSensorKeysPerPond = loadedSensorKeys;
      sensorData = List.generate(pondCount, (i) => _generateSensorList(i));
      pondStatus = List.generate(pondCount, (_) => 'Aman');
    });
  }

  void _savePondData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('pondCount', sensorData.length);
    prefs.setStringList(
      'activeSensors',
      activeSensorKeysPerPond.map((list) => jsonEncode(list)).toList(),
    );
  }

  List<SensorCardData> _generateSensorList(int pondIndex) {
    return activeSensorKeysPerPond[pondIndex]
        .map((key) => allSensors[key]!)
        .toList();
  }

  void updateSensorData(Map<String, dynamic> data) {
    setState(() {
      int pondIndex = (data['kolam'] ?? 1) - 1;
      if (pondIndex >= 0 && pondIndex < sensorData.length) {
        List<String> activeKeys = activeSensorKeysPerPond[pondIndex];

        for (int i = 0; i < activeKeys.length; i++) {
          final key = activeKeys[i];
          var sensor = sensorData[pondIndex][i];
          var value = data[key];
          bool isNormal = true;
          String formattedValue = '$value';

          switch (key) {
            case 'suhu':
              double val = double.tryParse('$value') ?? 0.0;
              isNormal = val >= 24 && val <= 32;
              formattedValue = '$val °C';
              break;
            case 'do':
              double val = double.tryParse('$value') ?? 0.0;
              isNormal = val >= 3 && val <= 8;
              formattedValue = '$val mg/L';
              break;
            case 'ph':
              double val = double.tryParse('$value') ?? 0.0;
              isNormal = val >= 6.5 && val <= 8.5;
              formattedValue = '$val';
              break;
            case 'berat_pakan':
              double val = double.tryParse('$value') ?? 0.0;
              isNormal = val >= 0.5;
              formattedValue = '$val Kg';
              break;
            case 'level_air':
              int val = int.tryParse('$value') ?? 0;
              isNormal = val >= 20;
              formattedValue = '$val%';
              break;
          }

          sensorData[pondIndex][i] = sensor.copyWith(
            value: formattedValue,
            color: isNormal ? Colors.teal : warningColor,
          );
        }

        bool isSafe =
            sensorData[pondIndex].every((s) => s.color != warningColor);
        pondStatus[pondIndex] = isSafe ? 'Aman' : 'Ada Masalah';
      }
    });
  }

  void _addPond() {
    setState(() {
      activeSensorKeysPerPond.add(allSensors.keys.toList());
      sensorData.add(_generateSensorList(activeSensorKeysPerPond.length - 1));
      pondStatus.add('Aman');
      selectedPond = sensorData.length - 1;
    });
    _savePondData();
  }

  void _deletePond(int index) {
    if (sensorData.length <= 1) return;
    setState(() {
      sensorData.removeAt(index);
      activeSensorKeysPerPond.removeAt(index);
      pondStatus.removeAt(index);
      selectedPond = 0;
    });
    _savePondData();
  }

  void _showSensorSettings() {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected =
            List.from(activeSensorKeysPerPond[selectedPond]);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Pilih Sensor yang Ditampilkan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: allSensors.keys.map((key) {
                  return CheckboxListTile(
                    value: tempSelected.contains(key),
                    title: Text(allSensors[key]!.label),
                    onChanged: (val) {
                      setStateDialog(() {
                        if (val == true) {
                          tempSelected.add(key);
                        } else {
                          tempSelected.remove(key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      activeSensorKeysPerPond[selectedPond] = tempSelected;
                      sensorData[selectedPond] =
                          _generateSensorList(selectedPond);
                    });
                    _savePondData();
                    Navigator.pop(context);
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> get _pages => [
        _buildDashboardView(),
        _buildConnectionPage(),
        AboutPage(mqttService: mqttService),
      ];

  Widget _buildDashboardView() {
    TextEditingController searchController = TextEditingController();
    List<int> filteredIndexes =
        List.generate(sensorData.length, (index) => index);

    return StatefulBuilder(
      builder: (context, setStateView) {
        void applySearch(String query) {
          setStateView(() {
            filteredIndexes = List.generate(sensorData.length, (index) => index)
                .where((index) => 'Kolam ${index + 1}'
                    .toLowerCase()
                    .contains(query.toLowerCase()))
                .toList();
          });
        }

        return sensorData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari Kolam...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: applySearch,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: _showSensorSettings,
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _addPond,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deletePond(selectedPond),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: ListView(
                        key: ValueKey<int>(selectedPond),
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...sensorData[selectedPond]
                              .map((data) => SensorCard(data: data))
                              .toList(),
                          SizedBox(height: 20),
                          _buildDetailTable(selectedPond),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: pondStatus[selectedPond] == 'Aman'
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pondStatus[selectedPond] == 'Aman'
                              ? Icons.check_circle
                              : Icons.warning,
                          color: pondStatus[selectedPond] == 'Aman'
                              ? Colors.teal
                              : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Status: ${pondStatus[selectedPond]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pondStatus[selectedPond] == 'Aman'
                                ? Colors.teal
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: const Color.fromARGB(255, 92, 231, 201),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filteredIndexes.map((index) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedPond = index),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selectedPond == index
                                          ? const Color(0xFF009688)
                                          : const Color(0xFF4DB6AC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Kolam ${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildDetailTable(int index) {
    final data = sensorData[index];
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                _buildTableCell('Sensor'),
                _buildTableCell('Nilai'),
                _buildTableCell('Status'),
              ],
            ),
            ...data.map((sensor) {
              bool isWarning = sensor.color == warningColor;
              return TableRow(
                children: [
                  _buildTableCell(sensor.label),
                  _buildTableCell(sensor.value),
                  _buildTableCell(
                    isWarning ? 'Tidak Stabil' : 'Normal',
                    color: isWarning ? warningColor : Colors.teal,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConnectionPage() {
    return ConnectionPage(
      mqttService: mqttService,
      onConnected: () => setState(() {}),
    );
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sensorData.isEmpty || selectedPond >= sensorData.length) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoring Kolam Ikan',
            style: TextStyle(color: Colors.white)),
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
            icon: FaIcon(FontAwesomeIcons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon:
                FaIcon(FontAwesomeIcons.wifi), // Ganti jadi ikon jaringan/wifi
            label: 'Connection',
          ),
          BottomNavigationBarItem(
            icon:
                FaIcon(FontAwesomeIcons.circleInfo), // Ganti jadi ikon "about"
            label: 'About',
          ),
        ],
      ),
    );
  }
}

class SensorCardData {
  final Widget icon;
  final String label;
  final String value;
  final Color color;

  SensorCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  SensorCardData copyWith({String? value, Color? color}) {
    return SensorCardData(
      icon: this.icon,
      label: this.label,
      value: value ?? this.value,
      color: color ?? this.color,
    );
  }
}
//  Done 19/04/2025
