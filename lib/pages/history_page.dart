import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/mqtt_service.dart';

class HistoryPage extends StatefulWidget {
  final MqttService mqttService;

  HistoryPage({required this.mqttService});

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
    final prefs = await SharedPreferences.getInstance();
    String key = 'history_pond_${pondIndex + 1}';
    List<String>? history = prefs.getStringList(key);
    if (history != null) {
      setState(() {
        historyData = history
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList()
            .reversed
            .toList();
      });
    } else {
      setState(() {
        historyData = [];
      });
    }
  }

  void _deleteHistory(int pondIndex) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'history_pond_${pondIndex + 1}';
    await prefs.remove(key);
    setState(() {
      if (selectedPond == pondIndex) {
        historyData = [];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Histori Kolam ${pondIndex + 1} dihapus')),
    );
  }

  Widget _buildHistoryTable() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: historyData.isEmpty
            ? Center(child: Text('Belum ada data histori'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Waktu')),
                    DataColumn(label: Text('Suhu')),
                    DataColumn(label: Text('DO')),
                    DataColumn(label: Text('pH')),
                    DataColumn(label: Text('Berat Pakan')),
                    DataColumn(label: Text('Level Air')),
                  ],
                  rows: historyData.map((entry) {
                    final data = entry['data'] as Map<String, dynamic>;
                    final timestamp = entry['timestamp'];
                    return DataRow(cells: [
                      DataCell(Text(timestamp.toString().substring(0, 19))),
                      DataCell(Text(data['suhu']?.toString() ?? '-')),
                      DataCell(Text(data['do']?.toString() ?? '-')),
                      DataCell(Text(data['ph']?.toString() ?? '-')),
                      DataCell(Text(data['berat_pakan']?.toString() ?? '-')),
                      DataCell(Text(data['level_air']?.toString() ?? '-')),
                    ]);
                  }).toList(),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Hapus Histori'),
                      content: Text(
                          'Apakah Anda yakin ingin menghapus histori untuk Kolam ${selectedPond + 1}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _deleteHistory(selectedPond);
                            Navigator.pop(context);
                          },
                          child: Text('Hapus'),
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
