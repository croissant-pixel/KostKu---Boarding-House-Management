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

  @override
  void initState() {
    super.initState();
    // Load data saat page dibuka
    Future.microtask(() {
      context.read<RoomProvider>().fetchRooms();
      context.read<TenantProvider>().fetchTenants();
    });
  }

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
      setState(() {}); // Refresh UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto dokumentasi berhasil ditambahkan'),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(String photoUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Yakin ingin menghapus foto ini?'),
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

    if (confirm == true) {
      await context.read<RoomProvider>().removeRoomPhoto(
        widget.room.id!,
        photoUrl,
      );
      setState(() {}); // Refresh UI
    }
  }

  int getRemainingDays(DateTime endDate) {
    return endDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final tenantProvider = context.watch<TenantProvider>();

    // Ambil room terbaru dari provider
    final room = roomProvider.rooms.firstWhereOrNull(
      (r) => r.id == widget.room.id,
    );

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room Not Found')),
        body: const Center(child: Text('Room tidak ditemukan')),
      );
    }

    // Ambil tenant aktif dari room ini
    final Tenant? tenant = tenantProvider.tenants.firstWhereOrNull(
      (t) => t.roomId == room.id,
    );

    // Ambil photos dari roomPhotos map
    final photos = roomProvider.roomPhotos[room.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Kamar ${room.number}'),
        actions: [
          // Tombol Edit Room (opsional)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Kamar',
            onPressed: () {
              // Navigate ke room form page untuk edit
              // Navigator.push(context, MaterialPageRoute(builder: (_) => RoomFormPage(room: room)));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. FOTO UTAMA KAMAR
          _buildMainPhoto(room),
          const SizedBox(height: 16),

          // 2. INFORMASI KAMAR
          _buildRoomInfo(room),
          const SizedBox(height: 16),

          // 3. FASILITAS
          _buildFacilities(room),
          const SizedBox(height: 16),

          // 4. FOTO DOKUMENTASI
          _buildPhotoGallery(photos),
          const SizedBox(height: 16),

          // 5. PENYEWA AKTIF
          _buildTenantInfo(tenant, room),
        ],
      ),
    );
  }

  // 1. Foto Utama Kamar
  Widget _buildMainPhoto(Room room) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: room.photoUrl.isNotEmpty
            ? Image.file(
                File(room.photoUrl),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                height: 220,
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.room, size: 80, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Foto kamar belum ditambahkan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // 2. Informasi Kamar
  Widget _buildRoomInfo(Room room) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Informasi Kamar',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.meeting_room, 'Nomor Kamar', room.number),
            _buildInfoRow(Icons.category, 'Tipe', room.type),
            _buildInfoRow(
              Icons.payments,
              'Harga',
              'Rp ${_formatPrice(room.price)}/bulan',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.circle, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Status:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: room.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room.isAvailable ? 'Available' : 'Occupied',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. Fasilitas
  Widget _buildFacilities(Room room) {
    final facilities = room.facilities.split(',').map((e) => e.trim()).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Fasilitas',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: facilities.map((facility) {
                return Chip(
                  avatar: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(facility),
                  backgroundColor: Colors.blue,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Foto Dokumentasi
  Widget _buildPhotoGallery(List<String> photos) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Foto Dokumentasi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Colors.blue),
                  onPressed: _addPhoto,
                  tooltip: 'Tambah Foto',
                ),
              ],
            ),
            const Divider(height: 24),
            photos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.photo, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada foto dokumentasi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return GestureDetector(
                        onTap: () {
                          // Show full image
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.file(File(photo)),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tutup'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
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
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(photo),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // 5. Penyewa Aktif
  Widget _buildTenantInfo(Tenant? tenant, Room room) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Penyewa Aktif',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            tenant == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada penyewa',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Tenant Profile
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage:
                                tenant.profilePhoto != null &&
                                    tenant.profilePhoto!.isNotEmpty
                                ? FileImage(File(tenant.profilePhoto!))
                                : null,
                            child:
                                tenant.profilePhoto == null ||
                                    tenant.profilePhoto!.isEmpty
                                ? const Icon(Icons.person, size: 35)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14),
                                    const SizedBox(width: 4),
                                    Text(tenant.phone),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        tenant.email,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Check-in/out dates
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.login,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                const Text('Check-in: '),
                                Text(
                                  tenant.checkInDate
                                          ?.toLocal()
                                          .toString()
                                          .split(' ')[0] ??
                                      '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (tenant.checkOutDate != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.logout,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Check-out: '),
                                  Text(
                                    tenant.checkOutDate!
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Contract status
                      if (tenant.checkOutDate != null) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final endDate = tenant.checkOutDate!;
                            final remainingDays = getRemainingDays(endDate);

                            Color color;
                            String text;
                            IconData icon;

                            if (remainingDays <= 0) {
                              color = Colors.red;
                              text = 'Kontrak sudah habis';
                              icon = Icons.warning;
                            } else if (remainingDays <= 7) {
                              color = Colors.orange;
                              text = 'Kontrak habis dalam $remainingDays hari';
                              icon = Icons.timer;
                            } else {
                              color = Colors.green;
                              text =
                                  'Kontrak aktif ($remainingDays hari tersisa)';
                              icon = Icons.check_circle;
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, color: color),
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
                      ],

                      const SizedBox(height: 16),

                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Checkout Penyewa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Checkout Penyewa'),
                                content: Text(
                                  'Yakin ingin checkout ${tenant.name}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Checkout'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            // Show loading
                            if (mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            try {
                              await context
                                  .read<TenantProvider>()
                                  .checkOutTenant(
                                    tenantId: tenant.id!,
                                    roomId: room.id!,
                                  );

                              await context.read<RoomProvider>().fetchRooms();

                              // Close loading
                              if (mounted) Navigator.pop(context);

                              // Close detail page
                              if (mounted) Navigator.pop(context);

                              // Show success
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${tenant.name} berhasil checkout',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Close loading
                              if (mounted) Navigator.pop(context);

                              // Show error
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
