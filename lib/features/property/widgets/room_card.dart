import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kostku/features/property/pages/room_inspection_page.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../pages/room_form_page.dart';
import '../pages/room_detail_page.dart';
import '../providers/room_provider.dart';

class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final isAvailable = room.status == RoomStatus.available;

    return Dismissible(
      key: ValueKey(room.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RoomFormPage(room: room)),
          );
          return false;
        }

        // Delete
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Kamar'),
            content: Text('Yakin ingin menghapus kamar ${room.number}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<RoomProvider>().deleteRoom(room.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamar berhasil dihapus')),
          );
        }
      },

      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RoomDetailPage(room: room)),
            );
          },
          leading: room.photoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(room.photoUrl),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.room),
          title: Text('Kamar ${room.number}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipe: ${room.type}'),
              Text('Harga: Rp ${room.price}'),
              const SizedBox(height: 6),
              // Tenant aktif
              room.tenantName != null
                  ? Text('Penyewa: ${room.tenantName}')
                  : const Text('Belum ada penyewa'),
              const SizedBox(height: 6),
              Chip(
                label: Text(room.status.name),
                backgroundColor: isAvailable ? Colors.green : Colors.red,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Inspeksi Kamar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomInspectionPage(room: room),
                ),
              );
            },
          )
        ),
      ),
    );
  }
}
