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

  /// 🔑 STATUS HARUS ENUM
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
      _status = widget.room!.status; // ✅ enum
      _photoPath = widget.room!.photoUrl.isNotEmpty
          ? widget.room!.photoUrl
          : null;
    }
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null ? 'Tambah Kamar' : 'Edit Kamar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Foto kamar
              GestureDetector(
                onTap: _pickPhoto,
                child: _photoPath != null
                    ? Image.file(
                        File(_photoPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.add_a_photo,
                          size: 100,
                          color: Colors.white70,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Nomor Kamar'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Tipe Kamar'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga / Bulan'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _facilitiesController,
                decoration: const InputDecoration(labelText: 'Fasilitas'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              /// ✅ DROPDOWN ENUM
              DropdownButtonFormField<RoomStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status Kamar'),
                items: const [
                  DropdownMenuItem(
                    value: RoomStatus.available,
                    child: Text('Available'),
                  ),
                  DropdownMenuItem(
                    value: RoomStatus.occupied,
                    child: Text('Occupied'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final room = Room(
                      id: widget.room?.id,
                      number: _numberController.text,
                      type: _typeController.text,
                      price: int.parse(_priceController.text),
                      status: _status, // ✅ enum
                      facilities: _facilitiesController.text,
                      photoUrl: _photoPath ?? '',
                    );

                    final provider = context.read<RoomProvider>();

                    if (widget.room == null) {
                      await provider.addRoom(room);
                    } else {
                      await provider.updateRoom(room);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamar berhasil disimpan')),
                    );

                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
