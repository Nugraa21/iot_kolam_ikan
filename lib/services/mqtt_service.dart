import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MqttService {
  late MqttServerClient client;
  String broker = 'broker.emqx.io';
  int port = 1883;
  String topic = 'nugra/data/kolam';
  String clientId = '225510017';
  Function(Map<String, dynamic>)? onDataReceived;

  // Inisialisasi Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void setConfiguration({
    required String broker,
    required int port,
    required String topic,
    required String clientId,
  }) {
    this.broker = broker;
    this.port = port;
    this.topic = topic;
    this.clientId = clientId;
  }

  Future<void> connect() async {
    client = MqttServerClient.withPort(broker, clientId, port);
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('willtopic')
        .withWillMessage('Connection Closed')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('MQTT Connection Error: $e');
      disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT Connected');
      client.subscribe(topic, MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? event) {
        final recMess = event![0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Payload received: $payload');

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            onDataReceived?.call(decoded);
            _saveToFirestore(decoded); // Simpan ke Firestore
          } else {
            print('Decoded data is not a JSON object');
          }
        } catch (e) {
          print('Error decoding JSON: $e');
        }
      });
    } else {
      print('MQTT Connection Failed - Status: ${client.connectionStatus}');
    }
  }

  // Fungsi untuk menyimpan data ke Firestore
  void _saveToFirestore(Map<String, dynamic> data) async {
    int pondIndex = (data['kolam'] ?? 1) - 1;
    String timestamp = DateTime.now().toIso8601String();

    try {
      await _firestore
          .collection('ponds')
          .doc('pond_${pondIndex + 1}')
          .collection('sensor_data')
          .add({
        'timestamp': timestamp,
        'suhu': data['suhu']?.toString() ?? '0.0',
        'do': data['do']?.toString() ?? '0.0',
        'ph': data['ph']?.toString() ?? '0.0',
        'berat_pakan': data['berat_pakan']?.toString() ?? '0.0',
        'level_air': data['level_air']?.toString() ?? '0',
      });
      print('Data saved to Firestore: $data');
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }

  void disconnect() {
    client.disconnect();
  }

  void onConnected() {
    print('Connected to MQTT broker');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
  }
}
