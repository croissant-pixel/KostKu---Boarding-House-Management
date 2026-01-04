import 'package:flutter/material.dart';
import '../../../core/database/db_helper.dart';
import '../models/kost_model.dart';

class KostProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  Kost? kost;
  List<String> photos = [];
  bool isLoading = false;

  // =================== Fetch ===================
  Future<void> fetchKost() async {
    isLoading = true;
    notifyListeners();

    kost = await _dbHelper.getKost();
    if (kost != null) {
      photos = await _dbHelper.getKostPhotos(kost!.id!);
    }

    isLoading = false;
    notifyListeners();
  }

  // =================== Save Kost ===================
  Future<void> saveKost(Kost newKost) async {
    if (kost == null) {
      final id = await _dbHelper.insertKost(newKost);
      newKost.id = id;
      kost = newKost;
    } else {
      newKost.id = kost!.id;
      await _dbHelper.updateKost(newKost);
      kost = newKost;
    }
    notifyListeners();
  }

  // =================== Photo Gallery ===================
  Future<void> addPhoto(String photoUrl) async {
    if (kost == null) return;
    await _dbHelper.addKostPhoto(kost!.id!, photoUrl);
    await fetchKost();
  }

  Future<void> removePhoto(int index) async {
    if (kost == null) return;
    // Ambil id foto dari DB dulu
    final db = await DBHelper.database;
    final maps = await db.query(
      'kost_photos',
      where: 'kost_id = ?',
      whereArgs: [kost!.id!],
    );
    if (maps.length > index) {
      await _dbHelper.deleteKostPhoto(maps[index]['id'] as int);
      await fetchKost();
    }
  }
}
