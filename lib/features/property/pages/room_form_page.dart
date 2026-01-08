import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';

class RoomFormPage extends StatefulWidget {
  final Room? room;
  const RoomFormPage({super.key, this.room});

  @override
  State<RoomFormPage> createState() => _RoomFormPageState();
}

class _RoomFormPageState extends State<RoomFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  RoomStatus _status = RoomStatus.available;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _numberController.text = widget.room!.number;
      _typeController.text = widget.room!.type;
      _priceController.text = widget.room!.price.toString();
      _facilitiesController.text = widget.room!.facilities;
      _status = widget.room!.status;
      _photoPath = widget.room!.photoUrl.isNotEmpty
          ? widget.room!.photoUrl
          : null;
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih Sumber Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
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
          _photoPath = image.path;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.room == null ? 'Tambah Kamar' : 'Edit Kamar'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Photo Section
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: _photoPath != null
                          ? DecorationImage(
                              image: FileImage(File(_photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photoPath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap untuk upload foto kamar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                if (_photoPath != null)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      onPressed: _pickPhoto,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.edit),
                    ),
                  ),
              ],
            ),

            // Form Fields
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Kamar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _numberController,
                    label: 'Nomor Kamar',
                    icon: Icons.meeting_room,
                    hint: 'Contoh: 101',
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _typeController,
                    label: 'Tipe Kamar',
                    icon: Icons.category,
                    hint: 'Contoh: Standard, Deluxe',
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _priceController,
                    label: 'Harga per Bulan',
                    icon: Icons.payments,
                    hint: 'Contoh: 1000000',
                    keyboardType: TextInputType.number,
                    prefix: const Text('Rp '),
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _facilitiesController,
                    label: 'Fasilitas',
                    icon: Icons.check_circle_outline,
                    hint: 'Pisahkan dengan koma (,)',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Status Dropdown
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
                    child: DropdownButtonFormField<RoomStatus>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Status Kamar',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: RoomStatus.available,
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Available'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: RoomStatus.occupied,
                          child: Row(
                            children: [
                              Icon(Icons.people, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Occupied'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
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
                        widget.room == null ? 'Simpan Kamar' : 'Update Kamar',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    Widget? prefix,
    int maxLines = 1,
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
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          prefix: prefix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto kamar belum diupload'),
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
      final room = Room(
        id: widget.room?.id,
        number: _numberController.text,
        type: _typeController.text,
        price: int.parse(_priceController.text),
        status: _status,
        facilities: _facilitiesController.text,
        photoUrl: _photoPath!,
      );

      final provider = context.read<RoomProvider>();

      if (widget.room == null) {
        await provider.addRoom(room);
      } else {
        await provider.updateRoom(room);
      }

      // Close loading
      if (mounted) Navigator.pop(context);

      // Close form
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.room == null
                  ? 'Kamar berhasil ditambahkan'
                  : 'Kamar berhasil diupdate',
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
    _numberController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _facilitiesController.dispose();
    super.dispose();
  }
}
