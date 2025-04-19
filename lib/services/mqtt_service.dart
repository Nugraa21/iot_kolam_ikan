import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MqttService {
  late MqttServerClient client;
  String broker = 'broker.emqx.io';
  int port = 1883;
  String topic = 'nugra/data/kolam';
  String clientId = '225510017';

  Function(Map<String, dynamic>)? onDataReceived;

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
//  Done 19/04/2025
