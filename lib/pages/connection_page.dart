import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mqtt_service.dart';

class ConnectionPage extends StatefulWidget {
  final MqttService mqttService;
  final VoidCallback onConnected;

  const ConnectionPage({
    Key? key,
    required this.mqttService,
    required this.onConnected,
  }) : super(key: key);

  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController brokerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController topicController = TextEditingController();

  String _statusMessage = 'Belum terkoneksi';

  @override
  void initState() {
    super.initState();
    _loadSavedConfiguration();
  }

  Future<void> _loadSavedConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      brokerController.text =
          prefs.getString('mqtt_broker') ?? widget.mqttService.broker;
      portController.text = prefs.getInt('mqtt_port')?.toString() ??
          widget.mqttService.port.toString();
      topicController.text =
          prefs.getString('mqtt_topic') ?? widget.mqttService.topic;
    });
  }

  Future<void> _saveConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_broker', brokerController.text);
    await prefs.setInt(
      'mqtt_port',
      int.tryParse(portController.text) ?? 1883,
    );
    await prefs.setString('mqtt_topic', topicController.text);
  }

  @override
  void dispose() {
    brokerController.dispose();
    portController.dispose();
    topicController.dispose();
    super.dispose();
  }

  Future<void> _connectToBroker() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (mounted) {
          setState(() {
            _statusMessage = '🔄 Menyambungkan...';
          });
        }

        widget.mqttService.setConfiguration(
          broker: brokerController.text,
          port: int.tryParse(portController.text) ?? 1883,
          topic: topicController.text,
        );

        await _saveConfiguration();

        await widget.mqttService.connect();

        if (mounted) {
          setState(() {
            _statusMessage = '✅ Terhubung ke MQTT broker';
          });

          widget.onConnected();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusMessage = '❌ Gagal terhubung: $e';
          });

          Fluttertoast.showToast(
            msg: "Gagal terhubung: $e",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 14,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE0F7FA),
                        radius: 36,
                        child: Icon(Icons.wifi, size: 40, color: Colors.teal),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Koneksi MQTT',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Silakan masukkan detail koneksi',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                          controller: brokerController,
                          label: 'Broker MQTT',
                          icon: Icons.cloud),
                      const SizedBox(height: 18),
                      _buildTextField(
                          controller: portController,
                          label: 'Port',
                          isNumber: true,
                          icon: Icons.numbers),
                      const SizedBox(height: 18),
                      _buildTextField(
                          controller: topicController,
                          label: 'Topik',
                          icon: Icons.message),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _connectToBroker,
                          icon: const Icon(Icons.link),
                          label: const Text('Hubungkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: _statusMessage.contains('Gagal')
                              ? Colors.red
                              : Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label tidak boleh kosong';
        }
        if (isNumber && int.tryParse(value.trim()) == null) {
          return '$label harus berupa angka';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6F8FA),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        labelStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
