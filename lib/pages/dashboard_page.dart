import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/sensor_card.dart';
import '../services/mqtt_service.dart';

class DashboardPage extends StatefulWidget {
  final MqttService mqttService;

  const DashboardPage({required this.mqttService, super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedPond = 0;
  final warningColor = const Color.fromARGB(255, 150, 0, 0);
  List<List<SensorCardData>> sensorData = [];
  List<List<String>> activeSensorKeysPerPond = [];
  List<String> pondStatus = [];
  List<StreamSubscription<QuerySnapshot>> _firestoreSubscriptions = [];
  bool _isLoading = true; // Track loading state

  final Map<String, SensorCardData> allSensors = {
    'suhu': SensorCardData(
      icon: const FaIcon(FontAwesomeIcons.temperatureHigh),
      label: 'Suhu',
      value: '0.0 °C',
      color: Colors.teal,
    ),
    'do': SensorCardData(
      icon: const FaIcon(FontAwesomeIcons.water),
      label: 'Kadar DO',
      value: '0.0 mg/L',
      color: Colors.teal,
    ),
    'ph': SensorCardData(
      icon: const FaIcon(FontAwesomeIcons.flaskVial),
      label: 'pH Air',
      value: '0.0',
      color: Colors.teal,
    ),
    'berat_pakan': SensorCardData(
      icon: const FaIcon(FontAwesomeIcons.weightHanging),
      label: 'Berat Pakan',
      value: '0.0 Kg',
      color: Colors.teal,
    ),
    'level_air': SensorCardData(
      icon: const FaIcon(FontAwesomeIcons.arrowsDownToLine),
      label: 'Ketinggian Air',
      value: '0%',
      color: Colors.teal,
    ),
  };

  @override
  void initState() {
    super.initState();
    widget.mqttService.onDataReceived = updateSensorData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPonds();
    });
  }

  void _loadPonds() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final pondCount = prefs.getInt('pondCount') ?? 3;
      final sensorLists = prefs.getStringList('activeSensors');

      List<List<String>> loadedSensorKeys = [];

      if (sensorLists != null && sensorLists.length == pondCount) {
        loadedSensorKeys = sensorLists
            .map((s) =>
                (jsonDecode(s) as List).map((e) => e.toString()).toList())
            .toList();
      } else {
        loadedSensorKeys =
            List.generate(pondCount, (_) => allSensors.keys.toList());
      }

      setState(() {
        activeSensorKeysPerPond = loadedSensorKeys;
        sensorData = List.generate(pondCount, (i) => _generateSensorList(i));
        pondStatus = List.generate(pondCount, (_) => 'Aman');
        _isLoading = false;
      });

      // Load initial data and set up listeners
      _loadLatestData(selectedPond);
      _listenToFirestore();
    } catch (e) {
      print('Error loading ponds: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kolam: $e')),
      );
    }
  }

  void _listenToFirestore() {
    // Cancel existing subscriptions
    for (var subscription in _firestoreSubscriptions) {
      subscription.cancel();
    }
    _firestoreSubscriptions.clear();

    // Set up listeners for each pond
    for (int i = 0; i < sensorData.length; i++) {
      final subscription = FirebaseFirestore.instance
          .collection('ponds')
          .doc('pond_${i + 1}')
          .collection('sensor_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          updateSensorData({
            'kolam': i + 1,
            'suhu': data['suhu']?.toString() ?? '0',
            'do': data['do']?.toString() ?? '0',
            'ph': data['ph']?.toString() ?? '0',
            'berat_pakan': data['berat_pakan']?.toString() ?? '0',
            'level_air': data['level_air']?.toString() ?? '0',
          }, fromFirestore: true);
        }
      }, onError: (e) {
        print('Error listening to Firestore for pond ${i + 1}: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data real-time: $e')),
        );
      });
      _firestoreSubscriptions.add(subscription);
    }
  }

  void _loadLatestData(int pondIndex) async {
    if (pondIndex < 0 || pondIndex >= sensorData.length) return;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ponds')
          .doc('pond_${pondIndex + 1}')
          .collection('sensor_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        updateSensorData({
          'kolam': pondIndex + 1,
          'suhu': data['suhu']?.toString() ?? '0',
          'do': data['do']?.toString() ?? '0',
          'ph': data['ph']?.toString() ?? '0',
          'berat_pakan': data['berat_pakan']?.toString() ?? '0',
          'level_air': data['level_air']?.toString() ?? '0',
        }, fromFirestore: true);
      }
    } catch (e) {
      print('Error loading latest data for pond ${pondIndex + 1}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data terbaru: $e')),
      );
    }
  }

  void _savePondData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('pondCount', sensorData.length);
      prefs.setStringList(
        'activeSensors',
        activeSensorKeysPerPond.map((list) => jsonEncode(list)).toList(),
      );
    } catch (e) {
      print('Error saving pond data: $e');
    }
  }

  List<SensorCardData> _generateSensorList(int pondIndex) {
    return activeSensorKeysPerPond[pondIndex]
        .map((key) => allSensors[key]!)
        .toList();
  }

  void updateSensorData(Map<String, dynamic> data,
      {bool fromFirestore = false}) {
    setState(() {
      int pondIndex = (data['kolam'] ?? 1) - 1;
      if (pondIndex >= 0 && pondIndex < sensorData.length) {
        List<String> activeKeys = activeSensorKeysPerPond[pondIndex];

        for (int i = 0; i < activeKeys.length; i++) {
          final key = activeKeys[i];
          var sensor = sensorData[pondIndex][i];
          var value = data[key] ?? '0';
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
    _listenToFirestore();
    _loadLatestData(selectedPond);
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
    _listenToFirestore();
    _loadLatestData(selectedPond);
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
              title: const Text('Pilih Sensor yang Ditampilkan'),
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
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      activeSensorKeysPerPond[selectedPond] = tempSelected;
                      sensorData[selectedPond] =
                          _generateSensorList(selectedPond);
                    });
                    _savePondData();
                    _loadLatestData(selectedPond);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
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
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: applySearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showSensorSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addPond,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePond(selectedPond),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
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
                    const SizedBox(height: 20),
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
                  const SizedBox(width: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filteredIndexes.map((index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPond = index;
                                _loadLatestData(index);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedPond == index
                                    ? const Color(0xFF009688)
                                    : const Color(0xFF4DB6AC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Kolam ${index + 1}',
                                style: const TextStyle(
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
    // Fixed syntax error
    final data = sensorData[index];
    return Card(
      elevation: 1,
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

  @override
  void dispose() {
    for (var subscription in _firestoreSubscriptions) {
      subscription.cancel();
    }
    widget.mqttService.disconnect(); // Ensure MQTT cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboardView();
  }
}

class SensorCardData {
  final Widget icon;
  final String label;
  final String value;
  final Color color;

  const SensorCardData({
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
