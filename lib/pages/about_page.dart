import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/mqtt_service.dart';

class AboutPage extends StatelessWidget {
  final MqttService mqttService;

  AboutPage({required this.mqttService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTitleSection(),
          _buildProfileExpansionCard(
            icon: Icons.person,
            name: 'Ludang Prasetyo',
            role: 'Developer',
            nim: '225510017',
            tugas: 'Mengembangkan aplikasi IoT',
            profilePicture: AssetImage('assets/ludang.jpg'),
            email: 'ludang.prasetyo@students.utdi.ac.id',
            github: 'https://github.com/Nugraa21',
            skill: 'Programming dan editing video',
          ),
          _buildProfileExpansionCard(
            icon: Icons.person,
            name: 'Ibnu Hibban ',
            role: 'UI Designer',
            nim: '225510007',
            tugas: 'Menangani IoT dan sensor',
            profilePicture: AssetImage('assets/ibnu.jpg'),
            email: 'Ibnu.Hibban.Dzulfikri@students.utdi.ac.id',
            github: '-----',
            skill: 'IoT, Sensor Integration, Embedded Systems',
          ),
          _buildProfileExpansionCard(
            icon: Icons.person,
            name: 'Muhammad Fadrian',
            role: 'Tester & Dokumentasi',
            nim: '225510005',
            tugas: 'Melakukan testing dan dokumentasi',
            profilePicture: AssetImage('assets/fadrian.jpg'),
            email: 'Muhamaad.fadrian@students.utdi.ac.id',
            github: 'https://github.com/fadrian',
            skill: 'Testing, Documentation, Quality Assurance',
          ),
          const SizedBox(height: 20),
          _buildExtraInfo(),
          const SizedBox(height: 20),
          _buildSensorTable(),
          const SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 48, color: Colors.teal),
        SizedBox(height: 10),
        Text('Tentang Aplikasi & Tim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfileExpansionCard({
    required IconData icon,
    required String name,
    required String role,
    required String nim,
    required String tugas,
    required ImageProvider profilePicture,
    required String email,
    required String github,
    required String skill,
  }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: CircleAvatar(radius: 28, backgroundImage: profilePicture),
          title: Text(name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text(role, style: TextStyle(color: Colors.grey[700])),
          children: [
            _buildInfoRow(Icons.badge, 'NIM', nim),
            _buildInfoRow(Icons.task, 'Tugas', tugas),
            _buildInfoRow(Icons.build, 'Keahlian', skill),
            _buildInfoRow(Icons.email, 'Email', email),
            _buildInfoRow(FontAwesomeIcons.github, 'GitHub', github),
            const SizedBox(height: 10),
            const Text('Mahasiswa UTDI',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text(
                'Universitas Teknologi Digital Indonesia (UTDI) adalah perguruan tinggi berbasis teknologi digital di Yogyakarta.'),
            const Text('Website: https://www.utdi.ac.id',
                style: TextStyle(color: Colors.blue)),
            const Text(
                'Alamat: Jl. Janti, Karang Jambe, Banguntapan, Bantul, Yogyakarta'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildExtraInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tentang Aplikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Aplikasi ini dibuat untuk memonitor kondisi kolam ikan secara real-time menggunakan teknologi IoT. '
              'Dengan bantuan sensor dan MQTT sebagai protokol komunikasi, pengguna dapat melihat suhu, pH, '
              'dan status air langsung dari aplikasi ini.',
            ),
            const SizedBox(height: 15),
            Text('Teknologi yang Digunakan:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Flutter (Mobile Framework)'),
            const Text('• MQTT Protocol (Komunikasi Sensor)'),
            const Text('• Sensor pH, Suhu, dan Ketinggian Air'),
            const Text('• NodeMCU / ESP32 sebagai pengendali utama'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTable() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensor yang Harus Dijaga Stabil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Table(
              border: TableBorder.all(
                  color: const Color.fromARGB(255, 141, 141, 141)),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  decoration:
                      BoxDecoration(color: Colors.deepPurple.withOpacity(0.2)),
                  children: [
                    _buildTableCell('Sensor'),
                    _buildTableCell('Rentang Ideal'),
                    _buildTableCell('Fungsi'),
                  ],
                ),
                _buildTableRow('Suhu', '26°C - 30°C',
                    'Mengukur suhu air kolam. Penting untuk kenyamanan dan pertumbuhan ikan.'),
                _buildTableRow('pH Air', '6.5 - 8.5',
                    'Mengukur tingkat keasaman atau kebasaan air.'),
                _buildTableRow('Ketinggian Air', '> 70%',
                    'Menjaga volume air kolam tetap optimal.'),
                _buildTableRow('Kadar DO', '5.0 - 8.0 mg/L',
                    'Menunjukkan kadar oksigen terlarut dalam air.'),
                _buildTableRow('Berat Pakan', '1 - 2 Kg',
                    'Menampilkan jumlah pakan yang tersedia.'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String sensor, String range, String function) {
    return TableRow(
      children: [
        _buildTableCell(sensor),
        _buildTableCell(range),
        _buildTableCell(function),
      ],
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: TextStyle(fontSize: 13)),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.grey.shade400),
        Text('Aplikasi IoT - 2025',
            style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text('Dibuat oleh Tim Developer NUGRA21',
            style: TextStyle(fontSize: 14, color: Colors.grey[800])),
      ],
    );
  }
}
//  Done//  Done 19/04/2025
