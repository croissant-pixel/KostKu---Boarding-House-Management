import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KostKu Dashboard')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _menuCard(
            icon: Icons.home_work,
            title: 'Kamar',
            onTap: () {
              // TODO: Room List Page
            },
          ),
          _menuCard(
            icon: Icons.people,
            title: 'Penyewa',
            onTap: () {
              // TODO: Tenant List Page (MODULE 2)
            },
          ),
          _menuCard(
            icon: Icons.receipt_long,
            title: 'Pembayaran',
            onTap: () {
              // TODO: Payment Page (MODULE 3)
            },
          ),
          _menuCard(icon: Icons.bar_chart, title: 'Laporan', onTap: () {}),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
