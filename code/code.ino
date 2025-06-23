#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h> // Untuk sensor DHT (suhu)
#include <Wire.h> // Untuk sensor I2C (mungkin untuk pH atau DO)
#include "HX711.h" // Untuk load cell (berat pakan)

// Informasi Jaringan WiFi
const char* ssid = "nugra";
const char* password = "0987654321nugra";

// Informasi Broker MQTT
const char* mqtt_broker = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_topic = "nugra/data/kolam";
const char* mqtt_client_id = "ESP32Client-225510017"; // Client ID untuk ESP32

// Pin untuk Sensor
#define DHTPIN 4     // Pin untuk sensor DHT11/DHT22 (Suhu)
#define DHTTYPE DHT11   // Tipe sensor DHT (DHT11, DHT22, DHT21)
DHT dht(DHTPIN, DHTTYPE);

// Pin untuk Sensor DO (Asumsi: Sensor Analog)
const int do_pin = A0; // Contoh pin analog untuk sensor DO

// Pin untuk Sensor pH (Asumsi: Sensor Analog)
const int ph_pin = A1;  // Contoh pin analog untuk sensor pH

// Pin untuk Load Cell (HX711)
const int loadcell_dout_pin = 5;
const int loadcell_sck_pin = 6;
HX711 scale;
const float calibration_factor = 100.0; // Sesuaikan dengan kalibrasi load cell Anda

// Pin untuk Sensor Level Air (Asumsi: Sensor Ultrasonik - contoh pin)
const int trigPin = 17;
const int echoPin = 16;
const long pingTravelTime = 20000; // Batas waktu untuk pembacaan ultrasonik (dalam mikrodetik)

WiFiClient espClient;
PubSubClient client(espClient);

// Fungsi untuk terhubung ke WiFi
void connectWiFi() {
  Serial.println("Menghubungkan ke WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi terhubung");
}

// Fungsi untuk terhubung ke Broker MQTT
void connectMQTT() {
  client.setServer(mqtt_broker, mqtt_port);
  while (!client.connected()) {
    Serial.println("Menghubungkan ke MQTT...");
    if (client.connect(mqtt_client_id)) {
      Serial.println("Terhubung ke MQTT");
    } else {
      Serial.print("Gagal terhubung ke MQTT, rc=");
      Serial.print(client.state());
      Serial.println(" Coba lagi dalam 5 detik");
      delay(5000);
    }
  }
}

// Fungsi untuk membaca data sensor suhu
float readTemperature() {
  return dht.readTemperature();
}

// Fungsi untuk membaca data sensor kelembaban (tidak digunakan dalam kode Flutter, tapi sensor DHT biasanya memiliki ini)
float readHumidity() {
  return dht.readHumidity();
}

// Fungsi untuk membaca data sensor DO (asumsi sensor analog)
float readDO() {
  int raw_do = analogRead(do_pin);
  // Konversi nilai analog ke kadar DO (perlu dikalibrasi sesuai sensor Anda)
  // Ini hanyalah contoh konversi sederhana
  float do_value = map(raw_do, 0, 4095, 0, 15.0); // Skala 0-15 mg/L
  return do_value;
}

// Fungsi untuk membaca data sensor pH (asumsi sensor analog)
float readPH() {
  int raw_ph = analogRead(ph_pin);
  // Konversi nilai analog ke pH (perlu dikalibrasi sesuai sensor Anda)
  // Ini hanyalah contoh konversi sederhana dengan rentang pH 0-14
  float ph_value = map(raw_ph, 0, 4095, 0, 14.0);
  return ph_value;
}

// Fungsi untuk membaca data dari load cell (berat pakan)
float readFeedWeight() {
  if (scale.is_ready()) {
    scale.set_scale(calibration_factor);
    float weight = scale.get_units();
    return max(0.0f, weight); // Memastikan berat tidak negatif
  } else {
    Serial.println("HX711 tidak ditemukan.");
    return 0.0;
  }
}

// Fungsi untuk membaca level air menggunakan sensor ultrasonik
float readWaterLevel() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, pingTravelTime);

  if (duration > 0 && duration < pingTravelTime) {
    // Kecepatan suara sekitar 343 m/s atau 29 mikrosekon per centimeter
    float distanceCm = duration / 29.0 / 2; // Dibagi 2 karena gelombang bolak-balik
    // Asumsikan ketinggian maksimum air adalah 50 cm (ini perlu disesuaikan)
    float waterLevelPercentage = max(0.0f, min(100.0f, (1 - (distanceCm / 50.0)) * 100));
    return waterLevelPercentage;
  } else {
    Serial.println("Gagal membaca sensor ultrasonik.");
    return 0.0;
  }
}

void setup() {
  Serial.begin(115200);

  // Inisialisasi sensor DHT
  dht.begin();

  // Inisialisasi load cell HX711
  scale.begin(loadcell_dout_pin, loadcell_sck_pin);
  scale.set_gain(128); // Gain factor dapat bervariasi (128, 64, 32)
  scale.tare();       // Set offset awal ke nol

  // Inisialisasi sensor ultrasonik
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  // Hubungkan ke WiFi
  connectWiFi();

  // Hubungkan ke Broker MQTT
  connectMQTT();
}

void loop() {
  if (!client.connected()) {
    connectMQTT();
  }
  client.loop();

  // Baca data sensor
  float suhu = readTemperature();
  float do_val = readDO();
  float ph_val = readPH();
  float berat_pakan = readFeedWeight();
  float level_air = readWaterLevel();

  // Buat payload JSON
  String payload = "{\"kolam\": 1,"; // Asumsi data untuk kolam 1
  payload += "\"suhu\": " + String(suhu) + ",";
  payload += "\"do\": " + String(do_val) + ",";
  payload += "\"ph\": " + String(ph_val) + ",";
  payload += "\"berat_pakan\": " + String(berat_pakan) + ",";
  payload += "\"level_air\": " + String(level_air) + "}";

  Serial.println("Mengirim data: " + payload);

  // Kirim data ke broker MQTT
  client.publish(mqtt_topic, payload.c_str());

  // Tunda pengiriman data (misalnya setiap 5 detik)
  delay(5000);
}