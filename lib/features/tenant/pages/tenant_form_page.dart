import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kostku/features/property/models/room_model.dart';
import 'package:kostku/features/property/providers/room_provider.dart';
import 'package:provider/provider.dart';
import '../models/tenant_model.dart';
import '../providers/tenant_provider.dart';

class TenantFormPage extends StatefulWidget {
  final Tenant? tenant;
  const TenantFormPage({super.key, this.tenant});

  @override
  State<TenantFormPage> createState() => _TenantFormPageState();
}

class _TenantFormPageState extends State<TenantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyController = TextEditingController();
  List<Room> get rooms => context.watch<RoomProvider>().rooms ?? [];

  List<Room> get availableRooms {
    return rooms.where((r) {
      // include room ini kalau sedang edit tenant dan room itu milik tenant ini
      if (widget.tenant != null && r.id == widget.tenant!.roomId) return true;
      // hanya tampilkan room yang available
      return r.status == RoomStatus.available;
    }).toList();
  }



  int? _selectedRoomId;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  String? _ktpPhotoPath;
  String? _profilePhotoPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
     Future.microtask(() {
      context.read<RoomProvider>().fetchRooms();
    });
    if (widget.tenant != null) {
      final t = widget.tenant!;
      _nameController.text = t.name;
      _phoneController.text = t.phone;
      _emailController.text = t.email;
      _emergencyController.text = t.emergencyContact ?? '';
      _selectedRoomId = t.roomId;
      _checkInDate = t.checkInDate;
      _checkOutDate = t.checkOutDate;
      _ktpPhotoPath = t.ktpPhoto;
      _profilePhotoPath = t.profilePhoto;
    }
  }

  Future<void> _pickImage(bool isKTP) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        if (isKTP)
          _ktpPhotoPath = image.path;
        else
          _profilePhotoPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomProvider>().rooms;

    final List<Room> roomItems = rooms.where((r) {
      // saat edit tenant → izinkan kamar lama tetap muncul
      if (widget.tenant != null && r.id == widget.tenant!.roomId) return true;

      // selain itu, hanya kamar available
      return r.status == RoomStatus.available;
    }).toList();

      final bool selectedRoomStillExists = roomItems.any(
      (r) => r.id == _selectedRoomId,
    );

    final int? dropdownValue = selectedRoomStillExists ? _selectedRoomId : null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenant == null ? 'Tambah Tenant' : 'Edit Tenant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor HP'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyController,
                decoration: const InputDecoration(labelText: 'Kontak Darurat'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: dropdownValue,
                decoration: const InputDecoration(labelText: 'Assign Room'),
                items: roomItems
                    .map(
                      (r) => DropdownMenuItem<int>(
                        value: r.id,
                        child: Text('Kamar ${r.number} - Rp ${r.price}'),
                      ),
                    )
                    .toList(),
                onChanged: roomItems.isEmpty
                    ? null
                    : (val) => setState(() => _selectedRoomId = val),
                validator: (v) => v == null ? 'Pilih kamar' : null,
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _checkInDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _checkInDate = picked);
                    },
                    child: Text(
                      _checkInDate == null
                          ? 'Pilih Check-in'
                          : _checkInDate!.toLocal().toString().split(' ')[0],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _checkOutDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        setState(() => _checkOutDate = picked);
                    },
                    child: Text(
                      _checkOutDate == null
                          ? 'Pilih Check-out'
                          : _checkOutDate!.toLocal().toString().split(' ')[0],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(true),
                    child: const Text('Upload KTP'),
                  ),
                  const SizedBox(width: 12),
                  if (_ktpPhotoPath != null)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.file(File(_ktpPhotoPath!)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(false),
                    child: const Text('Upload Profil Photo'),
                  ),
                  const SizedBox(width: 12),
                  if (_profilePhotoPath != null)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.file(File(_profilePhotoPath!)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_selectedRoomId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih kamar terlebih dahulu'),
                      ),
                    );
                    return;
                  }

                  final tenantProvider = context.read<TenantProvider>();
                  final roomProvider = context.read<RoomProvider>();

                  try {
                    // Hitung duration dari check-in dan check-out date
                    int durationMonth = 1;
                    if (_checkInDate != null && _checkOutDate != null) {
                      durationMonth =
                          ((_checkOutDate!.year - _checkInDate!.year) * 12 +
                          _checkOutDate!.month -
                          _checkInDate!.month);
                      if (durationMonth < 1) durationMonth = 1;
                    }

                    // ================= BUILD TENANT =================
                    final tenant = Tenant(
                      id: widget.tenant?.id,
                      name: _nameController.text,
                      phone: _phoneController.text,
                      email: _emailController.text,
                      emergencyContact: _emergencyController.text,
                      roomId: _selectedRoomId,
                      checkInDate: _checkInDate ?? DateTime.now(),
                      checkOutDate: _checkOutDate,
                      ktpPhoto: _ktpPhotoPath,
                      profilePhoto: _profilePhotoPath,
                      durationMonth: durationMonth,
                    );

                    int tenantId;

                    // ================= ADD / UPDATE TENANT =================
                    if (widget.tenant == null) {
                      // Tambah tenant baru
                      tenantId = await tenantProvider.addTenant(tenant);
                    } else {
                      // Update tenant existing
                      tenantId = widget.tenant!.id!;
                      await tenantProvider.updateTenant(tenant);
                    }

                    // ================= CHECK-IN (UPDATE ROOM STATUS) =================
                    await tenantProvider.checkInTenant(
                      tenantId: tenantId,
                      roomId: _selectedRoomId!,
                      checkInDate: tenant.checkInDate!,
                      durationMonth: durationMonth,
                      lat: 0, // TODO: implement geolocation if needed
                      lng: 0,
                    );

                    // ================= REFRESH DATA =================
                    await Future.wait([
                      roomProvider.fetchRooms(),
                      tenantProvider.fetchTenants(),
                    ]);

                    // ================= CLOSE PAGE =================
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.tenant == null
                                ? 'Tenant berhasil ditambahkan ke ${_selectedRoomId}'
                                : 'Tenant berhasil diupdate',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Submit Tenant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
