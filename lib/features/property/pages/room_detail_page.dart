import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kostku/features/tenant/models/tenant_model.dart';
import 'package:kostku/features/tenant/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../providers/room_provider.dart';
import 'package:collection/collection.dart';

class RoomDetailPage extends StatefulWidget {
  final Room room;

  const RoomDetailPage({super.key, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final ImagePicker _picker = ImagePicker();
  List<String> photos = [];

  Future<void> _addPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      await context.read<RoomProvider>().addRoomPhoto(
        widget.room.id!,
        image.path,
      );
      setState(() {
        photos = context.read<RoomProvider>().roomPhotos[widget.room.id!]!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto dokumentasi berhasil ditambahkan')),
      );
    }
  }

  Future<void> _removePhoto(int index) async {
    final removed = photos[index];
    await context.read<RoomProvider>().removeRoomPhoto(
      widget.room.id!,
      removed,
    );
    setState(() {
      photos = context.read<RoomProvider>().roomPhotos[widget.room.id!]!;
    });
  }

  DateTime? getContractEndDate(Tenant tenant) {
    if (tenant.checkInDate == null) return null;

    return DateTime(
      tenant.checkInDate!.year,
      tenant.checkInDate!.month + tenant.durationMonth,
      tenant.checkInDate!.day,
    );
  }

  int getRemainingDays(DateTime endDate) {
    return endDate.difference(DateTime.now()).inDays;
  }



  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final tenantProvider = context.watch<TenantProvider>();

    final room = roomProvider.rooms.firstWhere((r) => r.id == widget.room.id);
  
    final Tenant? tenant = tenantProvider.tenants.firstWhereOrNull(
    (t) => t.roomId == room.id && t.checkOutDate == null,
  );

    context.watch<TenantProvider>().getTenantByRoom(room.id!);

    final isAvailable = room.status == RoomStatus.available;

    return Scaffold(
      appBar: AppBar(title: Text('Kamar ${room.number}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto utama kamar → readonly
          room.photoUrl.isNotEmpty
              ? Image.file(
                  File(room.photoUrl),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.room,
                    size: 100,
                    color: Colors.white70,
                  ),
                ),
          const SizedBox(height: 16),

          // Info kamar
          Text(
            'Tipe: ${room.type}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Harga: Rp ${room.price}',
            style: const TextStyle(fontSize: 16),
          ),
          // STATUS KAMAR
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontSize: 16)),
              Chip(
                label: Text(room.isAvailable ? 'Available' : 'Occupied'),
                backgroundColor: room.isAvailable ? Colors.green : Colors.red,
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================= TENANT AKTIF =================
          const Text(
            'Penyewa Aktif',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          tenant == null
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Belum ada penyewa',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            tenant.profilePhoto != null &&
                                tenant.profilePhoto!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: FileImage(
                                  File(tenant.profilePhoto!),
                                ),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(tenant.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HP: ${tenant.phone}'),
                            Text(
                              'Check-in: ${tenant.checkInDate?.toLocal().toString().split(' ')[0]}',
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      // ========= TOMBOL CHECK OUT =========
                      if (tenant != null) ...[
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Checkout Penyewa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Checkout Penyewa'),
                                content: const Text(
                                  'Yakin ingin checkout penyewa ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Checkout'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            await context.read<TenantProvider>().checkOutTenant(
                              tenantId: tenant.id!,
                              roomId: widget.room.id!,
                            );

                            await context.read<RoomProvider>().fetchRooms();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Penyewa berhasil checkout'),
                              ),
                            );

                            Navigator.pop(context);
                          },
                        ),
                      ]
                    ],
                  ),
                ),
          const SizedBox(height: 12),
          const Text(
            'Fasilitas:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(room.facilities, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),

          // Gallery foto dokumentasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Foto Dokumentasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: _addPhoto,
                tooltip: 'Tambah Foto Dokumentasi',
              ),
            ],
          ),
          const SizedBox(height: 8),
          photos.isEmpty
              ? const Text('Belum ada foto dokumentasi')
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(photo),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (tenant != null) ...[
            const SizedBox(height: 8),

            Builder(
              builder: (context) {
                final endDate = getContractEndDate(tenant);
                if (endDate == null) return const SizedBox();

                final remainingDays = getRemainingDays(endDate);

                Color color;
                String text;

                if (remainingDays <= 0) {
                  color = Colors.red;
                  text = '⚠️ Kontrak sudah habis';
                } else if (remainingDays <= 7) {
                  color = Colors.orange;
                  text = '⏳ Kontrak habis dalam $remainingDays hari';
                } else {
                  color = Colors.green;
                  text = '✅ Kontrak aktif ($remainingDays hari tersisa)';
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }
}
