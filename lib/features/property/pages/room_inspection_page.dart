import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/inspection_model.dart';
import '../providers/inspection_provider.dart';
import '../models/room_model.dart';

class RoomInspectionPage extends StatefulWidget {
  final Room room;
  const RoomInspectionPage({super.key, required this.room});

  @override
  State<RoomInspectionPage> createState() => _RoomInspectionPageState();
}

class _RoomInspectionPageState extends State<RoomInspectionPage> {
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<InspectionProvider>().fetchInspections(widget.room.id!);
    });
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
      appBar: AppBar(title: Text('Inspeksi Kamar ${widget.room.number}')),
      body: Consumer<InspectionProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Kondisi',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('Upload Foto'),
                      onPressed: _pickPhoto,
                    ),
                    const SizedBox(width: 12),
                    if (_photoPath != null)
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.file(File(_photoPath!)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_notesController.text.isEmpty || _photoPath == null)
                      return;
                    final inspection = Inspection(
                      roomId: widget.room.id!,
                      date: DateTime.now(),
                      conditionNotes: _notesController.text,
                      photoUrl: _photoPath!,
                    );
                    await provider.addInspection(inspection);
                    _notesController.clear();
                    setState(() {
                      _photoPath = null;
                    });
                  },
                  child: const Text('Simpan Inspeksi'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.inspections.isEmpty
                      ? const Center(child: Text('Belum ada inspeksi'))
                      : ListView.builder(
                          itemCount: provider.inspections.length,
                          itemBuilder: (context, index) {
                            final insp = provider.inspections[index];
                            return Card(
                              child: ListTile(
                                leading: Image.file(File(insp.photoUrl)),
                                title: Text(insp.conditionNotes),
                                subtitle: Text(insp.date.toLocal().toString()),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => provider.deleteInspection(
                                    insp.id!,
                                    widget.room.id!,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
