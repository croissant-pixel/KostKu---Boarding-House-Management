import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../property/models/room_model.dart';
import '../../property/providers/room_provider.dart';
import '../models/tenant_model.dart';
import '../providers/tenant_provider.dart';

class TenantDetailPage extends StatefulWidget {
  final Tenant tenant;
  const TenantDetailPage({super.key, required this.tenant});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  Room? tenantRoom;

  void initState() {
    super.initState();
    final rooms = context.read<RoomProvider>().rooms;
    try {
      tenantRoom = rooms.firstWhere((r) => r.id == widget.tenant.roomId);
    } catch (e) {
      tenantRoom = null;
    }
  }

  DateTime? getContractEndDate(Tenant tenant) {
    return tenant.checkOutDate;
  }

  int getRemainingDays(DateTime endDate) {
    return endDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final isCheckedIn = tenant.checkInDate != null;
    final endDate = getContractEndDate(tenant);
    final remainingDays = endDate != null ? getRemainingDays(endDate) : null;

    Color? contractColor;
    String? contractText;

    if (remainingDays != null) {
      if (remainingDays <= 0) {
        contractColor = Colors.red;
        contractText = '⚠️ Kontrak sudah habis';
      } else if (remainingDays <= 7) {
        contractColor = Colors.orange;
        contractText = '⏳ Kontrak habis dalam $remainingDays hari';
      } else {
        contractColor = Colors.green;
        contractText = '✅ Kontrak aktif ($remainingDays hari tersisa)';
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Detail Tenant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto profil tenant
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: tenant.profilePhoto != null
                  ? FileImage(File(tenant.profilePhoto!))
                  : null,
              child: tenant.profilePhoto == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Info tenant
          Text('Nama: ${tenant.name}', style: const TextStyle(fontSize: 16)),
          Text('HP: ${tenant.phone}', style: const TextStyle(fontSize: 16)),
          Text('Email: ${tenant.email}', style: const TextStyle(fontSize: 16)),
          if (tenant.emergencyContact != null &&
              tenant.emergencyContact!.isNotEmpty)
            Text(
              'Kontak Darurat: ${tenant.emergencyContact}',
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 16),
          // Info kamar
          if (tenantRoom != null) ...[
            Text(
              'Kamar: ${tenantRoom!.number} (${tenantRoom!.type})',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Harga: Rp ${tenantRoom!.price}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Fasilitas: ${tenantRoom!.facilities}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
          const SizedBox(height: 16),
          // Status kontrak
          if (isCheckedIn && contractText != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: contractColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: contractColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: contractColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contractText,
                      style: TextStyle(
                        color: contractColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Tanggal check-in/out
          if (isCheckedIn) ...[
            Text(
              'Check-in: ${tenant.checkInDate!.toLocal().toString().split(' ')[0]}',
            ),
            Text(
              'Check-out: ${tenant.checkOutDate!.toLocal().toString().split(' ')[0]}',
            ),
            const SizedBox(height: 24),
            // Tombol checkout
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Checkout Tenant'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Checkout Tenant'),
                    content: const Text('Yakin ingin checkout tenant ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;

                await context.read<TenantProvider>().checkOutTenant(
                  tenantId: tenant.id!,
                  roomId: tenant.roomId!,
                );
                context.read<RoomProvider>().fetchRooms();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tenant berhasil checkout')),
                );
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }
}
