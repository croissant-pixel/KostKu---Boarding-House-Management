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
  final ImagePicker _picker = ImagePicker();

  int? _selectedRoomId;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _ktpPhotoPath;
  String? _profilePhotoPath;

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

  List<Room> get availableRooms {
    final rooms = context.watch<RoomProvider>().rooms;
    return rooms.where((r) {
      if (widget.tenant != null && r.id == widget.tenant!.roomId) return true;
      return r.status == RoomStatus.available;
    }).toList();
  }

  Future<void> _pickImage(bool isKTP) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Upload ${isKTP ? "KTP" : "Foto Profil"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          if (isKTP) {
            _ktpPhotoPath = image.path;
          } else {
            _profilePhotoPath = image.path;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomItems = availableRooms;
    final bool selectedRoomStillExists = roomItems.any(
      (r) => r.id == _selectedRoomId,
    );
    final int? dropdownValue = selectedRoomStillExists ? _selectedRoomId : null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.tenant == null ? 'Tambah Tenant' : 'Edit Tenant'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profilePhotoPath != null
                          ? FileImage(File(_profilePhotoPath!))
                          : null,
                      child: _profilePhotoPath == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Personal Info Section
            _buildSectionTitle('Informasi Personal', Icons.person),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.badge,
              hint: 'Masukkan nama lengkap',
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _phoneController,
              label: 'Nomor HP',
              icon: Icons.phone,
              hint: '08xxxxxxxxxx',
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              hint: 'email@example.com',
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _emergencyController,
              label: 'Kontak Darurat',
              icon: Icons.contact_emergency,
              hint: 'Nomor HP keluarga/teman',
              keyboardType: TextInputType.phone,
              isRequired: false,
            ),

            const SizedBox(height: 32),

            // Room Assignment Section
            _buildSectionTitle('Pilih Kamar', Icons.room),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<int>(
                value: dropdownValue,
                decoration: InputDecoration(
                  labelText: 'Pilih Kamar',
                  prefixIcon: const Icon(Icons.meeting_room),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: roomItems.map((r) {
                  return DropdownMenuItem<int>(
                    value: r.id,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${r.type} - Rp ${_formatPrice(r.price)}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: roomItems.isEmpty
                    ? null
                    : (val) {
                        setState(() => _selectedRoomId = val);
                      },
                validator: (v) => v == null ? 'Pilih kamar' : null,
              ),
            ),

            const SizedBox(height: 32),

            // Contract Period Section
            _buildSectionTitle('Periode Kontrak', Icons.calendar_today),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Check-in',
                    date: _checkInDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _checkInDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _checkInDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    label: 'Check-out',
                    date: _checkOutDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _checkOutDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _checkOutDate = picked);
                      }
                    },
                  ),
                ),
              ],
            ),

            if (_checkInDate != null && _checkOutDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Durasi: ${_calculateDuration()} bulan',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Document Section
            _buildSectionTitle('Dokumen', Icons.description),
            const SizedBox(height: 16),

            _buildPhotoCard(
              title: 'Foto KTP',
              icon: Icons.credit_card,
              photoPath: _ktpPhotoPath,
              onTap: () => _pickImage(true),
              color: Colors.orange,
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.tenant == null ? 'Simpan Tenant' : 'Update Tenant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '$label wajib diisi';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? date.toLocal().toString().split(' ')[0]
                      : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: date != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: date != null ? Colors.black : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required IconData icon,
    required String? photoPath,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  photoPath != null ? Icons.check_circle : Icons.upload,
                  color: photoPath != null ? Colors.green : Colors.grey,
                ),
              ],
            ),
            if (photoPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photoPath),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tap untuk upload $title',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _calculateDuration() {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    int months =
        (_checkOutDate!.year - _checkInDate!.year) * 12 +
        _checkOutDate!.month -
        _checkInDate!.month;
    return months < 1 ? 1 : months;
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kamar terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tenantProvider = context.read<TenantProvider>();
      final roomProvider = context.read<RoomProvider>();

      final durationMonth = _calculateDuration();

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

      if (widget.tenant == null) {
        tenantId = await tenantProvider.addTenant(tenant);
      } else {
        tenantId = widget.tenant!.id!;
        await tenantProvider.updateTenant(tenant);
      }

      await tenantProvider.checkInTenant(
        tenantId: tenantId,
        roomId: _selectedRoomId!,
        checkInDate: tenant.checkInDate!,
        durationMonth: durationMonth,
        lat: 0,
        lng: 0,
      );

      await Future.wait([
        roomProvider.fetchRooms(),
        tenantProvider.fetchTenants(),
      ]);

      // Close loading
      if (mounted) Navigator.pop(context);

      // Close form
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.tenant == null
                  ? 'Tenant berhasil ditambahkan'
                  : 'Tenant berhasil diupdate',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }
}
