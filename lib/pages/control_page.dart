import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';

class ControlPage extends StatefulWidget {
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final TextEditingController _suhuMinController = TextEditingController();
  final TextEditingController _suhuMaxController = TextEditingController();
  final TextEditingController _phMinController = TextEditingController();
  final TextEditingController _phMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _saveValues() async {
    final prefs = await SharedPreferences.getInstance();

    double? suhuMin = double.tryParse(_suhuMinController.text);
    double? suhuMax = double.tryParse(_suhuMaxController.text);
    double? phMin = double.tryParse(_phMinController.text);
    double? phMax = double.tryParse(_phMaxController.text);

    if (suhuMin == null || suhuMax == null || phMin == null || phMax == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan nilai yang valid!')),
      );
      return;
    }

    // Menyimpan nilai ke SharedPreferences
    await prefs.setString('suhu_min', _suhuMinController.text);
    await prefs.setString('suhu_max', _suhuMaxController.text);
    await prefs.setString('ph_min', _phMinController.text);
    await prefs.setString('ph_max', _phMaxController.text);

    // Log untuk memastikan nilai tersimpan
    print("Suhu Min: ${_suhuMinController.text}");
    print("Suhu Max: ${_suhuMaxController.text}");
    print("pH Min: ${_phMinController.text}");
    print("pH Max: ${_phMaxController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pengaturan disimpan!')),
    );
  }

  void _loadValues() async {
    final prefs = await SharedPreferences.getInstance();

    // Memuat nilai yang telah disimpan
    String suhuMin = prefs.getString('suhu_min') ?? '26.0';
    String suhuMax = prefs.getString('suhu_max') ?? '30.0';
    String phMin = prefs.getString('ph_min') ?? '6.5';
    String phMax = prefs.getString('ph_max') ?? '8.5';

    // Log untuk memastikan nilai dimuat
    print("Loaded suhu min: $suhuMin");
    print("Loaded suhu max: $suhuMax");
    print("Loaded pH min: $phMin");
    print("Loaded pH max: $phMax");

    _suhuMinController.text = suhuMin;
    _suhuMaxController.text = suhuMax;
    _phMinController.text = phMin;
    _phMaxController.text = phMax;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kontrol Data Sensor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildInputField('Suhu Minimum (°C)', _suhuMinController),
            _buildInputField('Suhu Maksimum (°C)', _suhuMaxController),
            _buildInputField('pH Minimum', _phMinController),
            _buildInputField('pH Maksimum', _phMaxController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveValues,
              child: Text('Simpan Pengaturan'),
            )
          ],
        ),
      ),
    );
  }

  // Widget untuk input field suhu atau pH
  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Format input untuk angka desimal
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+\.?[0-9]*$')),
        ],
      ),
    );
  }
}
