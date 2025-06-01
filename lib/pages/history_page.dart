import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mqtt_service.dart';

class HistoryPage extends StatefulWidget {
  final MqttService mqttService;

  const HistoryPage({required this.mqttService, super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int selectedPond = 0;
  List<Map<String, dynamic>> historyData = [];
  List<int> pondIndexes = [];

  @override
  void initState() {
    super.initState();
    _loadPonds();
  }

  void _loadPonds() async {
    final prefs = await SharedPreferences.getInstance();
    final pondCount = prefs.getInt('pondCount') ?? 3;
    setState(() {
      pondIndexes = List.generate(pondCount, (index) => index);
      _loadHistory(selectedPond);
    });
  }

  void _loadHistory(int pondIndex) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ponds')
          .doc('pond_${pondIndex + 1}')
          .collection('sensor_data')
          .orderBy('timestamp', descending: true)
          .limit(10) // Reduced to 10 for simplicity
          .get();

      setState(() {
        historyData = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error loading history from Firestore: $e');
      setState(() {
        historyData = [];
      });
    }
  }

  void _deleteHistory(int pondIndex) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ponds')
          .doc('pond_${pondIndex + 1}')
          .collection('sensor_data')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        if (selectedPond == pondIndex) {
          historyData = [];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Histori Kolam ${pondIndex + 1} dihapus')),
      );
    } catch (e) {
      print('Error deleting history: $e');
    }
  }

  Widget _buildTrendChart(int pondIndex) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Suhu Kolam ${pondIndex + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: historyData.length * 40.0,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= historyData.length ||
                                  value.toInt() < 0) {
                                return const Text('');
                              }
                              return Text(
                                historyData[value.toInt()]['timestamp']
                                    .toString()
                                    .substring(11, 16),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      barGroups: historyData.asMap().entries.map((entry) {
                        int index = entry.key;
                        double value =
                            double.tryParse(entry.value['suhu'] ?? '0') ?? 0;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: Colors.teal,
                              width: 15,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    return historyData.isEmpty
        ? const Center(child: Text('Belum ada data histori'))
        : Column(
            children: [
              _buildTrendChart(selectedPond),
              Expanded(
                child: ListView.builder(
                  itemCount: historyData.length,
                  itemBuilder: (context, index) {
                    final entry = historyData[index];
                    final timestamp = entry['timestamp'];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waktu: ${timestamp.toString().substring(0, 19)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Suhu: ${entry['suhu'] ?? '-'}'),
                            Text('DO: ${entry['do'] ?? '-'}'),
                            Text('pH: ${entry['ph'] ?? '-'}'),
                            Text('Berat Pakan: ${entry['berat_pakan'] ?? '-'}'),
                            Text('Level Air: ${entry['level_air'] ?? '-'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    // Fixed: Changed Context to BuildContext
    return Column(
      children: [
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
                    children: pondIndexes.map((index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedPond = index;
                            _loadHistory(index);
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
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Histori'),
                      content: Text(
                          'Apakah Anda yakin ingin menghapus histori untuk Kolam ${selectedPond + 1}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _deleteHistory(selectedPond);
                            Navigator.pop(context);
                          },
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildHistoryTable(),
          ),
        ),
      ],
    );
  }
}
