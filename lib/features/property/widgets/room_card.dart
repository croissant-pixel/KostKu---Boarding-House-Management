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
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RoomDetailPage(room: room)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Foto Kamar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: room.photoUrl.isNotEmpty
                      ? Image.file(
                          File(room.photoUrl),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.room,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Info Kamar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nomor Kamar & Status
                      Row(
                        children: [
                          Text(
                            'Kamar ${room.number}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAvailable ? 'Available' : 'Occupied',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Tipe & Harga
                      Text(
                        room.type,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${_formatPrice(room.price)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tenant Info
                      Row(
                        children: [
                          Icon(
                            room.tenantName != null
                                ? Icons.person
                                : Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              room.tenantName ?? 'Belum ada penyewa',
                              style: TextStyle(
                                fontSize: 13,
                                color: room.tenantName != null
                                    ? Colors.grey[800]
                                    : Colors.grey[500],
                                fontStyle: room.tenantName != null
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol Inspeksi
                IconButton(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk format harga
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
