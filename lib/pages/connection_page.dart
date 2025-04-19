// ... import tetap sama
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
  final TextEditingController clientIdController = TextEditingController();

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
      clientIdController.text =
          prefs.getString('mqtt_client_id') ?? widget.mqttService.clientId;
    });
  }

  Future<void> _saveConfiguration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_broker', brokerController.text);
    await prefs.setInt('mqtt_port', int.tryParse(portController.text) ?? 1883);
    await prefs.setString('mqtt_topic', topicController.text);
    await prefs.setString('mqtt_client_id', clientIdController.text);
  }

  Future<void> _connectToBroker() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _statusMessage = '🔄 Menyambungkan...';
        });

        widget.mqttService.setConfiguration(
          broker: brokerController.text,
          port: int.tryParse(portController.text) ?? 1883,
          topic: topicController.text,
          clientId: clientIdController.text,
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
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        labelStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF3F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              shadowColor: Colors.teal.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.teal,
                        radius: 36,
                        child: Icon(Icons.settings_ethernet,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Pengaturan Koneksi MQTT',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Masukkan detail broker, port, topik, dan client ID.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 30),
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
                          icon: Icons.topic),
                      const SizedBox(height: 18),
                      _buildTextField(
                          controller: clientIdController,
                          label: 'Client ID',
                          icon: Icons.perm_identity),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _connectToBroker,
                          icon: const Icon(Icons.link, size: 24),
                          label: const Text(
                            'Hubungkan',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            elevation: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: _statusMessage.contains('Gagal')
                              ? Colors.red
                              : Colors.teal,
                          fontWeight: FontWeight.w600,
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
}
//  Done 19/04/2025
