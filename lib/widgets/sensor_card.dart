import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';

class SensorCard extends StatelessWidget {
  final SensorCardData data;

  const SensorCard({Key? key, required this.data}) : super(key: key);

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: data.color),
            SizedBox(width: 8),
            Text(data.label),
          ],
        ),
        content: Text(
          'Nilai saat ini: ${data.value}\n\nSensor ini menampilkan data ${data.label.toLowerCase()} secara real-time.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
          ],
          border: Border.all(color: data.color.withOpacity(0.3), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon di dalam bulatan
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: data.icon,
            ),
            const SizedBox(width: 16.0),
            // Teks
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//  Done 19/04/2025
