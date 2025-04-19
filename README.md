# 📱 Aplikasi Mobile Monitoring Kolam Ikan Menggunakan MQTT

Aplikasi ini dibuat menggunakan Flutter untuk memantau kondisi kolam ikan secara real-time menggunakan ESP32 dan protokol MQTT. Data dari sensor dikirim ke broker MQTT dan ditampilkan dalam aplikasi ini.

## 👨‍💻 Tim Pengembang
- Ludang Prasetyo Nugroho - 225510017  
- Ibnu Hibban Dzulfikri - 225510007  
- Muhamaad Fadrian Samhar - 225510005  

Program Studi Teknik Komputer - S1  
Universitas Teknologi Digital Indonesia – 2025

---

## 🔧 Tools & Teknologi

### Aplikasi:
- **Visual Studio Code**: Code editor
- **Flutter**: Framework aplikasi mobile
- **Android Studio**: Emulator dan APK builder

### Perangkat IoT:
- **ESP32**: Mikrokontroler utama
- **Sensor**: DS18B20 / DHT11 / Sensor pH (opsional)
- **Indikator**: LED / Buzzer (opsional)
- **Broker MQTT**: HiveMQ / Mosquitto
- **Internet / Wi-Fi**
- **Arduino IDE**: Untuk pemrograman ESP32

---

## 📦 Library Flutter yang Digunakan

| Package                 | Kegunaan |
|------------------------|----------|
| `mqtt_client`          | Koneksi ke MQTT broker |
| `font_awesome_flutter` | Menampilkan ikon FontAwesome |
| `line_icons`           | Ikon tambahan |
| `wifi_iot`             | Koneksi ke WiFi |
| `fluttertoast`         | Notifikasi Toast |
| `shared_preferences`   | Menyimpan data lokal |
| `animations`           | Efek animasi UI |

---

## 📁 Struktur Folder & File


```
lib/
├── models/
│   └── sensor_data.dart           // Berisi model data sensor (misalnya suhu, pH, DO)
│
├── pages/
│   ├── about_page.dart            // Halaman informasi tentang aplikasi atau tim
│   ├── connection_page.dart       // Halaman untuk koneksi (kemungkinan MQTT atau jaringan)
│   └── dashboard_page.dart        // Halaman utama yang menampilkan dashboard kolam
│
├── services/
│   └── mqtt_service.dart          // Layanan untuk mengatur koneksi dan komunikasi MQTT
│
├── widgets/
│   └── sensor_card.dart           // Widget untuk menampilkan informasi sensor dalam bentuk kartu
│
└── main.dart                      // Entry point aplikasi, konfigurasi routing dan tema
```


---

## 🧠 Penjelasan Kode Penting

### 🔌 `mqtt_service.dart`
- Kelas utama untuk mengatur koneksi ke MQTT broker
- Client ID: `flutter_kolam_ikan`
- Konfigurasi broker, port, dan topic
- Menangani pesan yang diterima dan parsing JSON
- Fungsi:
  - `connect()`: Mulai koneksi
  - `setConfig()`: Atur ulang konfigurasi dari UI
  - `onDataReceived`: Callback saat data diterima

### 🌐 `connection_page.dart`
- Halaman untuk memasukkan:
  - Alamat broker
  - Port (default: 1883)
  - Topic (contoh: `nugra/data/kolam`)
- Menyimpan konfigurasi ke `SharedPreferences`
- Tombol "Hubungkan" untuk memulai koneksi ke broker

### 📊 `dashboard_page.dart`
- Menyimpan jumlah kolam & sensor aktif ke `SharedPreferences`
- Menampilkan data berdasarkan `data['kolam']` yang dikirim melalui MQTT
- Mendukung beberapa kolam dari satu topik
- Fungsi penting:
  - `_loadPonds()`: Muat data kolam saat aplikasi dibuka
  - `_savePondData()`: Simpan perubahan kolam
  - `_onDataReceived(data)`: Tampilkan data sesuai kolam

---

## 🖼️ Tampilan Aplikasi

- Dashboard monitoring kolam
- Menu koneksi ke broker (bisa diubah)
- Halaman About pengembang
- Menu tambah dan hapus kolam
- Tampilan data sensor (suhu, pH, dll.)
- Tabel dan popup info sederhana

---

## 🧪 Testing

- Gunakan **MQTT X** untuk testing
- Masukkan:
  - Broker: `broker.hivemq.com` (contoh)
  - Port: `1883`
  - Topik: `nugra/data/kolam`
- Kirim JSON seperti:
```json
{
  "kolam": 1,
  "suhu": 24.4,
  "do": 6,
  "ph": 7.7,
  "berat_pakan": 0.9,
  "level_air": 82
}
```

